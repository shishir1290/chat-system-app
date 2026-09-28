import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/socket_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/new_chat_dialog.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<SocketProvider>().connect(auth.token!, auth.user!.id);
        context.read<ChatProvider>().initializeWithUser(auth.user!.id);
        context.read<ChatProvider>().loadRooms();
        context.read<CallProvider>().initialize(auth.user!);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ChatProvider>().loadRooms(silent: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatRoomTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays == 0) {
      return DateFormat('hh:mm a').format(local);
    } else if (now.difference(local).inDays < 7) {
      return DateFormat('E').format(local);
    }
    return DateFormat('MM/dd').format(local);
  }

  void _openNewChatDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewChatDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final socket = context.watch<SocketProvider>();

    final user = auth.user;
    final currentUserId = user?.id ?? '';

    // Filter rooms by search query
    final filteredRooms = chat.rooms.where((room) {
      final name = room.getDisplayName(currentUserId).toLowerCase();
      final lastMsg = room.lastMessage?.message.toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || lastMsg.contains(q);
    }).toList();

    final isWideScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWideScreen
          ? Row(
              children: [
                // Left Sidebar
                SizedBox(
                  width: 360,
                  child: _buildSidebar(context, user, currentUserId, filteredRooms, socket, chat, isWideScreen: true),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                // Right Chat Pane
                Expanded(
                  child: chat.activeRoom != null
                      ? ChatScreen(
                          room: chat.activeRoom!,
                          onBack: () => chat.selectRoom(null),
                        )
                      : _buildEmptyState(),
                ),
              ],
            )
          : _buildSidebar(context, user, currentUserId, filteredRooms, socket, chat, isWideScreen: false),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    dynamic user,
    String currentUserId,
    List<ChatRoomModel> filteredRooms,
    SocketProvider socket,
    ChatProvider chat, {
    required bool isWideScreen,
  }) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: CustomAvatar(
                      name: user?.name ?? 'User',
                      avatarUrl: user?.avatar,
                      size: 40,
                      isOnline: true,
                      showOnlineBadge: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nexora Chat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_square, color: AppColors.primary, size: 20),
                      onPressed: _openNewChatDialog,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search chats & people...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: chat.isLoadingRooms && chat.rooms.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => chat.loadRooms(),
                      child: filteredRooms.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.textMuted),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'No conversations found',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Tap below to browse users and start a chat',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.add_comment_rounded, size: 18),
                                            label: const Text('Start a new chat'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: _openNewChatDialog,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                            itemCount: filteredRooms.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
                            itemBuilder: (context, index) {
                              final room = filteredRooms[index];
                              final isSelected = chat.activeRoom?.id == room.id;
                              final isOnline = room.isOtherUserOnline(currentUserId, socket.onlineUserIds);
                              final displayName = room.getDisplayName(currentUserId);
                              final displayAvatar = room.getDisplayAvatar(currentUserId);
                              final lastMsg = room.lastMessage;

                              return Material(
                                color: isSelected ? AppColors.cardHover.withAlpha(150) : Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CustomAvatar(
                                    name: displayName,
                                    avatarUrl: displayAvatar,
                                    size: 48,
                                    isOnline: isOnline,
                                    showOnlineBadge: !room.isGroup,
                                    isGroup: room.isGroup,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (lastMsg != null)
                                        Text(
                                          _formatRoomTime(lastMsg.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: room.unreadCount > 0 ? AppColors.primaryLight : AppColors.textMuted,
                                            fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMsg != null
                                              ? (lastMsg.isDeleted
                                                  ? 'Message deleted'
                                                  : (lastMsg.files.isNotEmpty
                                                      ? '📎 Attachment'
                                                      : lastMsg.message))
                                              : (room.isGroup ? 'Group created' : 'Start chatting'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                            fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (room.unreadCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${room.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    chat.selectRoom(room);
                                    if (!isWideScreen) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            room: room,
                                            onBack: () {
                                              chat.selectRoom(null);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.forum_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a contact from the sidebar or start a new direct message or group.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _openNewChatDialog,
            ),
          ],
        ),
      ),
    );
  }
}
