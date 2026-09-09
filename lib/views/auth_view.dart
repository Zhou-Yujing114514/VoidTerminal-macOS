import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isRegister = false;
  bool _isTotpLogin = false;
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _totpCode = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _password2.dispose();
    _totpCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final u = _username.text.trim();
    if (u.isEmpty) {
      setState(() => _error = '请输入用户名');
      return;
    }

    setState(() { _loading = true; _error = null; });

    String? err;
    if (_isTotpLogin) {
      final code = _totpCode.text.trim();
      if (code.isEmpty) {
        setState(() { _loading = false; _error = '请输入验证码'; });
        return;
      }
      err = await app.loginTotp(u, code);
    } else if (_isRegister) {
      final p = _password.text;
      final p2 = _password2.text;
      if (p.isEmpty || p2.isEmpty) {
        setState(() { _loading = false; _error = '请输入密码'; });
        return;
      }
      if (p != p2) {
        setState(() { _loading = false; _error = '两次密码不一致'; });
        return;
      }
      err = await app.register(u, p, p2);
    } else {
      final p = _password.text;
      if (p.isEmpty) {
        setState(() { _loading = false; _error = '请输入密码'; });
        return;
      }
      err = await app.login(u, p);
    }

    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
  }

  void _switchMode(bool totp) {
    setState(() {
      _isTotpLogin = totp;
      _isRegister = false;
      _error = null;
      _totpCode.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.vtBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '虚空终端',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: text),
              ),
              const SizedBox(height: 8),
              Text(
                '聊天与反馈，账号密码不同步于番茄站',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 28),
              // 登录方式切换
              if (!_isRegister)
                Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        label: '密码登录',
                        selected: !_isTotpLogin,
                        onTap: () => _switchMode(false),
                        textColor: text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _modeButton(
                        label: '验证码登录',
                        selected: _isTotpLogin,
                        onTap: () => _switchMode(true),
                        textColor: text,
                      ),
                    ),
                  ],
                ),
              if (!_isRegister) const SizedBox(height: 14),
              TextField(
                controller: _username,
                style: TextStyle(color: text),
                decoration: InputDecoration(
                  labelText: '用户名',
                  hintText: '用户名',
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              if (!_isTotpLogin) ...[
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: '密码',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password2,
                    obscureText: true,
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      filled: true,
                      fillColor: bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ] else ...[
                TextField(
                  controller: _totpCode,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: text, letterSpacing: 4, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: '认证器验证码',
                    hintText: '6 位数字',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                Text(
                  '使用已绑定的认证器 App（Google Authenticator / Microsoft Authenticator 等）生成的 6 位验证码登录',
                  style: TextStyle(fontSize: 11, color: muted, height: 1.4),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.vtRed, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vtAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isRegister ? '注册' : (_isTotpLogin ? '验证码登录' : '登录'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _isTotpLogin = false;
                  _error = null;
                  _totpCode.clear();
                }),
                child: Text(
                  _isRegister ? '已有账号？去登录' : '没有账号？去注册',
                  style: const TextStyle(color: AppColors.vtAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.vtAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.vtAccent : AppColors.vtBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppColors.vtAccent : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
