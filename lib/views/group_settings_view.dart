import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// 群设置视图
/// 对应 iOS 版的 GroupSettingsView.swift
class GroupSettingsView extends StatefulWidget {
  final ChatGroup group;
  const GroupSettingsView({super.key, required this.group});

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  final _newNameController = TextEditingController();
  String _message = '';

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  ChatGroup get _group {
    final app = context.read<AppState>();
    final idx = app.groups.indexWhere((g) => g.id == widget.group.id);
    return idx >= 0 ? app.groups[idx] : widget.group;
  }

  String _memberName(int index, String memberId) {
    final g = _group;
    if (g.memberNames != null && index < g.memberNames!.length) {
      return g.memberNames![index];
    }
    final app = context.read<AppState>();
    return app.userById(memberId)?.username ?? memberId;
  }

  String? _memberAvatar(int index, String memberId) {
    final g = _group;
    if (g.memberAvatars != null && index < g.memberAvatars!.length) {
      return g.memberAvatars![index];
    }
    final app = context.read<AppState>();
    return app.userById(memberId)?.avatar;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final g = _group;
    final isOwner = g.owner == app.currentUserId;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('群设置'),
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            card,
            children: [
              Row(
                children: [
                  AvatarWidget(name: g.name, avatarUrl: g.avatar, radius: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: text)),
                        const SizedBox(height: 4),
                        Text('${g.members.length} 人', style: TextStyle(fontSize: 13, color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('群成员', text),
          const SizedBox(height: 8),
          _buildCard(
            card,
            children: [
              for (var i = 0; i < g.members.length; i++)
                _buildMemberRow(
                  context,
                  memberId: g.members[i],
                  name: _memberName(i, g.members[i]),
                  avatar: _memberAvatar(i, g.members[i]),
                  isOwner: g.members[i] == g.owner,
                  canRemove: isOwner && g.members[i] != g.owner,
                  textColor: text,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isOwner) ...[
            _buildSectionTitle('群管理', text),
            const SizedBox(height: 8),
            _buildCard(
              card,
              children: [
                _buildListTile(
                  icon: Icons.edit_outlined,
                  label: '修改群名称',
                  textColor: text,
                  onTap: () => _showRenameDialog(context, g),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.person_add_outlined,
                  label: '添加成员',
                  textColor: text,
                  onTap: () => _showAddMembersSheet(context, g),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.delete_forever_outlined,
                  label: '解散群聊',
                  textColor: AppColors.vtRed,
                  iconColor: AppColors.vtRed,
                  onTap: () => _showConfirmDialog(
                    context,
                    title: '解散群聊',
                    content: '确定要解散「${g.name}」吗？此操作不可撤销。',
                    confirmText: '解散',
                    onConfirm: () {
                      app.groupDissolve(g.id);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildCard(
              card,
              children: [
                _buildListTile(
                  icon: Icons.logout,
                  label: '退出群聊',
                  textColor: AppColors.vtRed,
                  iconColor: AppColors.vtRed,
                  onTap: () => _showConfirmDialog(
                    context,
                    title: '退出群聊',
                    content: '确定要退出「${g.name}」吗？',
                    confirmText: '退出',
                    onConfirm: () {
                      app.groupLeave(g.id);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_message, style: const TextStyle(color: AppColors.vtRed, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Color card, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vtBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildMemberRow(
    BuildContext context, {
    required String memberId,
    required String name,
    required String? avatar,
    required bool isOwner,
    required bool canRemove,
    required Color textColor,
  }) {
    final app = context.read<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AvatarWidget(name: name, avatarUrl: avatar, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: TextStyle(fontSize: 14, color: textColor)),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.vtGreen, AppColors.vtAccent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('群主', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: AppColors.vtRed, size: 20),
              onPressed: () => _showConfirmDialog(
                context,
                title: '移除成员',
                content: '确定要移除「$name」吗？',
                confirmText: '移除',
                onConfirm: () {
                  app.groupRemoveMember(_group.id, memberId);
                  Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: iconColor ?? AppColors.vtAccent),
      title: Text(label, style: TextStyle(fontSize: 14, color: textColor)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.vtMuted),
      onTap: onTap,
    );
  }

  void _showRenameDialog(BuildContext context, ChatGroup g) {
    _newNameController.text = g.name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改群名称'),
        content: TextField(
          controller: _newNameController,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '新群名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final newName = _newNameController.text.trim();
              if (newName.isNotEmpty) {
                context.read<AppState>().groupRename(g.id, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersSheet(BuildContext context, ChatGroup g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGroupMembersSheet(group: g),
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: onConfirm,
            style: TextButton.styleFrom(foregroundColor: AppColors.vtRed),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// 添加群成员弹窗
class AddGroupMembersSheet extends StatefulWidget {
  final ChatGroup group;
  const AddGroupMembersSheet({super.key, required this.group});

  @override
  State<AddGroupMembersSheet> createState() => _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends State<AddGroupMembersSheet> {
  final Set<String> _selected = {};

  List<User> get _availableFriends {
    final app = context.read<AppState>();
    return app.friends.where((f) => !widget.group.members.contains(f.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final available = _availableFriends;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.vtCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('添加成员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: available.isEmpty
                ? Center(child: Text('没有可添加的好友', style: TextStyle(color: AppColors.vtMuted)))
                : ListView.builder(
                    itemCount: available.length,
                    itemBuilder: (context, i) {
                      final friend = available[i];
                      final selected = _selected.contains(friend.id);
                      return ListTile(
                        leading: AvatarWidget(name: friend.username, avatarUrl: friend.avatar, radius: 18),
                        title: Text(friend.username, style: TextStyle(color: text)),
                        trailing: selected
                            ? const Icon(Icons.check_circle, color: AppColors.vtGreen)
                            : const Icon(Icons.radio_button_unchecked, color: AppColors.vtMuted),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selected.remove(friend.id);
                            } else {
                              _selected.add(friend.id);
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
              onPressed: _selected.isEmpty
                  ? null
                  : () {
                      app.groupAddMembers(widget.group.id, _selected.toList());
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vtGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('确定添加 (${_selected.length})'),
            ),
          ),
        ],
      ),
    );
  }
}
