/// 服务器配置
class ServerConfig {
  static const String defaultBaseUrl = 'http://buer.kdns.fr';

  String baseUrl = defaultBaseUrl;

  String get wsUrl {
    if (baseUrl.startsWith('https://')) {
      return 'wss://${baseUrl.substring(8)}/ws';
    } else if (baseUrl.startsWith('http://')) {
      return 'ws://${baseUrl.substring(7)}/ws';
    }
    return 'ws://$baseUrl/ws';
  }

  String urlFor(String path) => '$baseUrl$path';

  String resourceUrlFor(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
