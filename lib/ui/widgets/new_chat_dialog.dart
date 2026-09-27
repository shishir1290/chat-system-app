import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class NewChatDialog extends StatefulWidget {
  const NewChatDialog({super.key});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _groupNameCtrl = TextEditingController();

  List<UserModel> _searchResults = [];
  final Set<String> _selectedMemberIds = {};
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _performSearch('');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await _authService.searchUsers(query);
      if (!mounted) return;
      final currentUserId = context.read<AuthProvider>().user?.id;
      setState(() {
        _searchResults = results.where((u) => u.id != currentUserId).toList();
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _startDirectChat(UserModel targetUser) async {
    setState(() => _isCreating = true);
    final chatProvider = context.read<ChatProvider>();
    final room = await chatProvider.createPeerChat(targetUser.id);
    if (mounted) {
      setState(() => _isCreating = false);
      if (room != null) {
        Navigator.pop(context);
        chatProvider.selectRoom(room);
      }
    }
  }

  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty || _selectedMemberIds.isEmpty) return;

    setState(() => _isCreating = true);
    final chatProvider = context.read<ChatProvider>();
    final room = await chatProvider.createGroupChat(name, _selectedMemberIds.toList());
    if (mounted) {
      setState(() => _isCreating = false);
      if (room != null) {
        Navigator.pop(context);
        chatProvider.selectRoom(room);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Text(
                  'New Conversation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Direct Message'),
                  Tab(text: 'Create Group'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Direct Message Search
                  Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search people by name or email...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isSearching
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : _searchResults.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No users found',
                                      style: TextStyle(color: AppColors.textMuted),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final user = _searchResults[index];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        leading: CustomAvatar(
                                          name: user.name,
                                          avatarUrl: user.avatar,
                                          isOnline: user.isOnline,
                                          showOnlineBadge: true,
                                        ),
                                        title: Text(
                                          user.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          user.email,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: AppColors.textMuted,
                                        ),
                                        onTap: () => _startDirectChat(user),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),

                  // Tab 2: Create Group
                  Column(
                    children: [
                      TextField(
                        controller: _groupNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Group Name...',
                          prefixIcon: Icon(Icons.groups_rounded, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Members:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _isSearching
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  final isSelected = _selectedMemberIds.contains(user.id);
                                  return CheckboxListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    secondary: CustomAvatar(
                                      name: user.name,
                                      avatarUrl: user.avatar,
                                      size: 36,
                                    ),
                                    title: Text(user.name, style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    checkColor: Colors.black,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedMemberIds.add(user.id);
                                        } else {
                                          _selectedMemberIds.remove(user.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isCreating || _selectedMemberIds.isEmpty ? null : _createGroup,
                          child: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  'Create Group (${_selectedMemberIds.length} selected)',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
