import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'two_fa_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final totpEnabled = app.currentUser?.totpEnabled == true;

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('我的', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                // 用户信息
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      AvatarWidget(name: app.currentUser?.username ?? '?', avatarUrl: app.currentUser?.avatar, radius: 28),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.currentUser?.username ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
                          const SizedBox(height: 4),
                          Text(
                            app.currentUser?.isAdmin == true ? '站长' : (app.currentUser?.isBot == true ? '机器人' : '普通用户'),
                            style: TextStyle(fontSize: 13, color: app.isAdmin ? AppColors.vtAmber : muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 账号设置
                Container(
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _settingItem(context, Icons.edit_outlined, '修改用户名', () => _changeUsername(context, app)),
                      const Divider(height: 1),
                      _settingItem(context, Icons.lock_outline, '修改密码', () => _changePassword(context, app)),
                      const Divider(height: 1),
                      _settingItem(
                        context,
                        Icons.verified_user_outlined,
                        '两步验证',
                        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TwoFAView())),
                        trailing: totpEnabled
                            ? const Icon(Icons.check_circle, color: AppColors.vtGreen, size: 18)
                            : null,
                      ),
                      if (app.isAdmin) ...[
                        const Divider(height: 1),
                        _settingItem(context, Icons.cleaning_services_outlined, '清空公共大厅', () => app.clearHall()),
                        const Divider(height: 1),
                        _settingItem(context, Icons.campaign_outlined, '发布公告', () => _announce(context, app)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 退出登录
                Container(
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                  child: _settingItem(context, Icons.logout, '退出登录', () => app.logout(), color: AppColors.vtRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? AppColors.vtAccent),
      title: Text(label, style: TextStyle(fontSize: 14, color: color ?? text)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppColors.vtMuted),
      onTap: onTap,
    );
  }

  void _changeUsername(BuildContext context, AppState app) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改用户名'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '新用户名')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final t = app.token;
              if (t != null) {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  try {
                    final u = await app.api.changeUsername(t, name);
                    app.currentUser = u;
                    app.refresh();
                  } catch (e) {
                    app.showToast('修改失败: $e');
                  }
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _changePassword(BuildContext context, AppState app) {
    final oldP = TextEditingController();
    final newP = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: '旧密码')),
            TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: '新密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final t = app.token;
              if (t != null) {
                try {
                  await app.api.changePassword(t, oldP.text, newP.text, newP.text);
                  app.showToast('密码修改成功');
                } catch (e) {
                  app.showToast('修改失败: $e');
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _announce(BuildContext context, AppState app) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发布公告'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '公告内容')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) app.announce(t);
              Navigator.pop(ctx);
            },
            child: const Text('发布'),
          ),
        ],
      ),
    );
  }
}
