/// 数据模型（对应 VoidTerminal-iOS 的 Models.swift）

class User {
  final String id;
  final String username;
  String? avatar;
  String? role;
  bool? banned;
  int? createdAt;
  bool? totpEnabled;

  User({
    required this.id,
    required this.username,
    this.avatar,
    this.role,
    this.banned,
    this.createdAt,
    this.totpEnabled,
  });

  bool get isAdmin => role == 'admin';
  bool get isBot => role == 'bot';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        avatar: json['avatar'] as String?,
        role: json['role'] as String?,
        banned: json['banned'] as bool?,
        createdAt: json['createdAt'] as int? ?? json['created_at'] as int?,
        totpEnabled: json['totpEnabled'] as bool?,
      );
}

class ChatMessage {
  final String id;
  final String from;
  String? fromName;
  String? fromAvatar;
  String? fromRole;
  bool? fromBot;
  final String content;
  List<String>? images;
  final int time;
  String? to;
  String? gid;
  bool isFromMe = false;

  ChatMessage({
    required this.id,
    required this.from,
    this.fromName,
    this.fromAvatar,
    this.fromRole,
    this.fromBot,
    required this.content,
    this.images,
    required this.time,
    this.to,
    this.gid,
    this.isFromMe = false,
  });

  bool get isImageOnly => content.isEmpty && (images?.isNotEmpty ?? false);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final from = json['from'] as String? ?? '';
    final content = json['content'] as String? ?? '';
    final time = json['time'] as int? ?? 0;
    final id = (json['id'] as String?) ??
        '${from}_${content}_$time';
    return ChatMessage(
      id: id,
      from: from,
      fromName: json['fromName'] as String?,
      fromAvatar: json['fromAvatar'] as String?,
      fromRole: json['fromRole'] as String?,
      fromBot: json['fromBot'] as bool?,
      content: content,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
      time: time,
      to: json['to'] as String?,
      gid: json['gid'] as String?,
    );
  }
}

class ChatGroup {
  final String id;
  String name;
  final String owner;
  List<String> members;
  List<String>? memberNames;
  List<String>? memberAvatars;
  String? avatar;
  int? createdAt;
  bool isOwner = false;

  ChatGroup({
    required this.id,
    required this.name,
    required this.owner,
    required this.members,
    this.memberNames,
    this.memberAvatars,
    this.avatar,
    this.createdAt,
    this.isOwner = false,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        members: (json['members'] as List?)?.map((e) => e.toString()).toList() ?? [],
        memberNames: (json['memberNames'] as List?)?.map((e) => e.toString()).toList(),
        memberAvatars: (json['memberAvatars'] as List?)?.map((e) => e.toString()).toList(),
        avatar: json['avatar'] as String?,
        createdAt: json['createdAt'] as int?,
      );
}

class FriendRequest {
  final String id;
  final String from;
  final String fromName;
  String? fromAvatar;
  final int time;

  FriendRequest({
    required this.id,
    required this.from,
    required this.fromName,
    this.fromAvatar,
    required this.time,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String? ?? '',
        from: json['from'] as String? ?? '',
        fromName: json['fromName'] as String? ?? '未知',
        fromAvatar: json['fromAvatar'] as String?,
        time: json['time'] as int? ?? 0,
      );
}

class MomentComment {
  final String user;
  String? userName;
  final String text;
  final int time;

  MomentComment({
    required this.user,
    this.userName,
    required this.text,
    required this.time,
  });

  factory MomentComment.fromJson(Map<String, dynamic> json) => MomentComment(
        user: json['author'] as String? ?? '',
        userName: json['authorName'] as String?,
        text: json['text'] as String? ?? '',
        time: json['time'] as int? ?? 0,
      );
}

class Moment {
  final String id;
  final String author;
  String? authorName;
  String? authorAvatar;
  final String text;
  List<String> images;
  final int time;
  List<String> likes;
  List<MomentComment> comments;
  bool isLiked = false;

  Moment({
    required this.id,
    required this.author,
    this.authorName,
    this.authorAvatar,
    required this.text,
    required this.images,
    required this.time,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });

