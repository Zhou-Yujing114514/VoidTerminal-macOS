import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'moments_view.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);

    return Container(
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('发现', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：朋友圈
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_outlined, color: AppColors.vtGreen),
                              const SizedBox(width: 10),
                              Text('朋友圈', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text)),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsView()));
                                },
                                child: const Text('进入', style: TextStyle(color: AppColors.vtAccent)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('我的群聊 (${app.groups.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: app.groups.isEmpty
                                      ? Center(child: Text('暂无群聊', style: TextStyle(color: muted)))
                                      : ListView.builder(
                                          itemCount: app.groups.length,
                                          itemBuilder: (context, i) {
                                            final g = app.groups[i];
                                            return ListTile(
                                              leading: AvatarWidget(name: g.name, avatarUrl: g.avatar, radius: 20),
                                              title: Text(g.name, style: TextStyle(color: text, fontSize: 14)),
                                              subtitle: Text('${g.members.length} 人', style: TextStyle(color: muted, fontSize: 12)),
                                              onTap: () {
                                                app.openRoom(Room('group', g.id, g.name));
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧：搜索群
                SizedBox(
                  width: 360,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('搜索群聊', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                        const SizedBox(height: 10),
                        TextField(
                          style: TextStyle(color: text),
                          onChanged: (v) => app.searchGroups(v),
                          decoration: InputDecoration(
                            hintText: '输入群名关键词',
                            hintStyle: TextStyle(color: muted),
                            prefixIcon: const Icon(Icons.search, color: AppColors.vtMuted),
                            filled: true,
                            fillColor: bg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: app.isSearching
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  itemCount: app.searchResults.length,
                                  itemBuilder: (context, i) {
                                    final g = app.searchResults[i];
                                    return ListTile(
                                      leading: const Icon(Icons.group, color: AppColors.vtAmber),
                                      title: Text(g.name, style: TextStyle(color: text, fontSize: 14)),
                                      subtitle: Text('${g.memberCount ?? 0} 人 · 群主: ${g.ownerName ?? '未知'}', style: TextStyle(color: muted, fontSize: 12)),
                                      trailing: TextButton(
                                        onPressed: () => app.applyToGroup(g.id),
                                        child: const Text('申请加入', style: TextStyle(color: AppColors.vtGreen)),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
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
