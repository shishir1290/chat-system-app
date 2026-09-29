import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../screens/screens.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class IncomingCallDialog extends StatefulWidget {
  const IncomingCallDialog({super.key});

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    final incoming = call.incomingCall;

    if (incoming == null || call.callStatus != CallStatus.incoming) {
      return const SizedBox.shrink();
    }

    final isVideo = incoming.isVideo;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          call.rejectCall();
        }
      },
      child: Positioned.fill(
        child: Material(
          color: AppColors.background,
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF0F2537),
                  Color(0xFF09111E),
                  Color(0xFF030712),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Top Call Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withAlpha(70), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          size: 16,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Caller Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      incoming.callerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (incoming.isGroup && incoming.roomName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      incoming.roomName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const Spacer(flex: 2),

                  // Pulsing Center Avatar
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glow Ring
                            Container(
                              width: 170 * _pulseAnimation.value,
                              height: 170 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isVideo ? AppColors.primary : Colors.cyan).withAlpha(20),
                              ),
                            ),
                            // Middle Glow Ring
                            Container(
                              width: 145 * _pulseAnimation.value,
                              height: 145 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isVideo ? AppColors.primary : Colors.cyan).withAlpha(35),
                              ),
                            ),
                            // Avatar
                            CustomAvatar(
                              name: incoming.callerName,
                              avatarUrl: incoming.callerAvatar,
                              size: 116,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Action Buttons: Decline & Accept
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decline Button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => call.rejectCall(),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.danger,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.danger.withAlpha(120),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Decline',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // Accept Button
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await call.answerCall();
                                appNavigatorKey.currentState?.push(
                                  MaterialPageRoute(builder: (_) => const CallScreen()),
                                );
                              },
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(140),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Accept',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
