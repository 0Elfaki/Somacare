#!/usr/bin/env python3
"""Structural sanity checks for the SomaCare Dart sources.

This is not a compiler. It catches the classes of breakage that a large
mechanical refactor actually introduces:

  1. unbalanced (), [], {} once strings and comments are stripped
  2. references to `AppColors.foo` (and the other token classes) whose member
     does not exist in lib/theme/app_theme.dart
  3. references to design-kit widgets that app_ui.dart does not declare
  4. files that use a symbol from app_theme.dart / app_ui.dart without
     importing it
  5. `const` applied directly to a static field reference (invalid Dart)

Run:  python3 tools/dart_check.py <project-root>
"""

from __future__ import annotations

import pathlib
import re
import sys

# ── source scrubbing ─────────────────────────────────────────────────────────


def strip_noise(src: str) -> str:
    """Blank out comments, strings and interpolations, preserving offsets."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        # line comment
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                out.append(' ')
                i += 1
            continue
        # block comment
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            depth = 1
            out.append('  ')
            i += 2
            while i < n and depth:
                if src.startswith('/*', i):
                    depth += 1
                    out.append('  ')
                    i += 2
                elif src.startswith('*/', i):
                    depth -= 1
                    out.append('  ')
                    i += 2
                else:
                    out.append('\n' if src[i] == '\n' else ' ')
                    i += 1
            continue
        # raw / triple / normal strings
        m = re.match(r"(r?)('''|\"\"\"|'|\")", src[i:])
        if m:
            raw = bool(m.group(1))
            quote = m.group(2)
            start = i
            i += len(m.group(0))
            out.append(' ' * (i - start))
            while i < n:
                if not raw and src[i] == '\\':
                    out.append('  ')
                    i += 2
                    continue
                if src.startswith(quote, i):
                    out.append(' ' * len(quote))
                    i += len(quote)
                    break
                # keep interpolated expressions: they contain real brackets
                if not raw and src.startswith('${', i):
                    depth = 0
                    while i < n:
                        if src[i] == '{':
                            depth += 1
                        elif src[i] == '}':
                            depth -= 1
                            if depth == 0:
                                out.append(src[i])
                                i += 1
                                break
                        out.append(src[i])
                        i += 1
                    continue
                out.append('\n' if src[i] == '\n' else ' ')
                i += 1
            continue
        out.append(c)
        i += 1
    return ''.join(out)


# ── checks ───────────────────────────────────────────────────────────────────

PAIRS = {')': '(', ']': '[', '}': '{'}
OPEN = set('([{')

TOKEN_CLASSES = (
    'AppColors',
    'AppSpacing',
    'AppTypography',
    'AppRadius',
    'AppShadows',
    'AppMotion',
    'AppTouch',
    'BloomTextStyles',
    'LegacyDarkColors',
    'PaymentBrandColors',
)


def members_of(src: str, class_name: str) -> set[str]:
    """Static members declared on `class_name` in `src`."""
    m = re.search(r'\bclass\s+' + class_name + r'\b[^{]*\{', src)
    if not m:
        return set()
    i = m.end() - 1
    depth = 0
    end = len(src)
    for j in range(i, len(src)):
        if src[j] == '{':
            depth += 1
        elif src[j] == '}':
            depth -= 1
            if depth == 0:
                end = j
                break
    body = src[i:end]
    names: set[str] = set()
    for mm in re.finditer(
        r'\bstatic\s+(?:const\s+|final\s+)?[\w<>,\s?\[\]]*?\b(\w+)\s*(?:=|\()',
        body,
    ):
        names.add(mm.group(1))
    for mm in re.finditer(r'\bstatic\s+\w[\w<>,\s?\[\]]*\s+(\w+)\s*[;=]', body):
        names.add(mm.group(1))
    return names


def top_level_names(src: str) -> set[str]:
    names = set()
    for mm in re.finditer(r'^(?:abstract\s+|sealed\s+|final\s+|base\s+|mixin\s+)*'
                          r'(?:class|enum|mixin|extension|typedef)\s+(\w+)',
                          src, re.M):
        names.add(mm.group(1))
    for mm in re.finditer(r'^[\w<>,\s?\[\]]+?\s(\w+)\s*\(', src, re.M):
        names.add(mm.group(1))
    return names


def main(root: pathlib.Path) -> int:
    lib = root / 'lib'
    theme_src = (lib / 'theme' / 'app_theme.dart').read_text(encoding='utf-8')
    ui_path = lib / 'widgets' / 'app_ui.dart'
    ui_src = ui_path.read_text(encoding='utf-8') if ui_path.exists() else ''

    declared = {c: members_of(theme_src, c) for c in TOKEN_CLASSES}
    ui_names = top_level_names(ui_src)
    theme_names = top_level_names(theme_src)

    problems: list[str] = []
    files = sorted(lib.rglob('*.dart'))

    for path in files:
        rel = path.relative_to(root)
        raw = path.read_text(encoding='utf-8')
        code = strip_noise(raw)

        # 1. bracket balance
        stack: list[tuple[str, int]] = []
        line = 1
        for ch in code:
            if ch == '\n':
                line += 1
            elif ch in OPEN:
                stack.append((ch, line))
            elif ch in PAIRS:
                if not stack or stack[-1][0] != PAIRS[ch]:
                    problems.append(
                        f'{rel}:{line}: unbalanced "{ch}"'
                        + (f' (open "{stack[-1][0]}" from line {stack[-1][1]})'
                           if stack else ' with nothing open')
                    )
                    break
                stack.pop()
        else:
            if stack:
                ch, ln = stack[-1]
                problems.append(f'{rel}: unclosed "{ch}" opened at line {ln}')

        # 2. token members exist
        for cls in TOKEN_CLASSES:
            for mm in re.finditer(r'\b' + cls + r'\.(\w+)', code):
                member = mm.group(1)
                if declared[cls] and member not in declared[cls]:
                    ln = code[: mm.start()].count('\n') + 1
                    problems.append(
                        f'{rel}:{ln}: {cls}.{member} is not declared in app_theme.dart'
                    )

        # 5. `const` directly before a static field reference
        for mm in re.finditer(r'\bconst\s+(' + '|'.join(TOKEN_CLASSES) + r')\.\w+',
                              code):
            ln = code[: mm.start()].count('\n') + 1
            problems.append(f'{rel}:{ln}: `const` applied to a field reference')

        # 4. imports present for the symbols used
        uses_theme = any(re.search(r'\b' + c + r'\.', code) for c in TOKEN_CLASSES)
        if uses_theme and 'app_theme.dart' not in raw and rel.name != 'app_theme.dart':
            problems.append(f'{rel}: uses theme tokens but does not import app_theme.dart')

        if rel.as_posix() not in ('lib/widgets/app_ui.dart',):
            # Only the design kit's own namespace: App*, appSection, showApp*.
            kit = {n for n in ui_names
                   if n.startswith(('App', 'appSection', 'showApp'))}
            used_ui = {n for n in kit if re.search(r'\b' + n + r'\b', code)}
            local = top_level_names(code)
            used_ui -= local
            used_ui -= theme_names
            if used_ui and 'app_ui.dart' not in raw:
                problems.append(
                    f'{rel}: uses {sorted(used_ui)[:4]} but does not import app_ui.dart'
                )

    print(f'checked {len(files)} files')
    if problems:
        print(f'\n{len(problems)} problem(s):')
        for p in problems:
            print('  ' + p)
        return 1
    print('no structural problems found')
    return 0


if __name__ == '__main__':
    sys.exit(main(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '.')))
