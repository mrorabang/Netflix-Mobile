import 'package:flutter_test/flutter_test.dart';
import 'package:netflix_clone/domain/watch_party/models/watch_party_models.dart';

void main() {
  group('WatchPartySyncMath', () {
    test('calculateClockSkewAndRtt computes RTT and server offset', () {
      final result = WatchPartySyncMath.calculateClockSkewAndRtt(
        clientSentAtMs: 1000,
        clientReceivedAtMs: 1100,
        serverTimestampMs: 1250,
      );
      expect(result.rttMs, 100);
      // client at server ~ 1000 + 50 = 1050; offset = 1250 - 1050 = 200
      expect(result.clockOffsetMs, 200);
    });

    test('calculateProjectedTime advances only when playing', () {
      final playing = WatchPartySyncMath.calculateProjectedTime(
        savedTime: 100.0,
        isPlaying: true,
        lastUpdatedAtMs: 10000,
        serverNowMs: 13500,
      );
      expect(playing, closeTo(103.5, 0.001));

      final paused = WatchPartySyncMath.calculateProjectedTime(
        savedTime: 100.0,
        isPlaying: false,
        lastUpdatedAtMs: 10000,
        serverNowMs: 13500,
      );
      expect(paused, 100.0);
    });

    test('calculateLateJoinSeekTarget compensates for load duration and RTT/2',
        () {
      final target = WatchPartySyncMath.calculateLateJoinSeekTarget(
        projectedCurrentTime: 120.0,
        loadDuration: const Duration(milliseconds: 1200),
        rttMs: 100,
        isPlaying: true,
      );
      // 120.0 + 1.2 + 0.05 = 121.25
      expect(target, closeTo(121.25, 0.001));

      final pausedTarget = WatchPartySyncMath.calculateLateJoinSeekTarget(
        projectedCurrentTime: 120.0,
        loadDuration: const Duration(milliseconds: 1200),
        rttMs: 100,
        isPlaying: false,
      );
      expect(pausedTarget, 120.0);
    });

    test('evaluateDrift selects none, speedUp, slowDown, or hardSeek', () {
      final none = WatchPartySyncMath.evaluateDrift(
        localTimeSec: 50.0,
        targetTimeSec: 50.3,
      );
      expect(none.kind, DriftCorrectionKind.none);
      expect(none.playbackSpeed, 1.0);

      final speedUp = WatchPartySyncMath.evaluateDrift(
        localTimeSec: 50.0,
        targetTimeSec: 50.8,
      );
      expect(speedUp.kind, DriftCorrectionKind.speedUp);
      expect(speedUp.playbackSpeed, 1.05);

      final slowDown = WatchPartySyncMath.evaluateDrift(
        localTimeSec: 50.8,
        targetTimeSec: 50.0,
      );
      expect(slowDown.kind, DriftCorrectionKind.slowDown);
      expect(slowDown.playbackSpeed, 0.95);

      final hardSeek = WatchPartySyncMath.evaluateDrift(
        localTimeSec: 50.0,
        targetTimeSec: 52.5,
      );
      expect(hardSeek.kind, DriftCorrectionKind.hardSeek);
      expect(hardSeek.playbackSpeed, 1.0);
    });
  });

  group('WatchParty Models', () {
    test('WatchPartyRoom.fromJson parses members, capacity, and visibility',
        () {
      final room = WatchPartyRoom.fromJson({
        'roomId': 'ABC123',
        'roomName': 'Phòng Test',
        'hostId': 'u1',
        'movieId': 'm1',
        'movieTitle': 'Inception',
        'visibility': 'PRIVATE',
        'maxMembers': 5,
        'isPlaying': true,
        'savedTime': 42.5,
        'members': [
          {'userId': 'u1', 'username': 'Host', 'isMuted': false},
          {'userId': 'u2', 'username': 'Guest', 'isForceMuted': true},
        ],
      });

      expect(room.roomId, 'ABC123');
      expect(room.isPrivate, true);
      expect(room.effectiveMemberCount, 2);
      expect(room.isFull, false);
      expect(room.resolvedHostName, 'Host');
      expect(room.members[1].isForceMuted, true);
    });
  });
}
