import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../screens/screens.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class ActiveCallMiniBar extends StatefulWidget {
  const ActiveCallMiniBar({super.key});

  @override
  State<ActiveCallMiniBar> createState() => _ActiveCallMiniBarState();
}

class _ActiveCallMiniBarState extends State<ActiveCallMiniBar> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();

    if (!call.isCallMinimized ||
        (call.callStatus != CallStatus.connected && call.callStatus != CallStatus.calling)) {
      return const SizedBox.shrink();
    }

    final isConnected = call.callStatus == CallStatus.connected;
    final isVideo = call.callType == CallType.video;
    final durationStr = isConnected
        ? _formatDuration(call.callDurationInSeconds)
        : (call.callStatus == CallStatus.calling ? 'Calling...' : 'Connecting...');

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            call.expandCall();
            appNavigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const CallScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF064E3B), // Emerald 900
                  Color(0xFF0F172A), // Slate 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(100), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Caller Avatar with pulsing indicator
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CustomAvatar(
                      name: call.targetUserName ?? (call.isGroupCall ? 'Group Call' : 'Call'),
                      avatarUrl: call.targetUserAvatar,
                      size: 40,
                    ),
                    FadeTransition(
                      opacity: _animController,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isConnected ? const Color(0xFF10B981) : Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name and Running Timer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        call.targetUserName ?? (call.isGroupCall ? 'Group Call' : 'Call'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                            size: 13,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            durationStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '• Tap to return',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Action: Mute / Unmute
                IconButton(
                  icon: Icon(
                    call.isAudioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: call.isAudioMuted ? Colors.amber : Colors.white,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => call.toggleAudio(),
                ),
                const SizedBox(width: 4),

                // Quick Action: Hang up
                GestureDetector(
                  onTap: () => call.endCall(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
