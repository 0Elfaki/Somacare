import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/message_model.dart';
import '../data/message_repository.dart';

/// Text-messaging screen between a student and their doctor, matching the
/// "Dr. Sarah Martinez" chat design — bubbles, an attached image, a voice
/// note, and a live typing indicator.
///
/// When [doctorId] is known (e.g. opened from a confirmed appointment) and
/// the student is signed in, the thread is loaded from and persisted to
/// the `messages` Supabase table in realtime (see
/// `lib/features/student/data/create_messages.sql`). Otherwise — e.g. when
/// opened from the dashboard's "Message Doctor" quick action with no
/// specific doctor picked yet — it falls back to a local demo thread so the
/// screen still has something to show.
class MessagingChatScreen extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorId;
  final String? appointmentId;

  const MessagingChatScreen({
    super.key,
    this.doctorName = 'Dr. Sarah Martinez',
    this.doctorSpecialty = 'General Physician',
    this.doctorId,
    this.appointmentId,
  });

  @override
  State<MessagingChatScreen> createState() => _MessagingChatScreenState();
}

class _MessagingChatScreenState extends State<MessagingChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  final Set<String> _seenIds = {};
  bool _isTyping = false;
  bool _isLoading = false;
  Timer? _replyTimer;
  RealtimeChannel? _channel;

  String? get _studentId => Supabase.instance.client.auth.currentUser?.id;

  /// True once we have both a signed-in student and a known doctor, so we
  /// can talk to the real `messages` table instead of showing demo data.
  bool get _isLive => _studentId != null && widget.doctorId != null;

  @override
  void initState() {
    super.initState();
    if (_isLive) {
      _loadLiveThread();
    } else {
      _loadDemoThread();
    }
  }

  void _loadDemoThread() {
    _messages.addAll([
      const _ChatMessage(
        isMe: true,
        type: _MessageType.text,
        text:
            "Hi Dr. Martinez, I've been experiencing headaches more frequently this week.",
        time: '9:30 AM',
      ),
      const _ChatMessage(
        isMe: false,
        type: _MessageType.text,
        text:
            'I\'m sorry to hear that. Can you tell me more about when they occur and how severe they are?',
        time: '9:31 AM',
      ),
      const _ChatMessage(
        isMe: true,
        type: _MessageType.text,
        text:
            'They usually happen in the afternoon and can last for a few hours. Here\'s an image from this morning.',
        time: '9:32 AM',
      ),
      const _ChatMessage(
        isMe: true,
        type: _MessageType.image,
        time: '9:32 AM',
      ),
      const _ChatMessage(
        isMe: false,
        type: _MessageType.text,
        text: 'Thank you. I reviewed the image. Here\'s a quick note for you.',
        time: '9:33 AM',
      ),
      const _ChatMessage(
        isMe: false,
        type: _MessageType.voice,
        time: '9:33 AM',
        durationLabel: '0:28',
      ),
      const _ChatMessage(
        isMe: true,
        type: _MessageType.text,
        text: 'Thank you, that helps!',
        time: '9:34 AM',
      ),
    ]);
  }

  Future<void> _loadLiveThread() async {
    final studentId = _studentId;
    final doctorId = widget.doctorId;
    if (studentId == null || doctorId == null) return;

    setState(() => _isLoading = true);
    final history = await MessageRepository.instance.fetchThread(
      studentId: studentId,
      doctorId: doctorId,
    );
    if (!mounted) return;
    setState(() {
      for (final m in history) {
        _seenIds.add(m.id);
        _messages.add(_ChatMessage.fromModel(m, meId: studentId));
      }
      _isLoading = false;
    });
    _scrollToBottom();
    unawaited(
      MessageRepository.instance.markThreadRead(
        studentId: studentId,
        doctorId: doctorId,
        readerId: studentId,
      ),
    );

    _channel = MessageRepository.instance.subscribe(
      studentId: studentId,
      doctorId: doctorId,
      onInsert: (message) {
        if (!mounted || _seenIds.contains(message.id)) return;
        _seenIds.add(message.id);
        setState(() {
          _messages.add(_ChatMessage.fromModel(message, meId: studentId));
          if (!message.isFromMe(studentId)) _isTyping = false;
        });
        _scrollToBottom();
      },
    );
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _channel?.unsubscribe();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    if (_isLive) {
      _sendLive(text);
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(isMe: true, type: _MessageType.text, text: text, time: _now()));
    });
    _scrollToBottom();

    // Simulate the doctor seeing the message and replying, so the thread
    // feels alive without requiring a backend for this screen.
    setState(() => _isTyping = true);
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          const _ChatMessage(
            isMe: false,
            type: _MessageType.text,
            text: "Got it — noted. Let's keep an eye on that.",
            time: '',
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendLive(String text) async {
    final studentId = _studentId;
    final doctorId = widget.doctorId;
    if (studentId == null || doctorId == null) return;

    setState(() => _isTyping = true);
    final sent = await MessageRepository.instance.sendMessage(
      studentId: studentId,
      doctorId: doctorId,
      senderId: studentId,
      body: text,
      appointmentId: widget.appointmentId,
    );
    if (!mounted) return;
    setState(() => _isTyping = false);

    if (sent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message. Try again.')),
      );
      return;
    }
    if (!_seenIds.contains(sent.id)) {
      _seenIds.add(sent.id);
      setState(() {
        _messages.add(_ChatMessage.fromModel(sent, meId: studentId));
      });
    }
    _scrollToBottom();
  }

  String _now() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/student-dashboard'),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B8CFF), Color(0xFF9333EA)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Color(0xFF64748B)),
            tooltip: 'Start video call',
            onPressed: () => context.push(
              '/consult',
              extra: {'doctorName': widget.doctorName},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F5F9)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B8CFF)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return _DoctorTypingRow(doctorName: widget.doctorName);
                      }
                      return _MessageBubble(msg: _messages[i]);
                    },
                  ),
          ),

          // ── Input bar ──────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5B8CFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message model ────────────────────────────────────────────────────────────

