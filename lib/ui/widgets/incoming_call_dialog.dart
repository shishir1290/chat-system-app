import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/call_provider.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class IncomingCallDialog extends StatelessWidget {
  const IncomingCallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    final incoming = call.incomingCall;

    if (incoming == null) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(50),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CustomAvatar(
                name: incoming.callerName,
                avatarUrl: incoming.callerAvatar,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      incoming.callerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          incoming.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          incoming.isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Reject Button
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                ),
                child: IconButton(
                  icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                  onPressed: () => call.rejectCall(),
                ),
              ),
              const SizedBox(width: 10),
              // Accept Button
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: IconButton(
                  icon: Icon(
                    incoming.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => call.answerCall(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
