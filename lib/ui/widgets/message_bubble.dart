import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
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
  final Function(String emoji)? onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
  });

  static const List<String> quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  static const List<String> allEmojis = [
    '👍', '❤️', '😂', '😮', '😢', '🙏',
    '🔥', '🎉', '👏', '🥳', '😍', '🤔',
    '💯', '✨', '🚀', '👀', '🤝', '🙌',
    '💔', '🤩', '😎', '😴', '🤯', '😡',
    '💩', '💪', '👌', '✌️', '🫡', '💖',
  ];

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  void _handleReaction(BuildContext context, String emoji) {
    if (onReact != null) {
      onReact!(emoji);
    } else {
      context.read<ChatProvider>().reactToMessage(message.id, emoji);
    }
  }

  void _showAllEmojisPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'React with emoji',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: allEmojis.length,
                  itemBuilder: (ctx, index) {
                    final emoji = allEmojis[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleReaction(context, emoji);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionDetailsModal(BuildContext context) {
    if (message.reactions.isEmpty) return;
    final currentUserId = context.read<AuthProvider>().user?.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Reactions (${message.reactions.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const Divider(color: AppColors.border),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: message.reactions.length,
                  itemBuilder: (ctx, index) {
                    final r = message.reactions[index];
                    final isCurrent = r.userId == currentUserId;
                    return ListTile(
                      leading: CustomAvatar(
                        name: r.user?.name ?? (isCurrent ? 'You' : 'User'),
                        avatarUrl: r.user?.avatar,
                        size: 36,
                      ),
                      title: Text(
                        isCurrent ? 'You' : (r.user?.name ?? 'User'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: isCurrent ? const Text('Tap to remove', style: TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
                      trailing: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      onTap: () {
                        if (isCurrent) {
                          Navigator.pop(ctx);
                          _handleReaction(context, r.emoji);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  errorListener: (_) {},
                  placeholder: (c, u) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  errorWidget: (c, u, e) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 48),
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
            // WhatsApp-style floating reaction bar inside sheet
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2428),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withAlpha(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...quickEmojis.map(
                    (emoji) => InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleReaction(context, emoji);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAllEmojisPicker(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 16),
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

  Widget _buildReactionsBadge(BuildContext context) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();

    final currentUserId = context.read<AuthProvider>().user?.id;
    final Map<String, int> counts = {};
    for (final r in message.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }

    final hasUserReacted = message.reactions.any((r) => r.userId == currentUserId);
    final sortedEmojis = counts.keys.toList();
    final totalCount = message.reactions.length;

    return GestureDetector(
      onTap: () => _showReactionDetailsModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E242B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUserReacted ? AppColors.primary.withAlpha(140) : Colors.white.withAlpha(35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...sortedEmojis.take(3).map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Text(e, style: const TextStyle(fontSize: 13, height: 1.1)),
            )),
            if (totalCount > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$totalCount',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 14, color: AppColors.textMuted),
                SizedBox(width: 6),
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

    if (_isCallMessage) {
      return _buildCallBubble(context);
    }

    final hasReactions = message.reactions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: hasReactions ? 14 : 3,
        left: 12,
        right: 12,
      ),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
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
                                      errorListener: (_) {},
                                      placeholder: (c, u) => Container(
                                        height: 140,
                                        color: AppColors.surface,
                                        child: const Center(
                                          child: CircularProgressIndicator(color: AppColors.primary),
                                        ),
                                      ),
                                      errorWidget: (c, u, e) => Container(
                                        height: 100,
                                        color: AppColors.surface,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 36),
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
                if (hasReactions)
                  Positioned(
                    bottom: -10,
                    left: isMe ? null : 10,
                    right: isMe ? 10 : null,
                    child: _buildReactionsBadge(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isCallMessage {
    final msg = message.message.toLowerCase();
    return message.isAudioCall ||
        message.isVideoCall ||
        msg.contains('call started') ||
        (msg.contains('missed') && msg.contains('call')) ||
        (msg.contains('declined') && msg.contains('call')) ||
        (msg.contains('ended') && msg.contains('call')) ||
        msg.contains('duration:') ||
        msg.startsWith('video call') ||
        msg.startsWith('audio call');
  }

  Widget _buildCallBubble(BuildContext context) {
    final msgText = message.message.trim();
    final msgLower = msgText.toLowerCase();
    final bool isVideo = message.isVideoCall || msgLower.contains('video');

    final bool isDeclined = msgLower.contains('declined') || msgLower.contains('rejected');
    final bool isEnded = msgLower.contains('ended') ||
        msgLower.contains('duration') ||
        msgLower.contains('completed') ||
        RegExp(r'\d+:\d+').hasMatch(msgText);
    final bool isMissed = !isEnded && (msgLower.contains('missed') ||
        (msgLower.contains('ringing') && !msgLower.contains('ended')));

    String title;
    String subtitle;
    IconData iconData;
    Color iconBgColor;
    Color iconColor;

    if (isDeclined) {
      title = isVideo ? 'Declined Video Call' : 'Declined Audio Call';
      subtitle = 'Declined';
      iconData = isVideo ? Icons.videocam_off_rounded : Icons.phone_disabled_rounded;
      iconBgColor = AppColors.danger.withAlpha(35);
      iconColor = AppColors.danger;
    } else if (isMissed) {
      title = isVideo ? 'Missed Video Call' : 'Missed Audio Call';
      subtitle = 'Missed';
      iconData = isVideo ? Icons.videocam_off_rounded : Icons.phone_missed_rounded;
      iconBgColor = AppColors.danger.withAlpha(35);
      iconColor = AppColors.danger;
    } else if (isEnded) {
      if (msgText.contains('\n')) {
        final lines = msgText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        title = lines[0];
        subtitle = lines.length > 1 ? lines[1] : 'Completed';
      } else {
        title = isVideo ? 'Video Call Is Ended' : 'Audio Call Is Ended';
        final match = RegExp(r'duration[:\s]*([0-9:]+)', caseSensitive: false).firstMatch(msgText) ??
            RegExp(r'\(([^)]+)\)').firstMatch(msgText) ??
            RegExp(r'(\d+:\d+)').firstMatch(msgText);
        if (match != null) {
          final dur = match.group(1) ?? '';
          subtitle = dur.toLowerCase().startsWith('duration') ? dur : 'Duration: $dur';
        } else {
          subtitle = 'Completed';
        }
      }

      iconData = isVideo ? Icons.videocam_rounded : Icons.call_rounded;
      iconBgColor = isMe ? Colors.white.withAlpha(40) : AppColors.primary.withAlpha(35);
      iconColor = isMe ? Colors.white : AppColors.primary;
    } else {
      if (msgText.contains('\n')) {
        final lines = msgText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
        title = lines[0];
        subtitle = lines.length > 1 ? lines[1] : 'Started';
      } else {
        if (isMe) {
          title = isVideo ? 'Outgoing Video Call' : 'Outgoing Audio Call';
        } else {
          title = isVideo ? 'Incoming Video Call' : 'Incoming Audio Call';
        }
        subtitle = 'Started';
      }

      iconData = isVideo
          ? Icons.videocam_rounded
          : (isMe ? Icons.call_made_rounded : Icons.call_received_rounded);
      iconBgColor = isMe ? Colors.white.withAlpha(40) : AppColors.primary.withAlpha(35);
      iconColor = isMe ? Colors.white : AppColors.primary;
    }

    final formattedTime = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
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
                  color: Colors.black.withAlpha(35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isMissed || isDeclined
                                  ? (isMe ? Colors.white.withAlpha(220) : AppColors.danger)
                                  : (isMe ? Colors.white.withAlpha(200) : AppColors.textSecondary),
                              fontWeight: isMissed || isDeclined ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formattedTime,
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
                        color: message.isRead ? Colors.cyanAccent : Colors.white.withAlpha(200),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
