import 'dart:math';

enum DriftCorrectionKind {
  none,
  speedUp,
  slowDown,
  hardSeek,
}

class DriftEvaluation {
  final DriftCorrectionKind kind;
  final double driftSeconds;
  final double playbackSpeed;

  const DriftEvaluation({
    required this.kind,
    required this.driftSeconds,
    required this.playbackSpeed,
  });
}

class ClockSyncResult {
  final int rttMs;
  final int clockOffsetMs;

  const ClockSyncResult({
    required this.rttMs,
    required this.clockOffsetMs,
  });
}

/// Pure math helpers for Watch Party time projection, RTT/clock-skew, and drift correction.
class WatchPartySyncMath {
  WatchPartySyncMath._();

  static const double minDriftThresholdSec = 0.4;
  static const double hardSeekThresholdSec = 1.5;
  static const double catchUpSpeed = 1.05;
  static const double slowDownSpeed = 0.95;

  /// Computes RTT and clock offset (`serverTime - clientTime`) from a PING_SYNC round-trip.
  static ClockSyncResult calculateClockSkewAndRtt({
    required int clientSentAtMs,
    required int clientReceivedAtMs,
    required int serverTimestampMs,
  }) {
    final rtt = max(0, clientReceivedAtMs - clientSentAtMs);
    final estimatedClientAtServer = clientSentAtMs + (rtt ~/ 2);
    final offset = serverTimestampMs - estimatedClientAtServer;
    return ClockSyncResult(rttMs: rtt, clockOffsetMs: offset);
  }

  /// Projects live playback timestamp given last saved state and synchronized server time.
  static double calculateProjectedTime({
    required double savedTime,
    required bool isPlaying,
    required int lastUpdatedAtMs,
    required int serverNowMs,
  }) {
    if (!isPlaying) return max(0.0, savedTime);
    final elapsedSec = max(0, serverNowMs - lastUpdatedAtMs) / 1000.0;
    return max(0.0, savedTime + elapsedSec);
  }

  /// Computes target seek position for a late joiner compensating for video load duration + RTT/2.
  static double calculateLateJoinSeekTarget({
    required double projectedCurrentTime,
    required Duration loadDuration,
    required int rttMs,
    required bool isPlaying,
  }) {
    if (!isPlaying) return max(0.0, projectedCurrentTime);
    final loadSec = loadDuration.inMilliseconds / 1000.0;
    final halfRttSec = max(0, rttMs) / 2000.0;
    return max(0.0, projectedCurrentTime + loadSec + halfRttSec);
  }

  /// Evaluates drift `dt = targetTimeSec - localTimeSec` and decides smooth speed adjustment vs hard seek.
  static DriftEvaluation evaluateDrift({
    required double localTimeSec,
    required double targetTimeSec,
  }) {
    final dt = targetTimeSec - localTimeSec;
    final absDt = dt.abs();
    if (absDt <= minDriftThresholdSec) {
      return DriftEvaluation(
        kind: DriftCorrectionKind.none,
        driftSeconds: dt,
        playbackSpeed: 1.0,
      );
    }
    if (absDt <= hardSeekThresholdSec) {
      return DriftEvaluation(
        kind: dt > 0
            ? DriftCorrectionKind.speedUp
            : DriftCorrectionKind.slowDown,
        driftSeconds: dt,
        playbackSpeed: dt > 0 ? catchUpSpeed : slowDownSpeed,
      );
    }
    return DriftEvaluation(
      kind: DriftCorrectionKind.hardSeek,
      driftSeconds: dt,
      playbackSpeed: 1.0,
    );
  }
}

class WatchPartyMember {
  final String userId;
  final String username;
  final String socketId;
  final bool isMuted;
  final bool isForceMuted;
  final bool isSpeaking;
  final int joinedAt;

  const WatchPartyMember({
    required this.userId,
    required this.username,
    this.socketId = '',
    this.isMuted = true,
    this.isForceMuted = false,
    this.isSpeaking = false,
    this.joinedAt = 0,
  });

