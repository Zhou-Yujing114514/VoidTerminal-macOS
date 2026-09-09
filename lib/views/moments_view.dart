import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class MomentsView extends StatefulWidget {
  const MomentsView({super.key});

  @override
  State<MomentsView> createState() => _MomentsViewState();
}

class _MomentsViewState extends State<MomentsView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _fmtTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${d.month}-${d.day} ${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final sorted = [...app.moments]..sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('朋友圈'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          // 发布区
          Container(
            color: card,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      hintText: '分享新鲜事...',
                      hintStyle: TextStyle(color: muted),
                      filled: true,
                      fillColor: bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final t = _input.text.trim();
                    if (t.isEmpty) return;
                    // 通过 ws 发朋友圈（服务端用 moment-post HTTP，这里简化：文字走 HTTP 需要 token）
                    _postMoment(app, t);
                    _input.clear();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.vtGreen, foregroundColor: Colors.white),
                  child: const Text('发布'),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: sorted.isEmpty
                ? Center(child: Text('还没有朋友圈，快来发布第一条吧', style: TextStyle(color: muted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => _MomentCard(moment: sorted[i], fmtTime: _fmtTime),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _postMoment(AppState app, String text) async {
    final t = app.token;
    if (t == null) return;
    try {
      await app.api.postMoment(t, text, []);
      app.showToast('发布成功');
    } catch (e) {
      app.showToast('发布失败: $e');
    }
  }
}

class _MomentCard extends StatelessWidget {
  final Moment moment;
  final String Function(int) fmtTime;

  const _MomentCard({required this.moment, required this.fmtTime});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final liked = moment.likes.contains(app.currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: moment.authorName ?? '?', avatarUrl: moment.authorAvatar, radius: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(moment.authorName ?? '未知', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                  Text(fmtTime(moment.time), style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
              const Spacer(),
              if (moment.author == app.currentUserId)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.vtMuted),
                  onPressed: () => app.momentDelete(moment.id),
                ),
            ],
          ),
          if (moment.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(moment.text, style: TextStyle(fontSize: 14, color: text, height: 1.5)),
          ],
          if (moment.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: moment.images.map((u) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(app.config.resourceUrlFor(u), width: 120, height: 120, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 120, height: 120, color: AppColors.vtBorder, child: const Icon(Icons.broken_image, color: AppColors.vtMuted))),
              )).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () => app.momentLike(moment.id),
                child: Row(
                  children: [
                    Icon(liked ? Icons.favorite : Icons.favorite_border, size: 18, color: liked ? AppColors.vtRed : muted),
                    if (moment.likes.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text('${moment.likes.length}', style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              InkWell(
                onTap: () => _showCommentDialog(context, app, moment.id),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: muted),
                    if (moment.comments.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text('${moment.comments.length}', style: TextStyle(fontSize: 12, color: muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (moment.comments.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...moment.comments.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(TextSpan(
                children: [
                  TextSpan(text: '${c.userName ?? '未知'}: ', style: TextStyle(fontSize: 12, color: AppColors.vtAccent)),
                  TextSpan(text: c.text, style: TextStyle(fontSize: 12, color: text)),
                ],
              )),
            )),
          ],
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context, AppState app, String mid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('评论'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入评论'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) app.momentComment(mid, t);
              Navigator.pop(ctx);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}
