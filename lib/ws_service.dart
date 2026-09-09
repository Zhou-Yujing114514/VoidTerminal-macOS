import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config.dart';
import 'models.dart';

class WsService {
  final ServerConfig config;
  WebSocketChannel? _channel;
  String? _token;
  bool _isConnected = false;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _sub;

  bool get isConnected => _isConnected;

  // 回调
  void Function(HelloMessage)? onHello;
  void Function(ChatMessage)? onGlobalMessage;
  void Function(ChatMessage)? onDMMessage;
  void Function(ChatMessage)? onGroupMessage;
  void Function(String room, String id, String? to, String? gid)? onRecalled;
  void Function(String)? onError;
  void Function(String)? onBanned;
  void Function(String)? onKicked;
  void Function(String)? onSystem;
  void Function(List<String>)? onPresence;
  void Function(String)? onAnnouncementUpdate;
  void Function(FriendRequest)? onFriendRequest;
  void Function(List<User>)? onFriendUpdate;
  void Function(bool ok, String action, String fromName)? onRequestRespond;
  void Function(bool, String?)? onRequestSent;
  void Function(ChatGroup)? onGroupCreated;
  void Function(String, String)? onGroupRemoved;
  void Function(String, ChatGroup)? onGroupRenamed;
  void Function(String, ChatGroup, String)? onGroupMemberRemoved;
  void Function(String, String)? onGroupAvatarUpdated;
  void Function(List<Moment>)? onMomentsUpdate;
  void Function(int)? onMaxOnlineUpdate;
  void Function(String)? onHallRenamed;
  void Function()? onHallCleared;
  void Function(String)? onGroupApplySent;
  void Function(GroupRequest)? onGroupApplyRequest;
  void Function(String, ChatGroup?)? onGroupApplyAccepted;
  void Function(String)? onGroupApplyRejected;
  void Function()? onDisconnect;

  WsService(this.config);