enum _MessageType { text, image, voice }

class _ChatMessage {
  final bool isMe;
  final _MessageType type;
  final String? text;
  final String time;
  final String? durationLabel;
  final String? attachmentUrl;

  const _ChatMessage({
    required this.isMe,
    required this.type,
    required this.time,
    this.text,
    this.durationLabel,
    this.attachmentUrl,
  });

  /// Converts a persisted [ChatMessageModel] (from Supabase) into the
  /// widget-local display model, formatting its timestamp and figuring out
  /// which side of the thread it belongs on relative to [meId].
  factory _ChatMessage.fromModel(ChatMessageModel m, {required String meId}) {
    final type = switch (m.type) {
      MessageType.image => _MessageType.image,
      MessageType.voice => _MessageType.voice,
      MessageType.text => _MessageType.text,
    };
    final local = m.createdAt.toLocal();
    final hour = local.hourOfPeriod12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return _ChatMessage(
      isMe: m.isFromMe(meId),
      type: type,
      text: m.body,
      time: '$hour:$minute $period',
      durationLabel: m.voiceDurationSeconds != null
          ? _formatDuration(m.voiceDurationSeconds!)
          : null,
      attachmentUrl: m.attachmentUrl,
    );
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

extension _HourOfPeriod on DateTime {
  int get hourOfPeriod12 {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }
}

// ── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    Widget content;
    switch (msg.type) {
      case _MessageType.text:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF5B8CFF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text ?? '',
            style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        );
        break;
      case _MessageType.image:
        content = ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: SizedBox(
            width: 200,
            height: 150,
            child: msg.attachmentUrl != null
                ? Image.network(
                    msg.attachmentUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 36,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.white54,
                        size: 36,
                      ),
                    ),
                  ),
          ),
        );
        break;
      case _MessageType.voice:
        content = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF5B8CFF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isMe ? Colors.white : const Color(0xFF5B8CFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isMe ? const Color(0xFF5B8CFF) : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              _Waveform(color: isMe ? Colors.white : const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Text(
                msg.durationLabel ?? '0:00',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [Flexible(child: content)],
          ),
          if (msg.time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                msg.time,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final Color color;
  const _Waveform({required this.color});

  static const _heights = [
    6.0, 12.0, 8.0, 16.0, 10.0, 18.0, 9.0, 14.0, 7.0, 16.0, 11.0, 8.0,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final h in _heights)
            Container(
              width: 2.5,
              height: h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Typing indicator row ─────────────────────────────────────────────────────

class _DoctorTypingRow extends StatelessWidget {
  final String doctorName;
  const _DoctorTypingRow({required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingDots(),
                const SizedBox(width: 8),
                Text(
                  '$doctorName is typing…',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 8,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = ((_ctrl.value + i * 0.2) % 1.0);
              final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Opacity(
                opacity: 0.4 + 0.6 * scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B8CFF),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
