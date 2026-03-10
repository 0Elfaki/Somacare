import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

const String _appId = String.fromEnvironment('AGORA_APP_ID', defaultValue: '');
const String _token = '';

class DoctorConsultScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const DoctorConsultScreen({super.key, required this.extra});

  @override
  State<DoctorConsultScreen> createState() => _DoctorConsultScreenState();
}

class _DoctorConsultScreenState extends State<DoctorConsultScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localJoined = false;
  bool _micMuted = false;
  bool _camOff = false;
  bool _isLoading = true;
  bool _isEndingCall = false;

  String get _channelId {
    final appointmentId = widget.extra['appointmentId'] as String?;
    if (appointmentId != null && appointmentId.isNotEmpty) {
      return 'appointment_$appointmentId';
    }
    return 'consultation';
  }

  String get _studentName =>
      (widget.extra['studentName'] as String?) ?? 'Patient';

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

    // Quick cleanup — don't block navigation
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
      context.go('/doctor-dashboard');
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
    // PopScope intercepts Android hardware back button
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Remote video (full screen) ────────────────
            if (_remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: _channelId),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white54,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading
                          ? 'Connecting...'
                          : 'Waiting for $_studentName...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(color: Colors.white54),
                    ],
                  ],
                ),
              ),

            // ── Local video (picture-in-picture) ──────────
            if (_localJoined && !_camOff)
              Positioned(
                top: 60,
                right: 16,
                width: 100,
                height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Consulting: $_studentName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Controls ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 32,
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
                      // Mute mic
                      _ControlButton(
                        icon: _micMuted ? Icons.mic_off : Icons.mic,
                        label: _micMuted ? 'Unmute' : 'Mute',
                        onTap: _toggleMic,
                        isActive: !_micMuted,
                      ),

                      // End call
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

                      // Toggle camera
                      _ControlButton(
                        icon: _camOff ? Icons.videocam_off : Icons.videocam,
                        label: _camOff ? 'Cam On' : 'Cam Off',
                        onTap: _toggleCam,
                        isActive: !_camOff,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ), // closes Scaffold
    ); // closes PopScope
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
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
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
