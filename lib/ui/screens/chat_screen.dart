import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoomModel room;
  final VoidCallback? onBack;

  const ChatScreen({super.key, required this.room, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  bool _isVoiceRecording = false;
  final List<File> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    if (_editingMessage != null) {
      await chatProvider.editMessage(_editingMessage!.id, text);
      setState(() {
        _editingMessage = null;
        _textCtrl.clear();
      });
      return;
    }

    final replyId = _replyingTo?.id;
    final filesToSend = List<File>.from(_attachedFiles);

    _textCtrl.clear();
    setState(() {
      _replyingTo = null;
      _attachedFiles.clear();
    });

    chatProvider.sendTyping(false);
    final success = await chatProvider.sendMessage(
      text: text,
      replyMessageId: replyId,
      files: filesToSend.isNotEmpty ? filesToSend : null,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Photos & Videos'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _attachedFiles.add(File(picked.path)));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.blueAccent),
                title: const Text('Camera Photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _imagePicker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _attachedFiles.add(File(picked.path)));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file_rounded, color: Colors.amber),
                title: const Text('Document / Any File'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await FilePicker.pickFiles();
                  if (res.isNotEmpty) {
                    setState(() {
                      for (final p in res) {
                        if (p.path != null) _attachedFiles.add(File(p.path!));
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCall(CallType type) async {
    final auth = context.read<AuthProvider>();
    final call = context.read<CallProvider>();
    final currentUserId = auth.user?.id ?? '';

    String targetId = '';
    String targetName = widget.room.name;
    String? targetAvatar = widget.room.avatar;

    if (!widget.room.isGroup) {
      final other = widget.room.members.firstWhere(
        (m) => m.memberId != currentUserId,
        orElse: () => widget.room.members.isNotEmpty ? widget.room.members.first : widget.room.members.first,
      );
      targetId = other.memberId;
      targetName = other.name;
      targetAvatar = other.avatar;
    }

    await call.startCall(
      targetUserId: targetId,
      roomId: widget.room.id,
      type: type,
      targetName: targetName,
      targetAvatar: targetAvatar,
      isGroup: widget.room.isGroup,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallScreen()),
      );
    }
  }

  void _joinOngoingCall({required bool isVideo}) async {
    final call = context.read<CallProvider>();
    await call.joinCall(
      roomId: widget.room.id,
      isVideo: isVideo,
      roomName: widget.room.name,
      roomAvatar: widget.room.avatar,
    );
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallScreen()),
      );
    }
  }

  Widget _buildOngoingCallBanner(BuildContext context, bool isVideo, int participantCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF059669),
            Color(0xFF0F766E),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withAlpha(70),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: Icon(
              isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isVideo ? 'Ongoing Group Video Call' : 'Ongoing Group Voice Call',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  participantCount > 0 ? '$participantCount participant(s) in call' : 'Tap to join',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: () => _joinOngoingCall(isVideo: isVideo),
            child: const Text(
              'Join',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currentRoom = chat.rooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => chat.activeRoom ?? widget.room,
    );
    final auth = context.watch<AuthProvider>();
    final socket = context.watch<SocketProvider>();
    final call = context.watch<CallProvider>();

    final currentUserId = auth.user?.id ?? '';
    final roomName = currentRoom.getDisplayName(currentUserId);
    final roomAvatar = currentRoom.getDisplayAvatar(currentUserId);
    final isOnline = currentRoom.isOtherUserOnline(currentUserId, socket.onlineUserIds);

    final messages = chat.activeMessages;
    final typingUserIds = chat.getActiveTypingUsers();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              )
            : null,
        title: GestureDetector(
          onTap: currentRoom.isGroup
              ? () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => GroupInfoSheet(room: currentRoom),
                  );
                }
              : null,
          child: Row(
            children: [
              CustomAvatar(
                name: roomName,
                avatarUrl: roomAvatar,
                size: 40,
                isOnline: isOnline,
                showOnlineBadge: !currentRoom.isGroup,
                isGroup: currentRoom.isGroup,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentRoom.isGroup
                          ? '${currentRoom.members.length} members'
                          : (isOnline ? 'Online' : 'Offline'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isOnline ? AppColors.online : AppColors.textSecondary,
                        fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.primaryLight, size: 22),
            onPressed: () => _startCall(CallType.audio),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.primaryLight, size: 24),
            onPressed: () => _startCall(CallType.video),
          ),
          if (currentRoom.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => GroupInfoSheet(room: currentRoom),
                );
              },
            ),
        ],
      ),
      body: ChatBackground(
        child: Column(
          children: [
            if (currentRoom.isGroup &&
                chat.isGroupCallOngoing(currentRoom.id) &&
                call.callStatus == CallStatus.idle)
              _buildOngoingCallBanner(
                context,
                chat.getGroupCallStatus(currentRoom.id)?['is_video'] ??
                    (chat.getActiveCallMessage(currentRoom.id)?.isVideoCall ?? true),
                chat.getGroupCallStatus(currentRoom.id)?['participant_count'] ?? 0,
              ),
            // Messages Feed
            Expanded(
            child: chat.isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No messages yet',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Send a message to start the conversation',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          final isMe = msg.senderId == currentUserId;
                          return MessageBubble(
                            message: msg,
                            isMe: isMe,
                            isGroup: widget.room.isGroup,
                            onReply: () {
                              setState(() {
                                _replyingTo = msg;
                                _editingMessage = null;
                              });
                            },
                            onEdit: () {
                              setState(() {
                                _editingMessage = msg;
                                _replyingTo = null;
                                _textCtrl.text = msg.message;
                              });
                            },
                            onDelete: () => chat.deleteMessage(msg.id),
                            onReact: (emoji) => chat.reactToMessage(msg.id, emoji),
                          );
                        },
                      ),
          ),

          // Typing indicator banner
          if (typingUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Someone is typing...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.primaryLight),
                  ),
                ],
              ),
            ),

          // Replying to / Editing indicator bar
          if (_replyingTo != null || _editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit_rounded : Icons.reply_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingMessage != null
                              ? 'Editing message'
                              : 'Replying to ${_replyingTo?.sender?.name ?? 'message'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          _editingMessage?.message ?? _replyingTo?.message ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      setState(() {
                        _replyingTo = null;
                        _editingMessage = null;
                        _textCtrl.clear();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Attached files preview strip
          if (_attachedFiles.isNotEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppColors.surface,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedFiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final file = _attachedFiles[index];
                  final name = file.path.split('/').last.split('\\').last;
                  return Chip(
                    backgroundColor: AppColors.card,
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => setState(() => _attachedFiles.removeAt(index)),
                  );
                },
              ),
            ),

          // Voice Recorder or Input Bar
          if (_isVoiceRecording)
            VoiceRecordBar(
              onSendVoice: (file) async {
                setState(() => _isVoiceRecording = false);
                await chat.sendMessage(text: '', files: [file]);
                _scrollToBottom();
              },
              onCancel: () => setState(() => _isVoiceRecording = false),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary, size: 24),
                      onPressed: _pickAttachment,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 4,
                        minLines: 1,
                        onChanged: (val) {
                          chat.sendTyping(val.isNotEmpty);
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_textCtrl.text.trim().isEmpty && _attachedFiles.isEmpty)
                      IconButton(
                        icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
                        onPressed: () => setState(() => _isVoiceRecording = true),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          onPressed: _handleSend,
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
}
