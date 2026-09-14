import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'messages_view.dart';
import 'contacts_view.dart';
import 'discover_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (app.token != null && !app.ws.isConnected) {
        app.ws.connect(app.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Row(
            children: [
              // 左侧导航
              Container(
                width: 72,
                color: isDark ? AppColors.vtCard : Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 头像
                    AvatarWidget(name: app.currentUser?.username ?? '?', avatarUrl: app.currentUser?.avatar, radius: 22),
                    const SizedBox(height: 24),
                    _navItem(Icons.chat_bubble_outline, '消息', 0),
                    _navItem(Icons.people_outline, '联系人', 1),
                    _navItem(Icons.explore_outlined, '发现', 2),
                    _navItem(Icons.person_outline, '我的', 3),
                    const Spacer(),
                  ],
                ),
              ),
              // 右侧内容
              Expanded(
                child: IndexedStack(
                  index: app.currentTab,
                  children: const [
                    MessagesView(),
                    ContactsView(),
                    DiscoverView(),
                    ProfileView(),
                  ],
                ),
              ),
            ],
          ),
          // 网络断开/重连指示
          if (!app.serverConnected && app.token != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.vtRed.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('正在重连…',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ),
          // 全局 toast
          if (app.toast != null)
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(app.toast!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx) {
    final app = context.read<AppState>();
    final selected = app.currentTab == idx;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        app.currentTab = idx;
        app.refresh();
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 26, color: selected ? AppColors.vtAccent : (isDark ? AppColors.vtMuted : const Color(0xFF888888))),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? AppColors.vtAccent : (isDark ? AppColors.vtMuted : const Color(0xFF888888)))),
          ],
        ),
      ),
    );
  }
}
