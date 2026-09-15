/// 服务器配置
class ServerConfig {
  static const String defaultBaseUrl = 'https://buer.kdns.fr';

  String baseUrl = defaultBaseUrl;

  String get wsUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring(8)}/ws';
    }
    // 未带协议的裸主机名，默认按加密连接处理
    return 'wss://$baseUrl/ws';
  }

  String urlFor(String path) => '$baseUrl$path';

  String resourceUrlFor(String path) {
    if (path.startsWith('https://')) return path;
    return '$baseUrl$path';
  }
}
