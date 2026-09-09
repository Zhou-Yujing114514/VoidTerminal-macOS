# 虚空终端 macOS 版

虚空终端（VoidTerminal）macOS 桌面客户端，基于 Flutter 开发，连接 buer.kdns.fr。

## 功能

- 🔐 登录/注册（密码 + TOTP 两步验证登录）
- 💬 公共大厅聊天
- 👤 好友私聊
- 👥 群聊（创建/解散/重命名/成员管理）
- 📇 好友列表/通讯录（添加好友/处理申请）
- 🌈 朋友圈/动态（发布/点赞/评论/删除）
- 🔍 搜索群聊/申请加群
- ↩️ 消息撤回
- 🖼️ 图片发送
- 🌙 日间/夜间模式
- 🔒 两步验证 (TOTP) 管理
- ⚙️ 管理员功能（公告/封禁/清空大厅等）

## 技术栈

- **框架**: Flutter 3.24+ / Dart 3.5+
- **状态管理**: Provider
- **网络**: HTTP (REST API) + WebSocket (实时消息)
- **平台**: macOS 10.14+ (Universal: arm64 + x86_64)

## 服务器

- API: `http://buer.kdns.fr/api/*`
- WebSocket: `ws://buer.kdns.fr/ws`

## 本地开发

```bash
# 安装依赖
flutter pub get

# 运行（需 macOS 环境）
flutter run -d macos

# 构建 Release
flutter build macos --release
```

## 下载

从 [Releases](https://github.com/Zhou-Yujing114514/VoidTerminal-macOS/releases) 页面下载：
- `VoidTerminal-macOS-arm64.zip` — Apple Silicon (M1/M2/M3/M4)
- `VoidTerminal-macOS-x86_64.zip` — Intel Mac

## 其他平台

- [Windows 版](https://github.com/Zhou-Yujing114514/VoidTerminal-Windows)
- [iOS 版](https://github.com/Zhou-Yujing114514/VoidTerminal-iOS)
