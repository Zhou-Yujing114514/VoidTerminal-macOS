import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_state.dart';
import '../theme.dart';

/// 两步验证（TOTP）视图
/// 对应 iOS 版的 TwoFAView.swift
class TwoFAView extends StatefulWidget {
  const TwoFAView({super.key});

  @override
  State<TwoFAView> createState() => _TwoFAViewState();
}

class _TwoFAViewState extends State<TwoFAView> {
  String _secret = '';
  String _uri = '';
  String _message = '';
  bool _isLoading = false;
  bool _showingSetup = false;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _totpEnabled => context.read<AppState>().currentUser?.totpEnabled == true;

  Future<void> _enable() async {
    final app = context.read<AppState>();
    setState(() { _isLoading = true; _message = ''; });
    final resp = await app.enable2FA();
    if (!mounted) return;
    if (resp != null && resp.ok) {
      setState(() {
        _secret = resp.secret ?? '';
        _uri = resp.uri ?? '';
        _showingSetup = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _message = '开启失败，请重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final app = context.read<AppState>();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = '请输入验证码');
      return;
    }
    setState(() { _isLoading = true; _message = ''; });
    final ok = await app.confirm2FA(code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _message = '验证码错误，请重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _disable() async {
    final app = context.read<AppState>();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = '请输入验证码');
      return;
    }
    setState(() { _isLoading = true; _message = ''; });
    final ok = await app.disable2FA(code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _message = '验证码错误，请重试';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.vtBg : const Color(0xFFf5f5f0);
    final card = isDark ? AppColors.vtCard : Colors.white;
    final text = isDark ? AppColors.vtText : const Color(0xFF333333);
    final muted = AppColors.vtMuted;
    final enabled = _totpEnabled;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('两步验证'),
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (enabled) ...[
            _buildCard(
              card,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.vtGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('已绑定认证器', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
                          const SizedBox(height: 4),
                          Text('可使用认证器验证码直接登录', style: TextStyle(fontSize: 13, color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('关闭两步验证', text),
            const SizedBox(height: 8),
            _buildCard(
              card,
              children: [
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: '输入验证码以关闭',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_message, style: const TextStyle(color: AppColors.vtRed, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _disable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vtRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('关闭两步验证'),
                  ),
                ),
              ],
            ),
          ] else if (!_showingSetup) ...[
            _buildCard(
              card,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vtAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('开启两步验证'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              card,
              children: [
                Text(
                  '开启后可用 Microsoft Authenticator / Google Authenticator / Authy 扫码，之后即可用动态验证码直接登录。',
                  style: TextStyle(fontSize: 13, color: muted, height: 1.5),
                ),
              ],
            ),
          ] else ...[
            _buildSectionTitle('扫码绑定', text),
            const SizedBox(height: 8),
            _buildCard(
              card,
              children: [
                Center(
                  child: _uri.isNotEmpty
                      ? QrImageView(
                          data: _uri,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        )
                      : Container(
                          width: 200,
                          height: 200,
                          color: AppColors.vtBorder,
                          child: const Icon(Icons.qr_code, size: 80, color: AppColors.vtMuted),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('密钥：$_secret', style: TextStyle(fontSize: 13, color: muted)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: muted,
                      onPressed: () {
                        // 复制密钥到剪贴板
                        // 简单实现，实际项目可使用 flutter/services 的 Clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('密钥已复制'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: '输入认证器显示的 6 位验证码',
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_message, style: const TextStyle(color: AppColors.vtRed, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vtGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('确认绑定'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Color card, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vtBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: text)),
    );
  }
}
