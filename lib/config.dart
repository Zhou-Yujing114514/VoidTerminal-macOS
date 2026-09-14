/// 服务器配置
class ServerConfig {
  static const String defaultBaseUrl = 'https://buer.kdns.fr';

  String baseUrl = defaultBaseUrl;

  String get wsUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring(8)}/ws';
    } else if (baseUrl.startsWith('http://')) {
      // 注意：仅当用户手动配置了 http:// 明文地址时才会走到这里，
      // 默认地址已强制使用 https/wss。
      return 'wss://${baseUrl.substring(7)}/ws';
    }
    // 未带协议的裸主机名，默认按加密连接处理
    return 'wss://$baseUrl/ws';
  }

  String urlFor(String path) => '$baseUrl$path';

  String resourceUrlFor(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
