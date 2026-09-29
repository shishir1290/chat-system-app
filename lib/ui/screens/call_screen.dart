import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
    final isGroup = call.isGroupCall || remoteRenderers.length > 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final isLocked = await LockScreenService.isKeyguardLocked();
        if (isLocked) {
          final unlocked = await LockScreenService.requestDismissKeyguard();
          if (unlocked && context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Main Video / Voice Call Content
            Positioned.fill(
              child: isGroup
                  ? _buildGroupVideoLayout(call, remoteRenderers, isVideo)
                  : _buildSingleVideoLayout(call, remoteRenderers, isVideo),
            ),

            // Top Info Bar
            Positioned(
              top: 44,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final isLocked = await LockScreenService.isKeyguardLocked();
                        if (isLocked) {
                          final unlocked = await LockScreenService.requestDismissKeyguard();
                          if (unlocked && context.mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        } else {
                          if (context.mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        call.targetUserName ?? (isGroup ? 'Group Call' : 'Call'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isGroup && remoteRenderers.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${remoteRenderers.length + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (call.callStatus == CallStatus.connected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(50),
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

          // Picture-in-Picture Local Camera View (Shown when in 1-to-1 or when local camera is on)
          if (!call.isVideoOff && call.localRenderer.srcObject != null)
            Positioned(
              top: 108,
              right: 16,
              width: isGroup ? 100 : 110,
              height: isGroup ? 140 : 160,
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

                  // Video Camera Toggle (Available for both Audio & Video calls)
                  _buildCallButton(
                    icon: call.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    isActive: !call.isVideoOff,
                    onTap: () => call.toggleVideo(),
                  ),

                  // Flip Camera (Shown when Camera is active)
                  if (!call.isVideoOff)
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

  Widget _buildSingleVideoLayout(CallProvider call, Map<String, RTCVideoRenderer> remoteRenderers, bool isVideo) {
    final hasRemoteVideo = remoteRenderers.isNotEmpty &&
        isVideo &&
        remoteRenderers.values.any((r) => r.srcObject != null);

    if (hasRemoteVideo) {
      final renderer = remoteRenderers.values.firstWhere(
        (r) => r.srcObject != null,
        orElse: () => remoteRenderers.values.first,
      );
      return RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    return Container(
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
    );
  }

  Widget _buildGroupVideoLayout(CallProvider call, Map<String, RTCVideoRenderer> remoteRenderers, bool isVideo) {
    final peers = remoteRenderers.entries.toList();

    if (peers.isEmpty) {
      return Container(
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
              name: call.targetUserName ?? 'Group Call',
              avatarUrl: call.targetUserAvatar,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              call.targetUserName ?? 'Group Call',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              call.callStatus == CallStatus.connected
                  ? 'Waiting for participants to join...'
                  : 'Starting group call...',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (peers.length == 1) {
      return _buildSingleVideoLayout(call, remoteRenderers, isVideo);
    }

    // Grid layout for 2+ participants
    final crossAxisCount = peers.length <= 2 ? 1 : 2;

    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 100, left: 12, right: 12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: peers.length == 2 ? 1.3 : 1.0,
        ),
        itemCount: peers.length,
        itemBuilder: (context, index) {
          final entry = peers[index];
          final renderer = entry.value;
          final hasVideo = renderer.srcObject != null &&
              renderer.srcObject!.getVideoTracks().isNotEmpty &&
              renderer.srcObject!.getVideoTracks().any((t) => t.enabled);

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasVideo && isVideo)
                    RTCVideoView(
                      renderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomAvatar(
                            name: 'Participant ${index + 1}',
                            size: 60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Participant ${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Bottom participant badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasVideo ? Icons.videocam_rounded : Icons.mic_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'User ${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
