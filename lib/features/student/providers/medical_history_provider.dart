import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/medical_history_model.dart';
import '../data/medical_history_repository.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum MedicalHistoryStatus { idle, loading, saving, error }

class MedicalHistoryState {
  final MedicalHistory? history;
  final MedicalHistoryStatus status;
  final String? errorMessage;
  final bool isEditing;

  const MedicalHistoryState({
    this.history,
    this.status = MedicalHistoryStatus.idle,
    this.errorMessage,
    this.isEditing = false,
  });

  bool get isLoading => status == MedicalHistoryStatus.loading;
  bool get isSaving => status == MedicalHistoryStatus.saving;

  MedicalHistoryState copyWith({
    MedicalHistory? history,
    MedicalHistoryStatus? status,
    String? errorMessage,
    bool? isEditing,
  }) {
    return MedicalHistoryState(
      history: history ?? this.history,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class MedicalHistoryNotifier extends StateNotifier<MedicalHistoryState> {
  MedicalHistoryNotifier()
    : super(const MedicalHistoryState(status: MedicalHistoryStatus.loading)) {
    _load();
  }

  final _repo = MedicalHistoryRepository.instance;
  Timer? _debounce;

  /// Initial async load – uses cached data when available.
  Future<void> _load() async {
    try {
      debugPrint('[MedicalHistoryNotifier] _load() starting…');
      final history = await _repo.fetch();
      debugPrint('[MedicalHistoryNotifier] _load() success');
      state = state.copyWith(
        history: history,
        status: MedicalHistoryStatus.idle,
      );
    } catch (e, st) {
      debugPrint('[MedicalHistoryNotifier] _load() error: $e\n$st');
      state = state.copyWith(
        status: MedicalHistoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Pull-to-refresh – forces a network call.
  Future<void> refresh() async {
    state = state.copyWith(status: MedicalHistoryStatus.loading);
    try {
      final history = await _repo.fetch(forceRefresh: true);
      state = state.copyWith(
        history: history,
        status: MedicalHistoryStatus.idle,
      );
    } catch (e) {
      state = state.copyWith(
        status: MedicalHistoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void cancelEditing() {
    state = state.copyWith(isEditing: false);
    // Reload to discard unsaved changes.
    _load();
  }

  /// Update a field locally (optimistic).
  void updateField(MedicalHistory Function(MedicalHistory) updater) {
    if (state.history == null) return;
    state = state.copyWith(history: updater(state.history!));
  }

  /// Debounced save – waits 600 ms of inactivity before persisting.
  void debouncedSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => save());
  }

  /// Immediate save.
  Future<bool> save() async {
    if (state.history == null) return false;
    state = state.copyWith(status: MedicalHistoryStatus.saving);
    try {
      await _repo.save(state.history!);
      state = state.copyWith(
        status: MedicalHistoryStatus.idle,
        isEditing: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: MedicalHistoryStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final medicalHistoryProvider =
    StateNotifierProvider.autoDispose<
      MedicalHistoryNotifier,
      MedicalHistoryState
    >((ref) => MedicalHistoryNotifier());
