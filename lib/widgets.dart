import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'theme.dart';

/// 统一的带缓存网络图片组件。
///
/// 基于 cached_network_image，对头像/消息图/朋友圈图做磁盘 + 内存缓存，
/// 避免每次滚动都重复下载。加载中显示占位，失败显示破图占位。
class VtNetworkImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final BoxShape shape;

  const VtNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: AppColors.vtBorder,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vtMuted),
          ),
        ),
      ),
      errorWidget: (context, _, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.vtBorder,
          shape: shape,
        ),
        child: const Icon(Icons.broken_image, color: AppColors.vtMuted),
      ),
    );
  }
}

/// 头像组件：有头像 URL 时加载缓存图片，否则显示首字母
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
        child: VtNetworkImage(
          url: url,
          width: radius * 2,
          height: radius * 2,
          shape: BoxShape.circle,
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
