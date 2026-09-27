import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../models/call_model.dart';
import '../../providers/call_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _durationTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && context.read<CallProvider>().callStatus == CallStatus.connected) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();

    if (call.callStatus == CallStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final isVideo = call.callType == CallType.video;
    final remoteRenderers = call.remoteRenderers;
    final hasRemoteVideo = remoteRenderers.isNotEmpty &&
        isVideo &&
        remoteRenderers.values.any((r) => r.srcObject != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Video or Voice Background
          if (hasRemoteVideo)
            Positioned.fill(
              child: RTCVideoView(
                remoteRenderers.values.firstWhere(
                  (r) => r.srcObject != null,
                  orElse: () => remoteRenderers.values.first,
                ),
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF1E293B), AppColors.background],
                    radius: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomAvatar(
                      name: call.targetUserName ?? 'Participant',
                      avatarUrl: call.targetUserAvatar,
                      size: 110,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      call.targetUserName ?? 'Call',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      call.callStatus == CallStatus.connected
                          ? _formatDuration(_callDurationSeconds)
                          : call.callStatus == CallStatus.calling
                              ? 'Connecting...'
                              : 'Ringing...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top Info Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    call.targetUserName ?? 'Call',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (call.callStatus == CallStatus.connected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDuration(_callDurationSeconds),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Picture-in-Picture Local Camera View
          if (isVideo && !call.isVideoOff)
            Positioned(
              top: 100,
              right: 16,
              width: 110,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RTCVideoView(
                    call.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),

          // Bottom Controls Bar
          Positioned(
            bottom: 36,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(220),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Audio Mute Toggle
                  _buildCallButton(
                    icon: call.isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: !call.isAudioMuted,
                    onTap: () => call.toggleAudio(),
                  ),

                  // Video Off Toggle
                  if (isVideo)
                    _buildCallButton(
                      icon: call.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                      isActive: !call.isVideoOff,
                      onTap: () => call.toggleVideo(),
                    ),

                  // Flip Camera
                  if (isVideo)
                    _buildCallButton(
                      icon: Icons.flip_camera_ios_rounded,
                      isActive: true,
                      onTap: () => call.switchCamera(),
                    ),

                  // End Call Button
                  GestureDetector(
                    onTap: () {
                      call.endCall();
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x66EF4444), blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardHover : AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppColors.borderLight : AppColors.danger,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.danger,
          size: 22,
        ),
      ),
    );
  }
}
