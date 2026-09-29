import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

class GroupInfoSheet extends StatefulWidget {
  final ChatRoomModel room;

  const GroupInfoSheet({super.key, required this.room});

  @override
  State<GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<GroupInfoSheet> {
  final AuthService _authService = AuthService();

  void _showAddMemberDialog() async {
    final chat = context.read<ChatProvider>();
    final currentRoom = chat.rooms.firstWhere(
      (r) => r.id == widget.room.id,
      orElse: () => chat.activeRoom ?? widget.room,
    );
    final results = await _authService.searchUsers('');
    final currentMemberIds = currentRoom.members.map((m) => m.memberId).toSet();
    final nonMembers = results.where((u) => !currentMemberIds.contains(u.id)).toList();

    if (!mounted) return;

    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: nonMembers.isEmpty
                      ? const Center(child: Text('No users to add', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          itemCount: nonMembers.length,
                          itemBuilder: (context, index) {
                            final user = nonMembers[index];
                            final isSel = selectedIds.contains(user.id);
                            return CheckboxListTile(
                              secondary: CustomAvatar(name: user.name, avatarUrl: user.avatar, size: 36),
                              title: Text(user.name),
                              subtitle: Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              value: isSel,
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              onChanged: (v) {
                                setDlgState(() {
                                  if (v == true) {
                                    selectedIds.add(user.id);
                                  } else {
                                    selectedIds.remove(user.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () async {
                              final chatProv = context.read<ChatProvider>();
                              Navigator.pop(ctx);
                              await chatProv.addMembersToGroup(
                                widget.room.id,
                                selectedIds.toList(),
                              );
                            },
                      child: const Text('Add Selected'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final currentUserId = context.watch<AuthProvider>().user?.id ?? '';
    final isGroupAdmin = currentRoom.members.any((m) => m.memberId == currentUserId && m.isAdmin) ||
        currentRoom.createdById == currentUserId;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          CustomAvatar(
            name: currentRoom.name,
            avatarUrl: currentRoom.avatar,
            size: 72,
            isGroup: true,
          ),
          const SizedBox(height: 12),
          Text(
            currentRoom.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${currentRoom.members.length} Members',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Group Members',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isGroupAdmin)
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Add Member', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  onPressed: _showAddMemberDialog,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: currentRoom.members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = currentRoom.members[index];
                final isSelf = member.memberId == currentUserId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CustomAvatar(
                    name: member.name,
                    avatarUrl: member.avatar,
                    size: 38,
                    isOnline: member.isOnline,
                    showOnlineBadge: true,
                  ),
                  title: Row(
                    children: [
                      Text(
                        member.name + (isSelf ? ' (You)' : ''),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (member.isAdmin || member.memberId == currentRoom.createdById) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: member.email != null
                      ? Text(member.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                      : null,
                  trailing: isGroupAdmin && !isSelf
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.danger, size: 20),
                          onPressed: () async {
                            await context.read<ChatProvider>().removeMemberFromGroup(
                              currentRoom.id,
                              member.memberId,
                            );
                          },
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                foregroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: Text(isGroupAdmin ? 'Delete / Leave Group' : 'Leave Group'),
              onPressed: () async {
                Navigator.pop(context);
                if (isGroupAdmin) {
                  await context.read<ChatProvider>().deleteRoom(currentRoom.id);
                } else {
                  await context.read<ChatProvider>().removeMemberFromGroup(currentRoom.id, currentUserId);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
