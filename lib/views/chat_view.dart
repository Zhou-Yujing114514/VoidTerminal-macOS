import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'group_settings_view.dart';

class ChatView extends StatefulWidget {
  final Room room;
  const ChatView({super.key, required this.room});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<AppState>().sendMessage(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _openGroupSettings() {
    final app = context.read<AppState>();
    final group = app.groups.firstWhere(
      (g) => g.id == widget.room.id,
      orElse: () => ChatGroup(
        id: widget.room.id,
        name: widget.room.name,
        owner: '',
        members: [],
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupSettingsView(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final msgs = app.messagesFor(widget.room);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final isGroup = widget.room.type == 'group';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients && msgs.isNotEmpty) {
        // 新消息时滚动到底部
      }
    });

    return Column(
      children: [
        Container(
          height: 56,
          color: card,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(widget.room.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
              const SizedBox(width: 10),
              if (widget.room.type == 'global')
                Text('在线 ${app.onlineUsers.length}', style: TextStyle(fontSize: 12, color: muted)),
              const Spacer(),
              if (app.announcement.isNotEmpty)
                Tooltip(
                  message: app.announcement,
                  child: Icon(Icons.campaign_outlined, size: 18, color: AppColors.vtAmber),
                ),
              if (isGroup) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: muted,
                  onPressed: _openGroupSettings,
                  tooltip: '群设置',
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: bg,
            child: msgs.isEmpty
                ? Center(child: Text('暂无消息', style: TextStyle(color: muted)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      msg: msgs[i],
                      onRecall: msgs[i].isFromMe
                          ? () => context.read<AppState>().recallMessage(msgs[i])
                          : null,
                      onNameTap: msgs[i].isFromMe
                          ? null
                          : () => context.read<AppState>().openRoom(
                                Room('dm', msgs[i].from, msgs[i].fromName ?? msgs[i].from),
                              ),
                    ),
                  ),
          ),
        ),
        Container(
          color: card,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  style: TextStyle(color: text),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: muted),
                    filled: true,
                    fillColor: bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vtAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback? onRecall;
  final VoidCallback? onNameTap;

  const _MessageBubble({required this.msg, this.onRecall, this.onNameTap});

  String _fmtTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = msg.isFromMe;
    final name = msg.fromName ?? msg.from;
    final isBot = msg.fromBot == true || msg.fromRole == 'bot';
    final baseUrl = context.read<AppState>().config.baseUrl;

    final avatar = AvatarWidget(name: name, avatarUrl: msg.fromAvatar, radius: 18);

    final bubble = Column(
      crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: onNameTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isBot ? AppColors.vtGreen : (me ? AppColors.vtAccent : AppColors.vtMuted),
                  ),
                ),
                if (isBot) const SizedBox(width: 4),
                if (isBot) const Text('🤖', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onLongPress: onRecall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: me ? AppColors.vtAccent : (isDark ? AppColors.vtCard : Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.content.isNotEmpty)
                  Text(
                    msg.content,
                    style: TextStyle(fontSize: 14, color: me ? Colors.white : (isDark ? AppColors.vtText : const Color(0xFF333333)), height: 1.4),
                  ),
                if (msg.images != null && msg.images!.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: msg.images!.map((u) {
                      final url = u.startsWith('http') ? u : '$baseUrl$u';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          url,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160, height: 160, color: AppColors.vtBorder,
                            child: const Icon(Icons.broken_image, color: AppColors.vtMuted),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(_fmtTime(msg.time), style: const TextStyle(fontSize: 10, color: AppColors.vtMuted)),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: me
            ? [
                Expanded(child: Align(alignment: Alignment.centerRight, child: bubble)),
                const SizedBox(width: 8),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 8),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: bubble)),
              ],
      ),
    );
  }
}