  factory Moment.fromJson(Map<String, dynamic> json) => Moment(
        id: json['id'] as String? ?? '',
        author: json['author'] as String? ?? '',
        authorName: json['authorName'] as String?,
        authorAvatar: json['authorAvatar'] as String?,
        text: json['text'] as String? ?? '',
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        time: json['time'] as int? ?? 0,
        likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
        comments: (json['comments'] as List?)
                ?.map((e) => MomentComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class HelloMessage {
  final User? selfUser;
  final int? maxOnline;
  final bool? isAdmin;
  final String? hallName;
  final String? announcement;
  final List<ChatMessage>? globalMsgs;
  final List<ChatGroup>? groups;
  final List<User>? friends;
  final List<FriendRequest>? pendingRequests;
  final List<GroupRequest>? groupApplyRequests;
  final Map<String, List<ChatMessage>>? dmRooms;
  final Map<String, List<ChatMessage>>? groupMsgs;
  final List<Moment>? moments;

  HelloMessage({
    this.selfUser,
    this.maxOnline,
    this.isAdmin,
    this.hallName,
    this.announcement,
    this.globalMsgs,
    this.groups,
    this.friends,
    this.pendingRequests,
    this.groupApplyRequests,
    this.dmRooms,
    this.groupMsgs,
    this.moments,
  });

  factory HelloMessage.fromJson(Map<String, dynamic> json) => HelloMessage(
        selfUser: json['self'] != null ? User.fromJson(json['self']) : null,
        maxOnline: json['maxOnline'] as int?,
        isAdmin: json['isAdmin'] as bool?,
        hallName: json['hallName'] as String?,
        announcement: json['announcement'] as String?,
        globalMsgs: (json['globalMsgs'] as List?)
            ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        groups: (json['groups'] as List?)
            ?.map((e) => ChatGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        friends: (json['friends'] as List?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingRequests: (json['pendingRequests'] as List?)
            ?.map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        groupApplyRequests: (json['groupApplyRequests'] as List?)
            ?.map((e) => GroupRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
        dmRooms: (json['dmRooms'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(
            k,
            (v as List)
                .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList())),
        groupMsgs: (json['groupMsgs'] as Map<String, dynamic>?)?.map((k, v) =>
            MapEntry(
                k,
                (v as List)
                    .map((e) =>
                        ChatMessage.fromJson(e as Map<String, dynamic>))
                    .toList())),
        moments: (json['moments'] as List?)
            ?.map((e) => Moment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SearchGroup {
  final String id;
  final String name;
  final String? owner;
  final String? ownerName;
  final int? memberCount;
  final String? avatar;

  SearchGroup({
    required this.id,
    required this.name,
    this.owner,
    this.ownerName,
    this.memberCount,
    this.avatar,
  });

  factory SearchGroup.fromJson(Map<String, dynamic> json) => SearchGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        owner: json['owner'] as String?,
        ownerName: json['ownerName'] as String?,
        memberCount: json['memberCount'] as int?,
        avatar: json['avatar'] as String?,
      );
}

class GroupRequest {
  final String id;
  final String gid;
  final String? groupName;
  final String from;
  final String? fromName;
  final String? fromAvatar;
  final int time;
  final String? status;

  GroupRequest({
    required this.id,
    required this.gid,
    this.groupName,
    required this.from,
    this.fromName,
    this.fromAvatar,
    required this.time,
    this.status,
  });

  factory GroupRequest.fromJson(Map<String, dynamic> json) => GroupRequest(
        id: json['id'] as String? ?? '',
        gid: json['gid'] as String? ?? '',
        groupName: json['groupName'] as String?,
        from: json['from'] as String? ?? '',
        fromName: json['fromName'] as String?,
        fromAvatar: json['fromAvatar'] as String?,
        time: json['time'] as int? ?? 0,
        status: json['status'] as String?,
      );
}

/// TOTP 两步验证启用响应
class TotpEnableResponse {
  final bool ok;
  final String? secret;
  final String? uri;

  TotpEnableResponse({required this.ok, this.secret, this.uri});

  factory TotpEnableResponse.fromJson(Map<String, dynamic> json) => TotpEnableResponse(
        ok: json['ok'] as bool? ?? false,
        secret: json['secret'] as String?,
        uri: json['uri'] as String?,
      );
}