  void connect(String token) {
    _manualDisconnect = false;
    _reconnectAttempts = 0;
    _token = token;
    _disconnect();
    final uri = Uri.parse(config.wsUrl);
    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _sub = _channel!.stream.listen(_onData, onDone: _onDone, onError: (_) => _onDone());
      Future.delayed(const Duration(milliseconds: 300), _sendAuth);
      _startHeartbeat();
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _disconnect();
    _token = null;
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void _sendAuth() {
    if (_token != null) {
      send({'type': 'auth', 'token': _token});
    }
  }

  void send(Map<String, dynamic> dict) {
    _channel?.sink.add(jsonEncode(dict));
  }

  // 便捷发送
  void sendGlobal(String content, {List<String> images = const []}) {
    final d = <String, dynamic>{'type': 'global', 'content': content};
    if (images.isNotEmpty) d['images'] = images;
    send(d);
  }

  void sendDM(String to, String content, {List<String> images = const []}) {
    final d = <String, dynamic>{'type': 'dm', 'to': to, 'content': content};
    if (images.isNotEmpty) d['images'] = images;
    send(d);
  }

  void sendGroup(String gid, String content, {List<String> images = const []}) {
    final d = <String, dynamic>{'type': 'group', 'gid': gid, 'content': content};
    if (images.isNotEmpty) d['images'] = images;
    send(d);
  }

  void sendGroupApply(String gid) => send({'type': 'group-apply', 'gid': gid});
  void sendGroupApplyRespond(String applyId, String action) =>
      send({'type': 'group-apply-respond', 'applyId': applyId, 'action': action});

  void recall(String room, String id, {String? to, String? gid}) {
    final d = <String, dynamic>{'type': 'recall', 'room': room, 'id': id};
    if (to != null) d['to'] = to;
    if (gid != null) d['gid'] = gid;
    send(d);
  }

  void createGroup(String name, List<String> members) =>
      send({'type': 'create-group', 'name': name, 'members': members});
  void sendFriendRequest(String username) =>
      send({'type': 'friend-request', 'username': username});
  void respondRequest(String requestId, String action) =>
      send({'type': 'request-respond', 'requestId': requestId, 'action': action});
  void unfriend(String userId) => send({'type': 'unfriend', 'userId': userId});
  void groupRename(String gid, String name) =>
      send({'type': 'group-rename', 'gid': gid, 'name': name});
  void groupRemoveMember(String gid, String userId) =>
      send({'type': 'group-remove-member', 'gid': gid, 'userId': userId});
  void groupLeave(String gid) => send({'type': 'group-leave', 'gid': gid});
  void groupAddMembers(String gid, List<String> members) =>
      send({'type': 'group-add-members', 'gid': gid, 'members': members});
  void groupDissolve(String gid) => send({'type': 'group-dissolve', 'gid': gid});
  void momentLike(String mid) => send({'type': 'moment-like', 'mid': mid});
  void momentComment(String mid, String text) =>
      send({'type': 'moment-comment', 'mid': mid, 'text': text});
  void momentDelete(String mid) => send({'type': 'moment-delete', 'mid': mid});
  void momentCommentDelete(String mid, String cid) =>
      send({'type': 'moment-comment-delete', 'mid': mid, 'cid': cid});
  void setMaxOnline(int value) => send({'type': 'set-max-online', 'value': value});
  void banUser(String username) => send({'type': 'ban-user', 'username': username});
  void unbanUser(String username) => send({'type': 'unban-user', 'username': username});
  void kickUser(String userId) => send({'type': 'kick-user', 'userId': userId});
  void announce(String content) => send({'type': 'announce', 'content': content});
  void renameHall(String name) => send({'type': 'rename-hall', 'name': name});
  void clearHall() => send({'type': 'clear-hall'});

  void _onData(dynamic data) {
    try {
      final dict = jsonDecode(data as String) as Map<String, dynamic>;
      _handle(dict);
    } catch (_) {}
  }

  void _handle(Map<String, dynamic> d) {
    final type = d['type'] as String?;
    switch (type) {
      case 'hello':
        onHello?.call(HelloMessage.fromJson(d));
        break;
      case 'global':
        onGlobalMessage?.call(ChatMessage.fromJson(d));
        break;
      case 'dm':
        onDMMessage?.call(ChatMessage.fromJson(d));
        break;
      case 'group':
        onGroupMessage?.call(ChatMessage.fromJson(d));
        break;
      case 'recalled':
        onRecalled?.call(
          d['room'] as String? ?? '',
          d['id'] as String? ?? '',
          d['to'] as String?,
          d['gid'] as String?,
        );
        break;
      case 'error':
        onError?.call(d['error'] as String? ?? '未知错误');
        break;
      case 'banned':
        onBanned?.call(d['error'] as String? ?? '账号已被封禁');
        break;
      case 'kicked':
        onKicked?.call(d['error'] as String? ?? '你已被移出服务器');
        break;
      case 'system':
        onSystem?.call(d['content'] as String? ?? '');
        break;
      case 'presence':
        final ids = (d['online'] as List?)?.map((e) {
          if (e is Map) return e['id'] as String? ?? '';
          return e.toString();
        }).where((e) => e.isNotEmpty).toList();
        onPresence?.call(ids ?? []);
        break;
      case 'announcement-update':
        onAnnouncementUpdate?.call(d['announcement'] as String? ?? '');
        break;
      case 'friend-request':
        if (d['request'] is Map) {
          onFriendRequest?.call(FriendRequest.fromJson(d['request'] as Map<String, dynamic>));
        }
        break;
      case 'friend-update':
        final list = (d['friends'] as List?)
                ?.map((e) => User.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        onFriendUpdate?.call(list);
        break;
      case 'request-respond':
        onRequestRespond?.call(
          d['ok'] as bool? ?? false,
          d['action'] as String? ?? '',
          d['fromName'] as String? ?? '',
        );
        break;
      case 'request-sent':
        onRequestSent?.call(d['ok'] as bool? ?? false, d['error'] as String?);
        break;
      case 'group-created':
        if (d['group'] is Map) {
          onGroupCreated?.call(ChatGroup.fromJson(d['group'] as Map<String, dynamic>));
        }
        break;
      case 'group-removed':
        onGroupRemoved?.call(d['gid'] as String? ?? '', d['error'] as String? ?? '');
        break;
      case 'group-renamed':
        if (d['group'] is Map) {
          onGroupRenamed?.call(d['gid'] as String? ?? '', ChatGroup.fromJson(d['group'] as Map<String, dynamic>));
        }
        break;
      case 'group-member-removed':
        if (d['group'] is Map) {
          onGroupMemberRemoved?.call(
            d['gid'] as String? ?? '',
            ChatGroup.fromJson(d['group'] as Map<String, dynamic>),
            d['userId'] as String? ?? '',
          );
        }
        break;
      case 'group-avatar-updated':
        onGroupAvatarUpdated?.call(d['gid'] as String? ?? '', d['avatar'] as String? ?? '');
        break;
      case 'moments':
        final list = (d['moments'] as List?)
                ?.map((e) => Moment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        onMomentsUpdate?.call(list);
        break;
      case 'max-online':
        onMaxOnlineUpdate?.call(d['maxOnline'] as int? ?? 0);
        break;
      case 'hall-renamed':
        onHallRenamed?.call(d['hallName'] as String? ?? '公共大厅');
        break;
      case 'hall-cleared':
        onHallCleared?.call();
        break;
      case 'group-apply-sent':
        onGroupApplySent?.call(d['gid'] as String? ?? '');
        break;
      case 'group-apply-request':
        if (d['apply'] is Map) {
          onGroupApplyRequest?.call(GroupRequest.fromJson(d['apply'] as Map<String, dynamic>));
        }
        break;
      case 'group-apply-accepted':
        ChatGroup? g;
        if (d['group'] is Map) g = ChatGroup.fromJson(d['group'] as Map<String, dynamic>);
        onGroupApplyAccepted?.call(d['gid'] as String? ?? '', g);
        break;
      case 'group-apply-rejected':
        onGroupApplyRejected?.call(d['gid'] as String? ?? '');
        break;
    }
  }

  void _onDone() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    onDisconnect?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _token == null) return;
    _reconnectAttempts++;
    final delay = (_reconnectAttempts * 2).clamp(1, 15);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_manualDisconnect && _token != null) connect(_token!);
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // 心跳间隔 15 秒，保持连接活跃，防止被中间设备断开
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _channel?.sink.add('ping');
    });
  }
}
