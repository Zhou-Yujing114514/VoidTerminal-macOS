import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_service.dart';
import 'ws_service.dart';
import 'models.dart';

/// 当前房间
class Room {
  final String type; // global / dm / group
  final String id; // peerId 或 gid
  final String name;
  Room(this.type, this.id, this.name);
}

class AppState extends ChangeNotifier {
  final ServerConfig config = ServerConfig();
  late final ApiService api = ApiService(config);
  late final WsService ws = WsService(config);

  String? token;
  User? currentUser;
  bool isAdmin = false;
  String hallName = '公共大厅';
  int maxOnline = 0;
  String announcement = '';
  String? toast;

  List<ChatMessage> globalMessages = [];
  Map<String, List<ChatMessage>> dmMessages = {};
  Map<String, List<ChatMessage>> groupMessages = {};
  List<ChatGroup> groups = [];
  List<User> friends = [];
  List<FriendRequest> pendingRequests = [];
  List<Moment> moments = [];
  Set<String> onlineUsers = {};
  List<SearchGroup> searchResults = [];
  List<GroupRequest> groupRequests = [];
  bool isSearching = false;

  Room? currentRoom;
  int currentTab = 0;
  String currentUserId = '';
  String currentUserName = '我';

  /// 与服务器 WebSocket 是否处于已连接（收到 hello）状态
  bool serverConnected = false;
  bool _hadConnected = false;
  DateTime? _lastSentAt;

