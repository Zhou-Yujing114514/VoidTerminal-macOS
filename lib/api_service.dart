import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';

class ApiService {
  final ServerConfig config;

  ApiService(this.config);

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse(config.urlFor(path)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      throw ApiException(data['error'] as String? ?? 'HTTP ${resp.statusCode}');
    }
    return data;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(Uri.parse(config.urlFor(path)));
    if (resp.statusCode >= 400) {
      throw ApiException('HTTP ${resp.statusCode}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  // MARK: - Auth
  Future<Map<String, dynamic>> register(String username, String password, String password2) async {
    return _post('/api/register', {'username': username, 'password': password, 'password2': password2});
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    return _post('/api/login', {'username': username, 'password': password});
  }

  /// TOTP 验证码登录（无需密码）
  Future<Map<String, dynamic>> loginTotp(String username, String code) async {
    return _post('/api/login-totp', {'username': username, 'code': code});
  }

  Future<User> me(String token) async {
    final data = await _post('/api/me', {'token': token});
    return User.fromJson(data['user']);
  }

  Future<void> logout(String token) async {
    await _post('/api/logout', {'token': token});
  }

  // MARK: - 两步验证 (2FA / TOTP)
  Future<TotpEnableResponse> enable2FA(String token) async {
    final data = await _post('/api/2fa/enable', {'token': token});
    return TotpEnableResponse.fromJson(data);
  }

  Future<void> confirm2FA(String token, String code) async {
    await _post('/api/2fa/confirm', {'token': token, 'code': code});
  }

  Future<void> disable2FA(String token, String code) async {
    await _post('/api/2fa/disable', {'token': token, 'code': code});
  }

  // MARK: - Avatar
  Future<String> uploadAvatar(String token, List<int> imageData) async {
    final b64 = base64Encode(imageData);
    final data = await _post('/api/avatar', {'token': token, 'data': b64});
    return data['avatar'] as String? ?? '';
  }

  Future<String> uploadGroupAvatar(String token, String gid, List<int> imageData) async {
    final b64 = base64Encode(imageData);
    final data = await _post('/api/group-avatar', {'token': token, 'gid': gid, 'data': b64});
    return data['avatar'] as String? ?? '';
  }

  Future<String> uploadMessageImage(String token, List<int> imageData) async {
    final b64 = base64Encode(imageData);
    final data = await _post('/api/upload-msg-image', {'token': token, 'data': b64});
    return data['url'] as String? ?? '';
  }

  // MARK: - Moment
  Future<Moment> postMoment(String token, String text, List<List<int>> images) async {
    final b64images = images.map((e) => base64Encode(e)).toList();
    final data = await _post('/api/moment-post', {'token': token, 'text': text, 'images': b64images});
    return Moment.fromJson(data['moment']);
  }

  // MARK: - Account
  Future<void> changePassword(String token, String old, String newP, String confirm) async {
    await _post('/api/change-password',
        {'token': token, 'oldPassword': old, 'newPassword': newP, 'newPassword2': confirm});
  }

  Future<User> changeUsername(String token, String newName) async {
    final data = await _post('/api/change-username', {'token': token, 'newUsername': newName});
    return User.fromJson(data['user']);
  }

  // MARK: - 搜索群
  Future<List<SearchGroup>> searchGroups(String keyword) async {
    final encoded = Uri.encodeComponent(keyword);
    final resp = await http.get(Uri.parse(config.urlFor('/api/search-groups?keyword=$encoded')));
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (data['ok'] == false) throw ApiException(data['error'] as String? ?? '搜索失败');
    return (data['groups'] as List?)
            ?.map((e) => SearchGroup.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
