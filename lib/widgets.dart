import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'theme.dart';

/// 头像组件：有头像 URL 时加载图片，否则显示首字母
class AvatarWidget extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.read<AppState>().config.baseUrl;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      final url = avatarUrl!.startsWith('http') ? avatarUrl! : '$baseUrl$avatarUrl';
      return ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.vtAccent,
      child: Text(
        name.isNotEmpty ? name.characters.first : '?',
        style: TextStyle(color: Colors.white, fontSize: radius * 0.8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