  AppState() {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    ws.onHello = (msg) => _handleHello(msg);
    ws.onGlobalMessage = (m) {
      var msg = m;
      msg.isFromMe = msg.from == currentUserId;
      if (msg.from == currentUserId) {
        globalMessages.removeWhere((e) => e.id.startsWith('temp_'));
      }
      if (!globalMessages.any((e) => e.id == msg.id)) globalMessages.add(msg);
      if (globalMessages.length > 500) {
        globalMessages = globalMessages.sublist(globalMessages.length - 500);
      }
      notifyListeners();
    };
    ws.onDMMessage = (m) {
      var msg = m;
      msg.isFromMe = msg.from == currentUserId;
      final peer = msg.from == currentUserId ? (msg.to ?? '') : msg.from;
      final key = dmRoomKey(currentUserId, peer);
      dmMessages.putIfAbsent(key, () => []);
      if (msg.from == currentUserId) {
        dmMessages[key]!.removeWhere((e) => e.id.startsWith('temp_'));
      }
      if (!dmMessages[key]!.any((e) => e.id == msg.id)) dmMessages[key]!.add(msg);
      notifyListeners();
    };
    ws.onGroupMessage = (m) {
      var msg = m;
      msg.isFromMe = msg.from == currentUserId;
      final gid = msg.gid ?? '';
      groupMessages.putIfAbsent(gid, () => []);
      if (msg.from == currentUserId) {
        groupMessages[gid]!.removeWhere((e) => e.id.startsWith('temp_'));
      }
      if (!groupMessages[gid]!.any((e) => e.id == msg.id)) groupMessages[gid]!.add(msg);
      notifyListeners();
    };
    ws.onRecalled = (room, id, to, gid) {
      switch (room) {
        case 'global':
          globalMessages.removeWhere((e) => e.id == id);
          break;
        case 'dm':
          final key = dmRoomKey(currentUserId, to ?? '');
          dmMessages[key]?.removeWhere((e) => e.id == id);
          break;
        case 'group':
          groupMessages[gid ?? '']?.removeWhere((e) => e.id == id);
          break;
      }
      notifyListeners();
    };
    ws.onError = showToast;
    ws.onBanned = (err) { showToast(err); token = null; currentUser = null; notifyListeners(); };
    ws.onKicked = (err) { showToast(err); token = null; currentUser = null; notifyListeners(); };
    ws.onSystem = showToast;
    ws.onDisconnect = () {
      serverConnected = false;
      notifyListeners();
      // 非手动登出时提示后台重连（登出时 token 已清空，ws 内部不会再触发重连）
      if (token != null) {
        showToast('连接断开，正在后台自动重连…');
      }
    };
    ws.onPresence = (ids) { onlineUsers = ids.toSet(); notifyListeners(); };
    ws.onAnnouncementUpdate = (ann) { if (ann.isNotEmpty) announcement = ann; notifyListeners(); };
    ws.onFriendRequest = (req) {
      if (!pendingRequests.any((e) => e.id == req.id)) { pendingRequests.add(req); notifyListeners(); }
    };
    ws.onFriendUpdate = (list) { friends = list; notifyListeners(); };
    ws.onRequestRespond = (ok, action, fromName) {
      showToast(ok ? '好友请求已${action == 'accept' ? '接受' : '拒绝'}（来自 $fromName）' : '操作失败');
    };
    ws.onRequestSent = (ok, error) => showToast(ok ? '验证请求已发送' : (error ?? '发送失败'));
    ws.onGroupCreated = (g) { g.isOwner = true; groups.add(g); showToast('群聊「${g.name}」已创建'); notifyListeners(); };
    ws.onGroupRemoved = (gid, error) { groups.removeWhere((e) => e.id == gid); groupMessages.remove(gid); showToast(error); notifyListeners(); };
    ws.onGroupRenamed = (gid, g) {
      final idx = groups.indexWhere((e) => e.id == gid);
      if (idx >= 0) { groups[idx].name = g.name; notifyListeners(); }
    };
    ws.onGroupMemberRemoved = (gid, g, userId) {
      final idx = groups.indexWhere((e) => e.id == gid);
      if (idx >= 0) { groups[idx].members = g.members; notifyListeners(); }
    };
    ws.onGroupAvatarUpdated = (gid, avatar) {
      final idx = groups.indexWhere((e) => e.id == gid);
      if (idx >= 0) { groups[idx].avatar = avatar; notifyListeners(); }
    };
    ws.onMomentsUpdate = (list) { moments = list; notifyListeners(); };
    ws.onHallRenamed = (name) { hallName = name; notifyListeners(); };
    ws.onHallCleared = () { globalMessages.clear(); notifyListeners(); };
    ws.onGroupApplySent = (_) => showToast('申请已发送，请等待群主审批');
    ws.onGroupApplyRequest = (req) {
      if (!groupRequests.any((e) => e.id == req.id)) { groupRequests.add(req); showToast('收到新的入群申请'); notifyListeners(); }
    };
    ws.onGroupApplyAccepted = (gid, g) {
      if (g != null) groups.add(g);
      showToast('你已成功加入群聊');
      notifyListeners();
    };
    ws.onGroupApplyRejected = (_) => showToast('你的入群申请被拒绝了');
    ws.onMaxOnlineUpdate = (m) { maxOnline = m; notifyListeners(); };
  }

  void _handleHello(HelloMessage msg) {
    // 连接真正建立
    final wasOffline = serverConnected == false && _hadConnected;
    serverConnected = true;
    _hadConnected = true;
    if (wasOffline) showToast('已重新连接');
    if (msg.selfUser != null) {
      currentUserName = msg.selfUser!.username;
      currentUserId = msg.selfUser!.id;
    }
    globalMessages = (msg.globalMsgs ?? []).map((m) { m.isFromMe = m.from == currentUserId; return m; }).toList();
    groups = (msg.groups ?? []).map((g) { g.isOwner = g.owner == currentUserId; return g; }).toList();
    friends = msg.friends ?? [];
    pendingRequests = msg.pendingRequests ?? [];
    groupRequests = msg.groupApplyRequests ?? [];
    if (msg.groupMsgs != null) {
      groupMessages = msg.groupMsgs!.map((k, v) => MapEntry(k, v.map((m) { m.isFromMe = m.from == currentUserId; return m; }).toList()));
    }
    moments = msg.moments ?? [];
    if (msg.announcement != null && msg.announcement!.isNotEmpty) announcement = msg.announcement!;
    if (msg.hallName != null) hallName = msg.hallName!;
    if (msg.maxOnline != null) maxOnline = msg.maxOnline!;
    if (msg.isAdmin != null) isAdmin = msg.isAdmin!;
    if (msg.dmRooms != null) {
      dmMessages = msg.dmRooms!.map((k, v) => MapEntry(k, v.map((m) { m.isFromMe = m.from == currentUserId; return m; }).toList()));
    }
    notifyListeners();
  }

