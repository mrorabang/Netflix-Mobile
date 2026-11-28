import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:netflix_clone/core/watch_party/watch_party_config.dart';
import 'package:netflix_clone/domain/watch_party/models/watch_party_models.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Singleton Socket.IO & REST client for Watch Party.
class WatchPartyService {
  WatchPartyService._internal();
  static final WatchPartyService instance = WatchPartyService._internal();

  io.Socket? _socket;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 5000,
    ),
  );

  String? _userId;
  String? _username;
  String? _activeRoomId;
  Timer? _pingTimer;

  int _rttMs = 60;
  int _clockOffsetMs = 0;
  bool _isConnected = false;

  int get rttMs => _rttMs;
  int get clockOffsetMs => _clockOffsetMs;
  int get serverNowMs =>
      DateTime.now().millisecondsSinceEpoch + _clockOffsetMs;
  bool get isConnected => _isConnected;
  String? get activeRoomId => _activeRoomId;

  // Stream controllers for Watch Party events
  final _connectionController = StreamController<bool>.broadcast();
  final _lobbyRoomsController =
      StreamController<List<WatchPartyRoom>>.broadcast();
  final _roomStateController = StreamController<WatchPartyRoom>.broadcast();
  final _syncPlayerController = StreamController<SyncPlayerEvent>.broadcast();
  final _movieChangedController =
      StreamController<MovieChangedEvent>.broadcast();
  final _moderationAppliedController =
      StreamController<ModerationAppliedEvent>.broadcast();
  final _userVoiceStateController =
      StreamController<UserVoiceStateEvent>.broadcast();
  final _newMessageController =
      StreamController<WatchPartyMessage>.broadcast();
  final _roomErrorController = StreamController<RoomErrorEvent>.broadcast();
  final _roomCreatedController = StreamController<WatchPartyRoom>.broadcast();
  final _hostMigratedController =
      StreamController<HostMigratedEvent>.broadcast();
  final _userJoinedController =
      StreamController<WatchPartyMember>.broadcast();
  final _userLeftController = StreamController<String>.broadcast();
  final _voiceSignalController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _voicePeerDisconnectController = StreamController<String>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<List<WatchPartyRoom>> get lobbyRoomsStream =>
      _lobbyRoomsController.stream;
  Stream<WatchPartyRoom> get roomStateStream => _roomStateController.stream;
  Stream<SyncPlayerEvent> get syncPlayerStream => _syncPlayerController.stream;
  Stream<MovieChangedEvent> get movieChangedStream =>
      _movieChangedController.stream;
  Stream<ModerationAppliedEvent> get moderationAppliedStream =>
      _moderationAppliedController.stream;
  Stream<UserVoiceStateEvent> get userVoiceStateStream =>
      _userVoiceStateController.stream;
  Stream<WatchPartyMessage> get newMessageStream =>
      _newMessageController.stream;
  Stream<RoomErrorEvent> get roomErrorStream => _roomErrorController.stream;
  Stream<WatchPartyRoom> get roomCreatedStream => _roomCreatedController.stream;
  Stream<HostMigratedEvent> get hostMigratedStream =>
      _hostMigratedController.stream;
  Stream<WatchPartyMember> get userJoinedStream => _userJoinedController.stream;
  Stream<String> get userLeftStream => _userLeftController.stream;
  Stream<Map<String, dynamic>> get voiceSignalStream =>
      _voiceSignalController.stream;
  Stream<String> get voicePeerDisconnectStream =>
      _voicePeerDisconnectController.stream;

  /// Returns a stable userId for this app session.
  String getOrCreateUserId() {
    if (_userId != null && _userId!.isNotEmpty) return _userId!;
    final rand = Random.secure();
    final suffix = List.generate(
      8,
      (_) => rand.nextInt(36).toRadixString(36),
    ).join();
    _userId = 'mob_$suffix';
    _username ??= 'Khán giả ${suffix.substring(0, 4).toUpperCase()}';
    return _userId!;
  }

  String get username {
    getOrCreateUserId();
    return _username ?? 'Khán giả';
  }

  set username(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      _username = trimmed;
    }
  }

  void setActiveRoomId(String? roomId) {
    _activeRoomId = roomId;
  }

  /// Connects (or reuses existing connection) to the Watch Party Socket.IO server.
  void connect({String? serverUrl}) {
    final targetUrl = serverUrl ?? WatchPartyConfig.serverUrl;
    if (_socket != null) {
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    getOrCreateUserId();
    final socket = io.io(
      targetUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(1500)
          .build(),
    );

    socket.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      _sendPingSync();
      _startPingTimer();
      fetchLobbyRooms();
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      _pingTimer?.cancel();
    });

    socket.onConnectError((err) {
      debugPrint('[WatchParty] Connect error: $err');
      _isConnected = false;
      _connectionController.add(false);
    });

    socket.on('PONG_SYNC', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final sentAt = (map['clientSentAt'] as num?)?.toInt() ?? 0;
        final serverTs = (map['serverTimestamp'] as num?)?.toInt() ?? 0;
        final receivedAt = DateTime.now().millisecondsSinceEpoch;
        if (sentAt > 0 && serverTs > 0) {
          final res = WatchPartySyncMath.calculateClockSkewAndRtt(
            clientSentAtMs: sentAt,
            clientReceivedAtMs: receivedAt,
            serverTimestampMs: serverTs,
          );
          _rttMs = res.rttMs;
          _clockOffsetMs = res.clockOffsetMs;
        }
      }
    });

    socket.on('PING_SYNC', (data) {
      // Some servers reply on PING_SYNC instead of PONG_SYNC
      if (data is Map && data.containsKey('serverTimestamp')) {
        final map = Map<String, dynamic>.from(data);
        final sentAt = (map['clientSentAt'] as num?)?.toInt() ?? 0;
        final serverTs = (map['serverTimestamp'] as num?)?.toInt() ?? 0;
        final receivedAt = DateTime.now().millisecondsSinceEpoch;
        if (sentAt > 0 && serverTs > 0) {
          final res = WatchPartySyncMath.calculateClockSkewAndRtt(
            clientSentAtMs: sentAt,
            clientReceivedAtMs: receivedAt,
            serverTimestampMs: serverTs,
          );
          _rttMs = res.rttMs;
          _clockOffsetMs = res.clockOffsetMs;
        }
      }
    });

    socket.on('LOBBY_ROOMS', (data) {
      final rooms = _parseRoomList(data);
      _lobbyRoomsController.add(rooms);
    });

    socket.on('ROOM_CREATED', (data) {
      if (data is Map) {
        final room = WatchPartyRoom.fromJson(Map<String, dynamic>.from(data));
        _activeRoomId = room.roomId;
        _roomCreatedController.add(room);
      }
    });

    socket.on('ROOM_STATE', (data) {
      if (data is Map) {
        final room = WatchPartyRoom.fromJson(Map<String, dynamic>.from(data));
        _activeRoomId = room.roomId;
        _roomStateController.add(room);
      }
    });

    socket.on('SYNC_PLAYER', (data) {
      if (data is Map) {
        _syncPlayerController.add(
          SyncPlayerEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('MOVIE_CHANGED', (data) {
      if (data is Map) {
        _movieChangedController.add(
          MovieChangedEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('MODERATION_APPLIED', (data) {
      if (data is Map) {
        final event =
            ModerationAppliedEvent.fromJson(Map<String, dynamic>.from(data));
        if (event.action == 'KICK' && event.targetUserId == _userId) {
          _activeRoomId = null;
        }
        _moderationAppliedController.add(event);
      }
    });

    socket.on('USER_VOICE_STATE', (data) {
      if (data is Map) {
        _userVoiceStateController.add(
          UserVoiceStateEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('NEW_MESSAGE', (data) {
      if (data is Map) {
        _newMessageController.add(
          WatchPartyMessage.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('ROOM_ERROR', (data) {
      if (data is Map) {
        _roomErrorController.add(
          RoomErrorEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('HOST_MIGRATED', (data) {
      if (data is Map) {
        _hostMigratedController.add(
          HostMigratedEvent.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('USER_JOINED', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final memberJson = map['member'] is Map
            ? Map<String, dynamic>.from(map['member'] as Map)
            : map;
        _userJoinedController.add(WatchPartyMember.fromJson(memberJson));
      }
    });

    socket.on('USER_LEFT', (data) {
      if (data is Map) {
        final uid = (data['userId'] ?? '').toString();
        if (uid.isNotEmpty) _userLeftController.add(uid);
      }
    });

    socket.on('VOICE_SIGNAL', (data) {
      if (data is Map) {
        _voiceSignalController.add(Map<String, dynamic>.from(data));
      }
    });

    socket.on('VOICE_PEER_DISCONNECT', (data) {
      if (data is Map) {
        final uid = (data['userId'] ?? '').toString();
        if (uid.isNotEmpty) _voicePeerDisconnectController.add(uid);
      }
    });

    _socket = socket;
    socket.connect();
  }

  void reconnectWithUrl(String newUrl) {
    WatchPartyConfig.setServerUrl(newUrl);
    _pingTimer?.cancel();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    connect(serverUrl: newUrl);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendPingSync();
    });
  }

  void _sendPingSync() {
    if (_socket?.connected != true) return;
    _socket?.emit('PING_SYNC', {
      'clientSentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  List<WatchPartyRoom> _parseRoomList(dynamic data) {
    final list = <WatchPartyRoom>[];
    final raw = data is Map ? (data['rooms'] ?? data['data'] ?? []) : data;
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(WatchPartyRoom.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  /// Fetches public rooms via socket and/or REST fallback.
  Future<List<WatchPartyRoom>> fetchLobbyRooms() async {
    if (_socket?.connected == true) {
      _socket?.emit('GET_LOBBY_ROOMS');
    }
    try {
      final resp = await _dio.get('${WatchPartyConfig.serverUrl}/api/rooms/public');
      if (resp.statusCode == 200) {
        final rooms = _parseRoomList(resp.data);
        _lobbyRoomsController.add(rooms);
        return rooms;
      }
    } catch (e) {
      debugPrint('[WatchParty] REST lobby fetch fallback error: $e');
    }
    return [];
  }

  void createRoom({
    required String movieId,
    String? episodeId,
    required String movieTitle,
    required String posterUrl,
    required String streamUrl,
    required String roomName,
    required String visibility,
    String? passcode,
    bool forceCloseOldRoom = false,
  }) {
    connect();
    _socket?.emit('CREATE_ROOM', {
      'userId': getOrCreateUserId(),
      'username': username,
      'movieId': movieId,
      if (episodeId != null) 'episodeId': episodeId,
      'movieTitle': movieTitle,
      'posterUrl': posterUrl,
      'streamUrl': streamUrl,
      'roomName': roomName,
      'visibility': visibility,
      if (passcode != null && passcode.isNotEmpty) 'passcode': passcode,
      if (forceCloseOldRoom) 'forceCloseOldRoom': true,
    });
  }

  void joinRoom({
    required String roomId,
    String? passcode,
  }) {
    connect();
    _socket?.emit('JOIN_ROOM', {
      'userId': getOrCreateUserId(),
      'username': username,
      'roomId': roomId,
      if (passcode != null && passcode.isNotEmpty) 'passcode': passcode,
    });
  }

  void leaveRoom(String roomId) {
    _socket?.emit('LEAVE_ROOM', {
      'roomId': roomId,
      'userId': getOrCreateUserId(),
    });
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
    }
  }

  void emitPlayerEvent({
    required String roomId,
    required String type,
    required double currentTime,
  }) {
    _socket?.emit('PLAYER_EVENT', {
      'roomId': roomId,
      'type': type,
      'currentTime': currentTime,
      'clientTimestamp': serverNowMs,
    });
  }

  void emitHostHeartbeat({
    required String roomId,
    required double currentTime,
    required bool isPlaying,
  }) {
    _socket?.emit('HOST_HEARTBEAT', {
      'roomId': roomId,
      'currentTime': currentTime,
      'isPlaying': isPlaying,
      'serverSyncedTime': serverNowMs,
    });
  }

  void emitHostChangeMovie({
    required String roomId,
    required String newMovieId,
    String? episodeId,
    required String movieTitle,
    required String posterUrl,
    required String streamUrl,
  }) {
    _socket?.emit('HOST_CHANGE_MOVIE', {
      'roomId': roomId,
      'newMovieId': newMovieId,
      if (episodeId != null) 'episodeId': episodeId,
      'movieTitle': movieTitle,
      'posterUrl': posterUrl,
      'streamUrl': streamUrl,
    });
  }

  void emitHostModeration({
    required String roomId,
    required String targetUserId,
    required String action,
  }) {
    _socket?.emit('HOST_MODERATION', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'action': action,
    });
  }

  void emitChatMessage({
    required String roomId,
    required String content,
    String type = 'TEXT',
  }) {
    _socket?.emit('CHAT_MESSAGE', {
      'roomId': roomId,
      'content': content,
      'type': type,
    });
  }

  void emitVoiceState({
    required String roomId,
    required bool isMuted,
    required bool isSpeaking,
  }) {
    _socket?.emit('VOICE_STATE', {
      'roomId': roomId,
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
    });
  }

  void emitVoiceSignal({
    required String roomId,
    required String targetUserId,
    required Map<String, dynamic> signal,
  }) {
    _socket?.emit('VOICE_SIGNAL', {
      'roomId': roomId,
      'targetUserId': targetUserId,
      'signal': signal,
    });
  }
}
