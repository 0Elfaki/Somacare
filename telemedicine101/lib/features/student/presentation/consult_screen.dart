import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String _appId = String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
const String _defaultChannel = 'consultation';
const String _token = '';

class ConsultScreen extends StatefulWidget {
  /// Optional channel override — pass via GoRouter extra:
  /// `context.push('/consult', extra: {'channelId': 'appointment_xyz'})`
  final String? channelId;

  const ConsultScreen({super.key, this.channelId});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localJoined = false;
  bool _micMuted = false;
  bool _camOff = false;
  bool _isLoading = true;
  bool _isEndingCall = false;

  String get _channelId => widget.channelId ?? _defaultChannel;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: _appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() {
              _localJoined = true;
              _isLoading = false;
            });
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: _token,
      channelId: _channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void _endCall() async {
    if (_isEndingCall) return;
    setState(() => _isEndingCall = true);

    try {
      await _engine.leaveChannel().timeout(const Duration(milliseconds: 500), onTimeout: () {});
    } catch (_) {}
    try {
      await _engine.release().timeout(const Duration(milliseconds: 500), onTimeout: () {});
    } catch (_) {}

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/student-dashboard');
    }
  }

  void _toggleMic() {
    setState(() => _micMuted = !_micMuted);
    _engine.muteLocalAudioStream(_micMuted);
  }

  void _toggleCam() {
    setState(() => _camOff = !_camOff);
    _engine.muteLocalVideoStream(_camOff);
  }

  @override
  void dispose() {
    _engine.leaveChannel().catchError((_) {});
    _engine.release().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PopScope intercepts Android hardware back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Remote video ──────────────────────────────
            _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: _channelId),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E293B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Waiting for doctor to join…',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        if (_isLoading) ...[
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(
                            color: Colors.white38,
                          ),
                        ],
                      ],
                    ),
                  ),

            // ── Local video PiP ───────────────────────────
            if (_localJoined && !_camOff)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),

            // ── Top bar ───────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 12,
                  16,
                  12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _endCall, // ✅ always cleans up Agora
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Consultation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Secure medical call',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlBtn(
                      icon: _micMuted ? Icons.mic_off : Icons.mic,
                      label: _micMuted ? 'Unmute' : 'Mute',
                      onTap: _toggleMic,
                      active: !_micMuted,
                    ),
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    _ControlBtn(
                      icon: _camOff ? Icons.videocam_off : Icons.videocam,
                      label: _camOff ? 'Show Cam' : 'Hide Cam',
                      onTap: _toggleCam,
                      active: !_camOff,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control Button ────────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFF475569),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