  factory WatchPartyMember.fromJson(Map<String, dynamic> json) {
    return WatchPartyMember(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? 'Thành viên').toString(),
      socketId: (json['socketId'] ?? '').toString(),
      isMuted: json['isMuted'] == true,
      isForceMuted: json['isForceMuted'] == true,
      isSpeaking: json['isSpeaking'] == true,
      joinedAt: _asInt(json['joinedAt']),
    );
  }

  WatchPartyMember copyWith({
    String? userId,
    String? username,
    String? socketId,
    bool? isMuted,
    bool? isForceMuted,
    bool? isSpeaking,
    int? joinedAt,
  }) {
    return WatchPartyMember(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      socketId: socketId ?? this.socketId,
      isMuted: isMuted ?? this.isMuted,
      isForceMuted: isForceMuted ?? this.isForceMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class WatchPartyMessage {
  final String id;
  final String userId;
  final String username;
  final String content;
  final String type; // TEXT | REACTION | SYSTEM
  final int timestamp;

  const WatchPartyMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  factory WatchPartyMessage.fromJson(Map<String, dynamic> json) {
    return WatchPartyMessage(
      id: (json['id'] ?? '${DateTime.now().microsecondsSinceEpoch}').toString(),
      userId: (json['userId'] ?? 'system').toString(),
      username: (json['username'] ?? 'Hệ thống').toString(),
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'TEXT').toString().toUpperCase(),
      timestamp: _asInt(json['timestamp'], fallback: DateTime.now().millisecondsSinceEpoch),
    );
  }
}

class WatchPartyRoom {
  final String roomId;
  final String roomName;
  final String hostId;
  final String hostName;
  final String movieId;
  final String? episodeId;
  final String movieTitle;
  final String posterUrl;
  final String streamUrl;
  final String visibility; // PUBLIC | PRIVATE
  final bool requiresPasscode;
  final double savedTime;
  final double? projectedCurrentTime;
  final bool isPlaying;
  final int lastUpdatedAt;
  final int stateVersion;
  final int maxMembers;
  final int memberCount;
  final List<WatchPartyMember> members;

  const WatchPartyRoom({
    required this.roomId,
    required this.roomName,
    required this.hostId,
    this.hostName = '',
    required this.movieId,
    this.episodeId,
    this.movieTitle = '',
    this.posterUrl = '',
    this.streamUrl = '',
    this.visibility = 'PUBLIC',
    this.requiresPasscode = false,
    this.savedTime = 0.0,
    this.projectedCurrentTime,
    this.isPlaying = false,
    this.lastUpdatedAt = 0,
    this.stateVersion = 0,
    this.maxMembers = 5,
    this.memberCount = 0,
    this.members = const [],
  });

  bool get isFull => effectiveMemberCount >= maxMembers;
  int get effectiveMemberCount =>
      members.isNotEmpty ? members.length : memberCount;
  bool get isPrivate => visibility.toUpperCase() == 'PRIVATE' || requiresPasscode;

  String get resolvedHostName {
    if (hostName.isNotEmpty) return hostName;
    for (final m in members) {
      if (m.userId == hostId) return m.username;
    }
    return 'Chủ phòng';
  }

  factory WatchPartyRoom.fromJson(Map<String, dynamic> json) {
    // WatchPartyServer wraps ROOM_CREATED and ROOM_STATE payloads inside `{ room: {...}, projectedCurrentTime, serverTimestamp }`.
    final Map<String, dynamic> src = json['room'] is Map
        ? Map<String, dynamic>.from(json['room'] as Map)
        : json;

    final rawMembers = src['members'];
    final parsedMembers = <WatchPartyMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          parsedMembers.add(
            WatchPartyMember.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final visibility = (src['visibility'] ?? 'PUBLIC').toString().toUpperCase();
    final projectedRaw = json['projectedCurrentTime'] ?? src['projectedCurrentTime'];
    return WatchPartyRoom(
      roomId: (src['roomId'] ?? src['id'] ?? '').toString(),
      roomName: (src['roomName'] ?? 'Phòng Xem Chung').toString(),
      hostId: (src['hostId'] ?? '').toString(),
      hostName: (src['hostName'] ?? '').toString(),
      movieId: (src['movieId'] ?? '').toString(),
      episodeId: src['episodeId']?.toString(),
      movieTitle: (src['movieTitle'] ?? 'Phim đang chiếu').toString(),
      posterUrl: (src['posterUrl'] ?? '').toString(),
      streamUrl: (src['streamUrl'] ?? '').toString(),
      visibility: visibility,
      requiresPasscode: src['requiresPasscode'] == true || visibility == 'PRIVATE',
      savedTime: _asDouble(src['savedTime']),
      projectedCurrentTime: projectedRaw != null ? _asDouble(projectedRaw) : null,
      isPlaying: src['isPlaying'] == true,
      lastUpdatedAt: _asInt(src['lastUpdatedAt']),
      stateVersion: _asInt(src['stateVersion']),
      maxMembers: _asInt(src['maxMembers'], fallback: 5),
      memberCount: _asInt(
        src['memberCount'],
        fallback: parsedMembers.length,
      ),
      members: parsedMembers,
    );
  }

  WatchPartyRoom copyWith({
    String? roomId,
    String? roomName,
    String? hostId,
    String? hostName,
    String? movieId,
    String? episodeId,
    String? movieTitle,
    String? posterUrl,
    String? streamUrl,
    String? visibility,
    bool? requiresPasscode,
    double? savedTime,
    double? projectedCurrentTime,
    bool? isPlaying,
    int? lastUpdatedAt,
    int? stateVersion,
    int? maxMembers,
    int? memberCount,
    List<WatchPartyMember>? members,
  }) {
    return WatchPartyRoom(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      movieId: movieId ?? this.movieId,
      episodeId: episodeId ?? this.episodeId,
      movieTitle: movieTitle ?? this.movieTitle,
      posterUrl: posterUrl ?? this.posterUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      visibility: visibility ?? this.visibility,
      requiresPasscode: requiresPasscode ?? this.requiresPasscode,
      savedTime: savedTime ?? this.savedTime,
      projectedCurrentTime: projectedCurrentTime ?? this.projectedCurrentTime,
      isPlaying: isPlaying ?? this.isPlaying,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      stateVersion: stateVersion ?? this.stateVersion,
      maxMembers: maxMembers ?? this.maxMembers,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
    );
  }
}

class SyncPlayerEvent {
  final String roomId;
  final String type; // PLAY | PAUSE | SEEK
  final double currentTime;
  final bool isPlaying;
  final int serverTimestamp;
  final int stateVersion;

  const SyncPlayerEvent({
    required this.roomId,
    required this.type,
    required this.currentTime,
    required this.isPlaying,
    required this.serverTimestamp,
    required this.stateVersion,
  });

  factory SyncPlayerEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'PLAY').toString().toUpperCase();
    return SyncPlayerEvent(
      roomId: (json['roomId'] ?? '').toString(),
      type: type,
      currentTime: _asDouble(json['currentTime']),
      isPlaying: json['isPlaying'] ?? (type == 'PLAY'),
      serverTimestamp: _asInt(json['serverTimestamp'], fallback: DateTime.now().millisecondsSinceEpoch),
      stateVersion: _asInt(json['stateVersion']),
    );
  }
}

