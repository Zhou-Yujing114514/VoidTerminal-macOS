import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;

    return Container(
      color: isDark ? AppColors.vtBg : const Color(0xFFf5f5f0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('联系人', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 好友列表
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text('好友 (${app.friends.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: app.friends.isEmpty
                              ? Center(child: Text('暂无好友', style: TextStyle(color: muted)))
                              : ListView.builder(
                                  itemCount: app.friends.length,
                                  itemBuilder: (context, i) {
                                    final f = app.friends[i];
                                    final online = app.isOnline(f.id);
                                    return ListTile(
                                      leading: Stack(
                                        children: [
                                          AvatarWidget(name: f.username, avatarUrl: f.avatar, radius: 20),
                                          if (online)
                                            Positioned(
                                              right: 0, bottom: 0,
                                              child: Container(width: 10, height: 10,
                                                decoration: BoxDecoration(color: AppColors.vtGreen, shape: BoxShape.circle)),
                                            ),
                                        ],
                                      ),
                                      title: Text(f.username, style: TextStyle(color: text, fontSize: 14)),
                                      subtitle: Text(online ? '在线' : '离线', style: TextStyle(color: muted, fontSize: 12)),
                                      onTap: () {
                                        app.openRoom(Room('dm', f.id, f.username));
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧操作区
                Container(
                  width: 300,
                  margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddFriendCard(app: app, text: text, muted: muted),
                      const SizedBox(height: 12),
                      _RequestsCard(app: app, text: text, muted: muted, card: card),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFriendCard extends StatelessWidget {
  final AppState app;
  final Color text;
  final Color muted;
  const _AddFriendCard({required this.app, required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('加好友', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText: '输入用户名',
              hintStyle: TextStyle(color: muted),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final u = controller.text.trim();
                if (u.isNotEmpty) app.sendFriendRequest(u);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.vtAccent, foregroundColor: Colors.white),
              child: const Text('发送申请'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  final AppState app;
  final Color text;
  final Color muted;
  final Color card;
  const _RequestsCard({required this.app, required this.text, required this.muted, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('好友申请 (${app.pendingRequests.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
          const SizedBox(height: 8),
          if (app.pendingRequests.isEmpty)
            Text('暂无申请', style: TextStyle(color: muted, fontSize: 13))
          else
            ...app.pendingRequests.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.fromName, style: TextStyle(color: text, fontSize: 13))),
                      TextButton(
                        onPressed: () => app.respondRequest(r.id, 'accept'),
                        child: const Text('接受', style: TextStyle(color: AppColors.vtGreen)),
                      ),
                      TextButton(
                        onPressed: () => app.respondRequest(r.id, 'reject'),
                        child: const Text('拒绝', style: TextStyle(color: AppColors.vtRed)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