  String dmRoomKey(String a, String b) => a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  List<ChatMessage> messagesFor(Room room) {
    switch (room.type) {
      case 'global':
        return globalMessages;
      case 'dm':
        return dmMessages[dmRoomKey(currentUserId, room.id)] ?? [];
      case 'group':
        return groupMessages[room.id] ?? [];
      default:
        return [];
    }
  }

  void sendMessage(String text, {List<String> images = const []}) {
    final room = currentRoom;
    if (room == null || (text.isEmpty && images.isEmpty)) return;
    // 发送防抖：600ms 内的重复触发直接忽略，避免连点发送按钮造成重复消息
    final stamp = DateTime.now();
    if (_lastSentAt != null && stamp.difference(_lastSentAt!).inMilliseconds < 600) return;
    _lastSentAt = stamp;
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final tempMsg = ChatMessage(
      id: tempId, from: currentUserId, fromName: currentUserName,
      content: text, images: images.isEmpty ? null : images, time: now,
      to: room.type == 'dm' ? room.id : null,
      gid: room.type == 'group' ? room.id : null,
      isFromMe: true,
    );
    switch (room.type) {
      case 'global':
        globalMessages.add(tempMsg);
        ws.sendGlobal(text, images: images);
        break;
      case 'dm':
        dmMessages.putIfAbsent(dmRoomKey(currentUserId, room.id), () => []).add(tempMsg);
        ws.sendDM(room.id, text, images: images);
        break;
      case 'group':
        groupMessages.putIfAbsent(room.id, () => []).add(tempMsg);
        ws.sendGroup(room.id, text, images: images);
        break;
    }
    notifyListeners();
  }

  void recallMessage(ChatMessage msg) {
    final room = currentRoom;
    if (room == null) return;
    switch (room.type) {
      case 'global': ws.recall('global', msg.id); break;
      case 'dm': ws.recall('dm', msg.id, to: room.id); break;
      case 'group': ws.recall('group', msg.id, gid: room.id); break;
    }
  }

  // MARK: - 登录/注册/登出
  Future<String?> login(String username, String password) async {
    try {
      final data = await api.login(username, password);
      token = data['token'] as String?;
      currentUser = User.fromJson(data['user']);
      isAdmin = currentUser?.isAdmin ?? false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '登录失败: $e';
    }
  }

  /// TOTP 验证码登录
  Future<String?> loginTotp(String username, String code) async {
    try {
      final data = await api.loginTotp(username, code);
      token = data['token'] as String?;
      currentUser = User.fromJson(data['user']);
      isAdmin = currentUser?.isAdmin ?? false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '登录失败: $e';
    }
  }

  Future<String?> register(String username, String password, String password2) async {
    try {
      final data = await api.register(username, password, password2);
      token = data['token'] as String?;
      currentUser = User.fromJson(data['user']);
      isAdmin = currentUser?.isAdmin ?? false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '注册失败: $e';
    }
  }

  Future<void> logout() async {
    final t = token;
    ws.disconnect();
    if (t != null) { try { await api.logout(t); } catch (_) {} }
    token = null;
    currentUser = null;
    isAdmin = false;
    serverConnected = false;
    globalMessages.clear();
    dmMessages.clear();
    groupMessages.clear();
    groups.clear();
    friends.clear();
    moments.clear();
    groupRequests.clear();
    currentRoom = null;
    notifyListeners();
  }

  // MARK: - 两步验证 (2FA / TOTP)
  Future<TotpEnableResponse?> enable2FA() async {
    final t = token;
    if (t == null) return null;
    try {
      return await api.enable2FA(t);
    } catch (e) {
      showToast('开启失败: $e');
      return null;
    }
  }