class MovieChangedEvent {
  final String roomId;
  final String newMovieId;
  final String? episodeId;
  final String movieTitle;
  final String posterUrl;
  final String streamUrl;
  final double savedTime;
  final bool isPlaying;

  const MovieChangedEvent({
    required this.roomId,
    required this.newMovieId,
    this.episodeId,
    required this.movieTitle,
    required this.posterUrl,
    required this.streamUrl,
    this.savedTime = 0.0,
    this.isPlaying = true,
  });

  factory MovieChangedEvent.fromJson(Map<String, dynamic> json) {
    return MovieChangedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      newMovieId: (json['newMovieId'] ?? json['movieId'] ?? '').toString(),
      episodeId: json['episodeId']?.toString(),
      movieTitle: (json['movieTitle'] ?? 'Phim mới').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      streamUrl: (json['streamUrl'] ?? '').toString(),
      savedTime: _asDouble(json['savedTime']),
      isPlaying: json['isPlaying'] ?? true,
    );
  }
}

class ModerationAppliedEvent {
  final String roomId;
  final String targetUserId;
  final String action; // MUTE_MIC | UNMUTE_MIC | KICK | TRANSFER_HOST
  final String? newHostId;
  final String? message;

  const ModerationAppliedEvent({
    required this.roomId,
    required this.targetUserId,
    required this.action,
    this.newHostId,
    this.message,
  });

  factory ModerationAppliedEvent.fromJson(Map<String, dynamic> json) {
    return ModerationAppliedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      targetUserId: (json['targetUserId'] ?? '').toString(),
      action: (json['action'] ?? '').toString().toUpperCase(),
      newHostId: json['newHostId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class UserVoiceStateEvent {
  final String roomId;
  final String userId;
  final bool isMuted;
  final bool isForceMuted;
  final bool isSpeaking;

  const UserVoiceStateEvent({
    required this.roomId,
    required this.userId,
    required this.isMuted,
    required this.isForceMuted,
    required this.isSpeaking,
  });

  factory UserVoiceStateEvent.fromJson(Map<String, dynamic> json) {
    return UserVoiceStateEvent(
      roomId: (json['roomId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      isMuted: json['isMuted'] == true,
      isForceMuted: json['isForceMuted'] == true,
      isSpeaking: json['isSpeaking'] == true,
    );
  }
}

class HostMigratedEvent {
  final String roomId;
  final String newHostId;
  final String newHostName;

  const HostMigratedEvent({
    required this.roomId,
    required this.newHostId,
    required this.newHostName,
  });

  factory HostMigratedEvent.fromJson(Map<String, dynamic> json) {
    return HostMigratedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      newHostId: (json['newHostId'] ?? '').toString(),
      newHostName: (json['newHostName'] ?? 'Chủ phòng mới').toString(),
    );
  }
}

class RoomErrorEvent {
  final String code;
  final String message;
  final String? existingRoomId;
  final int? retryAfterSec;

  const RoomErrorEvent({
    required this.code,
    required this.message,
    this.existingRoomId,
    this.retryAfterSec,
  });

  factory RoomErrorEvent.fromJson(Map<String, dynamic> json) {
    return RoomErrorEvent(
      code: (json['code'] ?? 'UNKNOWN_ERROR').toString().toUpperCase(),
      message: (json['message'] ?? 'Đã có lỗi xảy ra').toString(),
      existingRoomId: json['existingRoomId']?.toString(),
      retryAfterSec: json['retryAfterSec'] != null ? _asInt(json['retryAfterSec']) : null,
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
