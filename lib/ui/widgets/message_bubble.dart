import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/message_model.dart';
import '../theme/app_theme.dart';
import 'audio_wave_player.dart';
import 'custom_avatar.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isGroup;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            if (isMe && onEdit != null && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.amber),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!();
                },
              ),
            if (isMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                title: const Text('Delete Message', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: CustomAvatar(
                name: message.sender?.name ?? 'User',
                avatarUrl: message.sender?.avatar,
                size: 28,
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showContextMenu(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.primaryGradient : null,
                  color: isMe ? null : AppColors.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe ? null : Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender name for group
                    if (!isMe && isGroup && message.sender != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.sender!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),

                    // Reply preview box
                    if (message.replayMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withAlpha(35) : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white : AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replayMessage!.sender?.name ?? 'Replying to message',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.replayMessage!.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMe ? Colors.white.withAlpha(200) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Attachments rendering
                    if (message.files.isNotEmpty)
                      ...message.files.map((file) {
                        final fullUrl = AppConfig.getFullMediaUrl(file.fileUrl);
                        final isImg = file.fileType?.startsWith('image/') == true ||
                            file.fileName.toLowerCase().endsWith('.png') ||
                            file.fileName.toLowerCase().endsWith('.jpg') ||
                            file.fileName.toLowerCase().endsWith('.jpeg') ||
                            file.fileName.toLowerCase().endsWith('.webp');
                        final isAud = file.fileType?.startsWith('audio/') == true ||
                            file.fileName.toLowerCase().endsWith('.mp3') ||
                            file.fileName.toLowerCase().endsWith('.m4a') ||
                            file.fileName.toLowerCase().endsWith('.wav') ||
                            file.fileName.toLowerCase().endsWith('.ogg');

                        if (isImg) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, fullUrl),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: const BoxConstraints(maxHeight: 220),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: fullUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(
                                    height: 140,
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        if (isAud) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: AudioWavePlayer(
                              audioUrl: fullUrl,
                              isMe: isMe,
                            ),
                          );
                        }

                        // Generic file / doc attachment
                        return GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(fullUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withAlpha(30) : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.download_rounded, size: 20, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        );
                      }),

                    // Message text
                    if (message.message.isNotEmpty)
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color: isMe ? Colors.white : AppColors.textPrimary,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp and delivery/read ticks
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              '(edited)',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isMe ? Colors.white.withAlpha(180) : AppColors.textMuted,
                              ),
                            ),
                          ),
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMe ? Colors.white.withAlpha(200) : AppColors.textMuted,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 14,
                            color: message.isRead
                                ? Colors.cyanAccent
                                : Colors.white.withAlpha(200),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