  Future<bool> confirm2FA(String code) async {
    final t = token;
    if (t == null) return false;
    try {
      await api.confirm2FA(t, code);
      if (currentUser != null) {
        currentUser = User(
          id: currentUser!.id,
          username: currentUser!.username,
          avatar: currentUser!.avatar,
          role: currentUser!.role,
          banned: currentUser!.banned,
          createdAt: currentUser!.createdAt,
          totpEnabled: true,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      showToast('确认失败: $e');
      return false;
    }
  }

  Future<bool> disable2FA(String code) async {
    final t = token;
    if (t == null) return false;
    try {
      await api.disable2FA(t, code);
      if (currentUser != null) {
        currentUser = User(
          id: currentUser!.id,
          username: currentUser!.username,
          avatar: currentUser!.avatar,
          role: currentUser!.role,
          banned: currentUser!.banned,
          createdAt: currentUser!.createdAt,
          totpEnabled: false,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      showToast('关闭失败: $e');
      return false;
    }
  }

  // MARK: - 搜索群
  Future<void> searchGroups(String keyword) async {
    if (keyword.isEmpty) { searchResults = []; notifyListeners(); return; }
    isSearching = true;
    notifyListeners();
    try {
      searchResults = await api.searchGroups(keyword);
    } catch (e) {
      showToast('搜索失败: $e');
    }
    isSearching = false;
    notifyListeners();
  }

  void applyToGroup(String gid) {
    if (!ws.isConnected) { showToast('连接未就绪，请稍后重试'); return; }
    ws.sendGroupApply(gid);
  }

  void respondToGroupRequest(String applyId, String action) {
    ws.sendGroupApplyRespond(applyId, action);
    groupRequests.removeWhere((e) => e.id == applyId);
    notifyListeners();
  }

  // MARK: - 好友
  void sendFriendRequest(String username) => ws.sendFriendRequest(username);
  void respondRequest(String requestId, String action) {
    ws.respondRequest(requestId, action);
    pendingRequests.removeWhere((e) => e.id == requestId);
    notifyListeners();
  }
  void unfriend(String userId) => ws.unfriend(userId);

  // MARK: - 群
  void createGroup(String name, List<String> members) => ws.createGroup(name, members);
  void groupRename(String gid, String name) => ws.groupRename(gid, name);
  void groupRemoveMember(String gid, String userId) => ws.groupRemoveMember(gid, userId);
  void groupLeave(String gid) => ws.groupLeave(gid);
  void groupAddMembers(String gid, List<String> members) => ws.groupAddMembers(gid, members);
  void groupDissolve(String gid) => ws.groupDissolve(gid);

  // MARK: - 朋友圈
  void momentLike(String mid) => ws.momentLike(mid);
  void momentComment(String mid, String text) => ws.momentComment(mid, text);
  void momentDelete(String mid) => ws.momentDelete(mid);
  void momentCommentDelete(String mid, String cid) => ws.momentCommentDelete(mid, cid);

  // MARK: - 管理员
  void setMaxOnline(int v) => ws.setMaxOnline(v);
  void banUser(String username) => ws.banUser(username);
  void unbanUser(String username) => ws.unbanUser(username);
  void kickUser(String userId) => ws.kickUser(userId);
  void announce(String content) => ws.announce(content);
  void renameHall(String name) => ws.renameHall(name);
  void clearHall() => ws.clearHall();

  User? userById(String id) {
    for (final u in friends) { if (u.id == id) return u; }
    if (currentUser?.id == id) return currentUser;
    return null;
  }

  bool isOnline(String id) => onlineUsers.contains(id);

  void openRoom(Room room) {
    currentRoom = room;
    currentTab = 0; // 切到消息页显示聊天窗口
    notifyListeners();
  }

  void showToast(String text) {
    toast = text;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      if (toast == text) { toast = null; notifyListeners(); }
    });
  }

  /// 供外部 UI 触发状态刷新
  void refresh() => notifyListeners();
}
