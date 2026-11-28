import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/watch_party/watch_party_config.dart';
import 'package:netflix_clone/domain/core/di/injectable.dart';
import 'package:netflix_clone/domain/description/description_service.dart';
import 'package:netflix_clone/domain/watch_party/models/watch_party_models.dart';
import 'package:netflix_clone/infrastructure/watch_party/watch_party_service.dart';
import 'package:netflix_clone/presentation/watch_party/watch_party_hls_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class _FloatingEmoji {
  final int id;
  final String emoji;
  _FloatingEmoji(this.id, this.emoji);
}

class ScreenWatchPartyRoom extends StatefulWidget {
  final WatchPartyRoom initialRoom;

  const ScreenWatchPartyRoom({super.key, required this.initialRoom});

  @override
  State<ScreenWatchPartyRoom> createState() => _ScreenWatchPartyRoomState();
}

class _ScreenWatchPartyRoomState extends State<ScreenWatchPartyRoom> {
  final _service = WatchPartyService.instance;
  static const _platformChannel = MethodChannel('com.example.netflix_clone/cast');
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();

  late WatchPartyRoom _room;
  WebViewController? _webController;
  bool _useEmbedFallback = false;
  bool _isVideoReady = false;
  bool _playerIsPlaying = false;
  bool _playerIsBuffering = true;
  bool _needsUserTap = false;
  double _playerCurrentSec = 0.0;
  double _playerDurationSec = 0.0;
  String? _videoError;
  bool _isRemoteAction = false;
  bool _isMuted = true;
  bool _isForceMuted = false;
  bool _showOverlayChat = true;
  bool _chatOverlayMuted = false;
  bool _showFullscreenUi = true;
  bool _showLandscapeEmojiBar = false;
  bool _isLeavingConfirmed = false;
  bool _isConfirmDialogOpen = false;
  Timer? _fullscreenUiHideTimer;
  Timer? _chatToastHideTimer;
  int _activeTab = 0; // 0: Chat, 1: Members (in portrait)
  int _lastStateVersion = 0;
  double _lastSyncedSavedTime = 0.0;
  int _lastSyncedUpdatedAt = 0;
  bool _lastSyncedPlaying = false;
  DateTime? _lastHardSeekAt;

  final List<WatchPartyMessage> _messages = [];
  final List<_FloatingEmoji> _floatingEmojis = [];
  int _emojiCounter = 0;

  Timer? _heartbeatTimer;
  Timer? _driftTimer;
  final List<StreamSubscription> _subs = [];

  String get _myUserId => _service.getOrCreateUserId();
  bool get _isHost => _room.hostId == _myUserId;

  @override
  void initState() {
    super.initState();
    _room = widget.initialRoom;
    _lastStateVersion = _room.stateVersion;
    _lastSyncedSavedTime = _room.projectedCurrentTime ?? _room.savedTime;
    _lastSyncedUpdatedAt = _room.lastUpdatedAt > 0
        ? _room.lastUpdatedAt
        : _service.serverNowMs;
    _lastSyncedPlaying = _room.isPlaying;

    _syncLocalForceMuteFromRoom();
    _initVideoForRoom(_room, isLateJoin: true);
    _bindSocketStreams();
    _startTimers();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _driftTimer?.cancel();
    _fullscreenUiHideTimer?.cancel();
    _chatToastHideTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _chatController.dispose();
    _chatScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _syncLocalForceMuteFromRoom() {
    for (final m in _room.members) {
      if (m.userId == _myUserId) {
        _isForceMuted = m.isForceMuted;
        if (_isForceMuted) _isMuted = true;
        break;
      }
    }
  }

  WebViewController _createWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final wv = WebViewController.fromPlatformCreationParams(params);
    if (wv.platform is AndroidWebViewController) {
      final androidWv = wv.platform as AndroidWebViewController;
      AndroidWebViewController.enableDebugging(false);
      androidWv.setMediaPlaybackRequiresUserGesture(false);
      androidWv.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }
    wv
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'WatchPartyPlayer',
        onMessageReceived: (JavaScriptMessage msg) {
          _handlePlayerMessage(msg.message);
        },
      );
    return wv;
  }

  void _syncVoicePeersToWebView() {
    if (_webController == null || _useEmbedFallback) return;
    final idsJson = jsonEncode(_room.members.map((m) => m.userId).toList());
    final myIdJson = jsonEncode(_myUserId);
    _webController!.runJavaScript(
      'if (window.wpVoice) { window.wpVoice.setSelf($myIdJson); window.wpVoice.syncPeers($idsJson); }',
    );
  }

  void _handlePlayerMessage(String raw) {
    if (!mounted) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = (data['type'] ?? '').toString();

      if (type == 'voice_signal') {
        final targetId = (data['targetUserId'] ?? '').toString();
        final signal = data['signal'];
        if (targetId.isNotEmpty && signal is Map) {
          _service.emitVoiceSignal(
            roomId: _room.roomId,
            targetUserId: targetId,
            signal: Map<String, dynamic>.from(signal),
          );
        }
        return;
      }
      if (type == 'voice_speaking') {
        final speaking = data['isSpeaking'] == true;
        _service.emitVoiceState(
          roomId: _room.roomId,
          isMuted: _isMuted,
          isSpeaking: speaking && !_isMuted && !_isForceMuted,
        );
        return;
      }
      if (type == 'voice_error') {
        final msg = (data['message'] ?? 'Không thể bật micro.').toString();
        setState(() => _isMuted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: kNetflixRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final ct = (data['currentTime'] as num?)?.toDouble();
      final dur = (data['duration'] as num?)?.toDouble();
      final playing = data['isPlaying'] as bool?;
      final buffering = data['isBuffering'] as bool?;

      setState(() {
        if (ct != null && ct.isFinite && ct >= 0) _playerCurrentSec = ct;
        if (dur != null && dur.isFinite && dur > 0) _playerDurationSec = dur;
        if (playing != null) _playerIsPlaying = playing;
        if (buffering != null) _playerIsBuffering = buffering;

        if (type == 'ready') {
          _isVideoReady = true;
          _videoError = null;
          _syncVoicePeersToWebView();
        } else if (type == 'playing') {
          _isVideoReady = true;
          _playerIsPlaying = true;
          _playerIsBuffering = false;
          _needsUserTap = false;
        } else if (type == 'pause') {
          _playerIsPlaying = false;
        } else if (type == 'autoplay_blocked') {
          _needsUserTap = true;
          _playerIsBuffering = false;
        } else if (type == 'error') {
          _playerIsBuffering = false;
          _videoError = (data['message'] ?? 'Không thể phát luồng video này.').toString();
        }
      });
    } catch (_) {}
  }

  String _extractDirectStreamUrl(String? linkM3u8, String? linkEmbed) {
    final m3u8 = (linkM3u8 ?? '').trim();
    if (m3u8.isNotEmpty &&
        !m3u8.toLowerCase().contains('player.phimapi.com') &&
        !m3u8.toLowerCase().contains('?url=')) {
      return m3u8;
    }
    final candidate = m3u8.isNotEmpty ? m3u8 : (linkEmbed ?? '').trim();
    if (candidate.isEmpty) return '';
    try {
      final uri = Uri.parse(candidate);
      final inner = uri.queryParameters['url']?.trim() ?? '';
      if (inner.isNotEmpty && inner.toLowerCase().contains('.m3u8')) {
        return inner;
      }
    } catch (_) {}
    return candidate;
  }

  Future<void> _initVideoForRoom(
    WatchPartyRoom room, {
    required bool isLateJoin,
  }) async {
    final rawUrl = _extractDirectStreamUrl(room.streamUrl, room.streamUrl);
    final playableUrl = rawUrl.isNotEmpty
        ? rawUrl
        : WatchPartyConfig.fallbackSampleStreamUrl;
    final lower = playableUrl.toLowerCase();
    final isDirectStream = !lower.contains('player.phimapi.com') &&
        !lower.contains('?url=') &&
        (lower.contains('.m3u8') || lower.contains('.mp4'));

    final startSec = isLateJoin
        ? (room.projectedCurrentTime ?? room.savedTime)
        : room.savedTime;

    _lastSyncedSavedTime = startSec;
    _lastSyncedUpdatedAt = _service.serverNowMs;
    _lastSyncedPlaying = room.isPlaying;
    _lastHardSeekAt = DateTime.now();

    setState(() {
      _isVideoReady = false;
      _playerIsBuffering = true;
      _needsUserTap = false;
      _videoError = null;
      _playerCurrentSec = startSec;
      _playerIsPlaying = room.isPlaying;
      _useEmbedFallback = !isDirectStream;
    });

    final wv = _webController ?? _createWebViewController();
    _webController = wv;

    if (!isDirectStream) {
      await wv.loadRequest(Uri.parse(playableUrl));
      if (mounted) setState(() => _isVideoReady = true);
      return;
    }

    final html = buildWatchPartyHlsHtml(
      streamUrl: playableUrl,
      startTimeSec: startSec,
      autoPlay: room.isPlaying,
      rttMs: _service.rttMs,
    );
    await wv.loadHtmlString(html, baseUrl: 'https://player.phimapi.com');
  }

  void _enableEmbedFallback() {
    final rawUrl = _room.streamUrl.trim();
    final baseUrl = rawUrl.isNotEmpty
        ? rawUrl
        : WatchPartyConfig.fallbackSampleStreamUrl;
    final embedUrl = baseUrl.contains('.m3u8') && !baseUrl.contains('player')
        ? 'https://player.phimapi.com/player/?url=${Uri.encodeComponent(baseUrl)}'
        : baseUrl;

    final wv = _webController ?? _createWebViewController();
    _webController = wv;
    wv.loadRequest(Uri.parse(embedUrl));

    setState(() {
      _useEmbedFallback = true;
      _isVideoReady = true;
      _playerIsBuffering = false;
      _videoError = null;
    });
  }

  void _bindSocketStreams() {
    _subs.add(_service.roomStateStream.listen((room) {
      if (!mounted || room.roomId != _room.roomId) return;
      setState(() {
        _room = room;
        _syncLocalForceMuteFromRoom();
      });
    }));

    _subs.add(_service.syncPlayerStream.listen((ev) async {
      if (!mounted || ev.roomId.toUpperCase() != _room.roomId.toUpperCase()) return;
      if (ev.stateVersion > 0 && ev.stateVersion < _lastStateVersion) return;
      _lastStateVersion = ev.stateVersion;
      _lastSyncedSavedTime = ev.currentTime;
      _lastSyncedUpdatedAt = ev.serverTimestamp;
      _lastSyncedPlaying = ev.isPlaying;

      if (_webController == null || _useEmbedFallback) return;

      _isRemoteAction = true;
      _lastHardSeekAt = DateTime.now();
      try {
        final forceSeek = ev.type == 'SEEK';
        await _webController!.runJavaScript(
          'if (window.wpPlayer) window.wpPlayer.syncState(${ev.currentTime}, ${ev.isPlaying}, $forceSeek);',
        );
      } catch (_) {} finally {
        _isRemoteAction = false;
      }
      if (mounted) {
        setState(() {
          _playerCurrentSec = ev.currentTime;
          _playerIsPlaying = ev.isPlaying;
        });
      }
    }));

    _subs.add(_service.movieChangedStream.listen((ev) {
      if (!mounted || ev.roomId.toUpperCase() != _room.roomId.toUpperCase()) return;
      final directUrl = _extractDirectStreamUrl(ev.streamUrl, ev.streamUrl);
      setState(() {
        _useEmbedFallback = false;
        _room = _room.copyWith(
          movieId: ev.newMovieId,
          episodeId: ev.episodeId,
          movieTitle: ev.movieTitle,
          posterUrl: ev.posterUrl,
          streamUrl: directUrl,
          savedTime: ev.savedTime,
          projectedCurrentTime: ev.savedTime,
          isPlaying: ev.isPlaying,
        );
      });
      _initVideoForRoom(_room, isLateJoin: false);
    }));

    _subs.add(_service.userJoinedStream.listen((member) {
      if (!mounted) return;
      final exists = _room.members.any((m) => m.userId == member.userId);
      if (!exists) {
        setState(() {
          _room = _room.copyWith(members: [..._room.members, member]);
        });
        _syncVoicePeersToWebView();
      }
    }));

    _subs.add(_service.userLeftStream.listen((uid) {
      if (!mounted) return;
      setState(() {
        _room = _room.copyWith(
          members: _room.members.where((m) => m.userId != uid).toList(),
        );
      });
      _webController?.runJavaScript(
        'if (window.wpVoice) window.wpVoice.disconnectPeer(${jsonEncode(uid)});',
      );
    }));

    _subs.add(_service.voiceSignalStream.listen((data) {
      if (!mounted || _webController == null || _useEmbedFallback) return;
      final fromId = (data['fromUserId'] ?? '').toString();
      final signal = data['signal'];
      if (fromId.isEmpty || signal == null) return;
      _webController!.runJavaScript(
        'if (window.wpVoice) window.wpVoice.handleSignal(${jsonEncode(fromId)}, ${jsonEncode(signal)});',
      );
    }));

    _subs.add(_service.voicePeerDisconnectStream.listen((uid) {
      if (!mounted || _webController == null || _useEmbedFallback) return;
      _webController!.runJavaScript(
        'if (window.wpVoice) window.wpVoice.disconnectPeer(${jsonEncode(uid)});',
      );
    }));

    _subs.add(_service.userVoiceStateStream.listen((ev) {
      if (!mounted || ev.roomId != _room.roomId) return;
      setState(() {
        final updated = _room.members.map((m) {
          if (m.userId != ev.userId) return m;
          return m.copyWith(
            isMuted: ev.isMuted,
            isForceMuted: ev.isForceMuted,
            isSpeaking: ev.isSpeaking,
          );
        }).toList();
        _room = _room.copyWith(members: updated);
        if (ev.userId == _myUserId) {
          _isForceMuted = ev.isForceMuted;
          if (_isForceMuted) _isMuted = true;
        }
      });
    }));

    _subs.add(_service.moderationAppliedStream.listen((ev) {
      if (!mounted || ev.roomId != _room.roomId) return;
      if (ev.action == 'KICK' && ev.targetUserId == _myUserId) {
        _isLeavingConfirmed = true;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã bị chủ phòng mời ra khỏi phòng.'),
            backgroundColor: kNetflixRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (ev.action == 'TRANSFER_HOST') {
        final nextHostId = (ev.newHostId != null && ev.newHostId!.isNotEmpty)
            ? ev.newHostId!
            : ev.targetUserId;
        if (nextHostId.isNotEmpty) {
          setState(() {
            _room = _room.copyWith(hostId: nextHostId);
          });
        }
      } else if (ev.action == 'MUTE_MIC' || ev.action == 'UNMUTE_MIC') {
        final forceMute = ev.action == 'MUTE_MIC';
        setState(() {
          _room = _room.copyWith(
            members: _room.members.map((m) {
              if (m.userId != ev.targetUserId) return m;
              return m.copyWith(
                isForceMuted: forceMute,
                isMuted: forceMute ? true : m.isMuted,
              );
            }).toList(),
          );
          if (ev.targetUserId == _myUserId) {
            _isForceMuted = forceMute;
            if (forceMute) _isMuted = true;
          }
        });
      }
    }));

    _subs.add(_service.hostMigratedStream.listen((ev) {
      if (!mounted || ev.roomId != _room.roomId) return;
      setState(() {
        _room = _room.copyWith(hostId: ev.newHostId, hostName: ev.newHostName);
      });
    }));

    _subs.add(_service.newMessageStream.listen((msg) {
      if (!mounted) return;
      if (msg.type == 'REACTION') {
        _spawnFloatingEmoji(msg.content);
        return;
      }
      setState(() {
        _messages.add(msg);
        if (!_chatOverlayMuted) {
          _showOverlayChat = true;
        }
      });
      if (!_chatOverlayMuted) {
        _chatToastHideTimer?.cancel();
        _chatToastHideTimer = Timer(const Duration(seconds: 6), () {
          if (mounted && !_showFullscreenUi) {
            setState(() => _showOverlayChat = false);
          }
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }));
  }

  void _startTimers() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isHost || !mounted || !_isVideoReady || _useEmbedFallback) return;
      _service.emitHostHeartbeat(
        roomId: _room.roomId,
        currentTime: _playerCurrentSec,
        isPlaying: _playerIsPlaying,
      );
    });

    _driftTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isHost || _isRemoteAction || _useEmbedFallback || !mounted) return;
      if (_webController == null || !_isVideoReady || !_lastSyncedPlaying) {
        return;
      }
      if (_playerIsBuffering) return;

      final targetSec = WatchPartySyncMath.calculateProjectedTime(
        savedTime: _lastSyncedSavedTime,
        isPlaying: _lastSyncedPlaying,
        lastUpdatedAtMs: _lastSyncedUpdatedAt,
        serverNowMs: _service.serverNowMs,
      );
      final eval = WatchPartySyncMath.evaluateDrift(
        localTimeSec: _playerCurrentSec,
        targetTimeSec: targetSec,
      );

      switch (eval.kind) {
        case DriftCorrectionKind.none:
          await _webController!.runJavaScript(
            'if (window.wpPlayer) window.wpPlayer.setRate(1.0);',
          );
          break;
        case DriftCorrectionKind.speedUp:
        case DriftCorrectionKind.slowDown:
          await _webController!.runJavaScript(
            'if (window.wpPlayer) window.wpPlayer.setRate(${eval.playbackSpeed});',
          );
          break;
        case DriftCorrectionKind.hardSeek:
          final sinceLastSeek = _lastHardSeekAt == null
              ? const Duration(seconds: 99)
              : DateTime.now().difference(_lastHardSeekAt!);
          if (eval.driftSeconds.abs() <= 3.0 ||
              sinceLastSeek < const Duration(seconds: 8)) {
            final rate = eval.driftSeconds > 0
                ? WatchPartySyncMath.catchUpSpeed
                : WatchPartySyncMath.slowDownSpeed;
            await _webController!.runJavaScript(
              'if (window.wpPlayer) window.wpPlayer.setRate($rate);',
            );
            break;
          }
          _isRemoteAction = true;
          _lastHardSeekAt = DateTime.now();
          try {
            await _webController!.runJavaScript(
              'if (window.wpPlayer) window.wpPlayer.syncState($targetSec, true, true);',
            );
          } finally {
            _isRemoteAction = false;
          }
          break;
      }
    });
  }

  void _spawnFloatingEmoji(String emoji) {
    final id = ++_emojiCounter;
    setState(() {
      _floatingEmojis.add(_FloatingEmoji(id, emoji));
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _floatingEmojis.removeWhere((e) => e.id == id);
      });
    });
  }

  void _togglePlayPause() {
    if (!_isHost || _isRemoteAction || _webController == null || _useEmbedFallback) return;
    final currentSec = _playerCurrentSec;
    if (_playerIsPlaying) {
      _webController!.runJavaScript('if (window.wpPlayer) window.wpPlayer.pause();');
      _service.emitPlayerEvent(
        roomId: _room.roomId,
        type: 'PAUSE',
        currentTime: currentSec,
      );
      setState(() {
        _playerIsPlaying = false;
        _lastSyncedPlaying = false;
      });
    } else {
      _webController!.runJavaScript('if (window.wpPlayer) window.wpPlayer.play();');
      _service.emitPlayerEvent(
        roomId: _room.roomId,
        type: 'PLAY',
        currentTime: currentSec,
      );
      setState(() {
        _playerIsPlaying = true;
        _lastSyncedPlaying = true;
      });
    }
  }

  void _seekToSeconds(double seconds) {
    if (!_isHost || _isRemoteAction || _webController == null || _useEmbedFallback) return;
    final maxDur = _playerDurationSec > 0 ? _playerDurationSec : seconds;
    final clamped = seconds.clamp(0.0, maxDur);
    _webController!.runJavaScript('if (window.wpPlayer) window.wpPlayer.seek($clamped);');
    _service.emitPlayerEvent(
      roomId: _room.roomId,
      type: 'SEEK',
      currentTime: clamped,
    );
    setState(() {
      _playerCurrentSec = clamped;
      _lastSyncedSavedTime = clamped;
      _lastSyncedUpdatedAt = _service.serverNowMs;
    });
  }

  Future<void> _toggleMic() async {
    if (_isForceMuted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chủ phòng đã tắt mic của bạn.'),
          backgroundColor: kNetflixRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nextMuted = !_isMuted;
    if (!nextMuted) {
      try {
        final granted = await _platformChannel
                .invokeMethod<bool>('requestAudioPermission') ??
            true;
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng cấp quyền Micro để dùng Voice Chat.'),
                backgroundColor: kNetflixRed,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } catch (_) {}
    }

    setState(() => _isMuted = nextMuted);
    _syncVoicePeersToWebView();
    _webController?.runJavaScript(
      'if (window.wpVoice) window.wpVoice.setMuted(${nextMuted ? 'true' : 'false'});',
    );
    _service.emitVoiceState(
      roomId: _room.roomId,
      isMuted: _isMuted,
      isSpeaking: false,
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    _service.emitChatMessage(roomId: _room.roomId, content: text, type: 'TEXT');
  }

  void _sendReaction(String emoji) {
    _service.emitChatMessage(
      roomId: _room.roomId,
      content: emoji,
      type: 'REACTION',
    );
  }

  Future<void> _showChangeMovieDialog() async {
    if (!_isHost) return;
    final searchCtrl = TextEditingController();
    final dio = Dio(BaseOptions(connectTimeout: 8000, receiveTimeout: 8000));

    List<Map<String, dynamic>> results = [];
    bool isSearching = true;
    bool initialLoaded = false;
    bool isLoadingEps = false;
    Map<String, dynamic>? pickedMovie;
    List<Map<String, String>> pickedEpisodes = [];
    Timer? debounce;

    Future<void> runSearch(
      String query,
      void Function(void Function()) setModalState,
    ) async {
      setModalState(() => isSearching = true);
      try {
        final q = query.trim();
        final url = q.isEmpty
            ? 'https://phimapi.com/danh-sach/phim-moi-cap-nhat?page=1'
            : 'https://phimapi.com/v1/api/tim-kiem?keyword=${Uri.encodeComponent(q)}&limit=14';
        final resp = await dio.get(url);
        final data = resp.data;
        final List items = q.isEmpty
            ? (data['items'] as List? ?? [])
            : ((data['data']?['items']) as List? ?? []);
        final String cdn = (q.isEmpty
                    ? data['APP_DOMAIN_CDN_IMAGE']
                    : data['data']?['APP_DOMAIN_CDN_IMAGE'])
                ?.toString() ??
            'https://phimimg.com';
        setModalState(() {
          results = items.take(14).map<Map<String, dynamic>>((raw) {
            final map = Map<String, dynamic>.from(raw as Map);
            final p = (map['poster_url'] ?? map['thumb_url'] ?? '').toString();
            final fullPoster = p.startsWith('http')
                ? p
                : (p.isNotEmpty ? '$cdn/${p.replaceFirst(RegExp(r'^/'), '')}' : '');
            return {
              'slug': (map['slug'] ?? map['_id'] ?? '').toString(),
              'name': (map['name'] ?? 'Phim').toString(),
              'poster_url': fullPoster,
              'year': (map['year'] ?? '').toString(),
            };
          }).toList();
        });
      } catch (_) {
      } finally {
        setModalState(() => isSearching = false);
      }
    }

    Future<void> selectMovie(
      Map<String, dynamic> item,
      BuildContext ctx,
      void Function(void Function()) setModalState,
    ) async {
      final slug = item['slug'] as String;
      final name = item['name'] as String;
      final poster = item['poster_url'] as String;
      setModalState(() {
        isLoadingEps = true;
        pickedMovie = item;
        pickedEpisodes = [];
      });

      final eps = <Map<String, String>>[];
      try {
        final resp = await dio.get('https://phimapi.com/phim/$slug');
        final epServers = resp.data['episodes'] as List? ?? [];
        if (epServers.isNotEmpty) {
          final serverData = (epServers.first['server_data'] as List?) ?? [];
          for (final raw in serverData) {
            final ep = Map<String, dynamic>.from(raw as Map);
            final link = _extractDirectStreamUrl(
              ep['link_m3u8']?.toString(),
              ep['link_embed']?.toString(),
            );
            if (link.isNotEmpty) {
              eps.add({
                'name': (ep['name'] ?? 'Full').toString(),
                'slug': (ep['slug'] ?? 'full').toString(),
                'streamUrl': link,
              });
            }
          }
        }
      } catch (_) {}

      if (eps.isEmpty) {
        try {
          final res = await getIt<DescriptionService>().getMovieDescription(id: slug);
          res.fold((_) {}, (desc) {
            for (final ep in desc.episodeList) {
              final link = _extractDirectStreamUrl(ep.linkM3u8, ep.linkEmbed);
              if (link.isNotEmpty) {
                eps.add({'name': ep.name, 'slug': ep.name, 'streamUrl': link});
              }
            }
          });
        } catch (_) {}
      }

      if (eps.length <= 1) {
        final streamUrl = eps.isNotEmpty
            ? eps.first['streamUrl']!
            : WatchPartyConfig.fallbackSampleStreamUrl;
        if (ctx.mounted) Navigator.pop(ctx);
        _service.emitHostChangeMovie(
          roomId: _room.roomId,
          newMovieId: slug,
          episodeId: eps.isNotEmpty ? eps.first['slug'] : 'full',
          movieTitle: name,
          posterUrl: poster,
          streamUrl: streamUrl,
        );
        return;
      }

      setModalState(() {
        isLoadingEps = false;
        pickedEpisodes = eps;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (!initialLoaded) {
            initialLoaded = true;
            Future.microtask(() => runSearch('', setModalState));
          }
          return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (pickedMovie != null && pickedEpisodes.length > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => setModalState(() {
                          pickedMovie = null;
                          pickedEpisodes = [];
                        }),
                      ),
                    Expanded(
                      child: Text(
                        pickedMovie != null && pickedEpisodes.length > 1
                            ? 'Chọn tập: ${pickedMovie!['name']}'
                            : 'Đổi phim / Tìm phim mới',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (pickedMovie == null || pickedEpisodes.length <= 1) ...[
                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    onChanged: (val) {
                      debounce?.cancel();
                      debounce = Timer(
                        const Duration(milliseconds: 350),
                        () => runSearch(val, setModalState),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm tên phim (VD: Conan, Slime, Mai)...',
                      hintStyle: const TextStyle(color: kGray, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: kGray, size: 20),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kNetflixRed,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  color: kNetflixRed),
                              onPressed: () =>
                                  runSearch(searchCtrl.text, setModalState),
                            ),
                      filled: true,
                      fillColor: kCardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (isLoadingEps)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: kNetflixRed),
                    ),
                  )
                else if (pickedMovie != null && pickedEpisodes.length > 1)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: pickedEpisodes.length,
                      itemBuilder: (_, i) {
                        final ep = pickedEpisodes[i];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kCardColor,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _service.emitHostChangeMovie(
                              roomId: _room.roomId,
                              newMovieId: pickedMovie!['slug'] as String,
                              episodeId: ep['slug'],
                              movieTitle: '${pickedMovie!['name']} - ${ep['name']}',
                              posterUrl: pickedMovie!['poster_url'] as String,
                              streamUrl: ep['streamUrl']!,
                            );
                          },
                          child: Text(
                            ep['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy phim phù hợp.',
                              style: TextStyle(color: kGray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.white10),
                            itemBuilder: (_, i) {
                              final item = results[i];
                              final poster = item['poster_url'] as String;
                              final year = item['year'] as String;
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: poster.isNotEmpty
                                      ? Image.network(
                                          poster,
                                          width: 40,
                                          height: 54,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.movie, color: kGray),
                                        )
                                      : const Icon(Icons.movie, color: kGray),
                                ),
                                title: Text(
                                  item['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: year.isNotEmpty
                                    ? Text(
                                        year,
                                        style: const TextStyle(
                                            color: kGray, fontSize: 11.5),
                                      )
                                    : null,
                                onTap: () => selectMovie(item, ctx, setModalState),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Future<void> _leaveRoom() async {
    if (_isConfirmDialogOpen || !mounted) return;
    _isConfirmDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Rời phòng Xem Chung?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          _isHost
              ? 'Bạn đang là Chủ phòng. Nếu rời phòng, quyền chủ phòng sẽ chuyển cho thành viên khác (hoặc phòng sẽ đóng nếu không còn ai).'
              : 'Bạn có chắc muốn thoát ra màn hình sảnh chờ không?',
          style: const TextStyle(color: kGray, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNetflixRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Thoát phòng',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    _isConfirmDialogOpen = false;

    if (confirmed == true && mounted) {
      _isLeavingConfirmed = true;
      _service.leaveRoom(_room.roomId);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: _isLeavingConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLeavingConfirmed) {
          _leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: isLandscape ? _buildLandscapeView() : _buildPortraitView(),
      ),
    );
  }

  void _scheduleFullscreenUiHide() {
    _fullscreenUiHideTimer?.cancel();
    _fullscreenUiHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showFullscreenUi) {
        setState(() {
          _showFullscreenUi = false;
          _showLandscapeEmojiBar = false;
        });
      }
    });
  }

  void _setFullscreenUiVisible(bool visible) {
    _fullscreenUiHideTimer?.cancel();
    setState(() {
      _showFullscreenUi = visible;
      if (!visible) _showLandscapeEmojiBar = false;
    });
    if (visible) {
      _scheduleFullscreenUiHide();
    }
  }

  Widget _buildVideoStage({required bool isLandscape}) {
    final showChrome = !isLandscape || _showFullscreenUi;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        if (_webController != null)
          WebViewWidget(controller: _webController!),

        if (_playerIsBuffering && _videoError == null && !_useEmbedFallback)
          const Center(
            child: CircularProgressIndicator(color: kNetflixRed),
          ),

        if (_needsUserTap && _videoError == null && !_useEmbedFallback)
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNetflixRed,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                setState(() => _needsUserTap = false);
                _webController?.runJavaScript(
                  'if (window.wpPlayer) window.wpPlayer.play();',
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text(
                'Bấm để xem cùng phòng',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),

        if (_videoError != null)
          Container(
            color: Colors.black87,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _videoError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                      onPressed: () => _initVideoForRoom(_room, isLateJoin: false),
                      child: const Text(
                        'Thử phát lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kNetflixRed),
                      onPressed: _enableEmbedFallback,
                      child: const Text(
                        'Mở trình phát Embed',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Floating Emoji Reactions
        Positioned(
          right: 20,
          bottom: 54,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _floatingEmojis
                  .map(
                    (e) => TweenAnimationBuilder<double>(
                      key: ValueKey(e.id),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1600),
                      builder: (_, t, child) => Transform.translate(
                        offset: Offset(0, -60 * t),
                        child: Opacity(opacity: 1.0 - t, child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          e.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

        // Top Bar Overlay
        if (showChrome)
          Positioned(
            top: 8,
            left: 10,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: _leaveRoom,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _room.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_room.movieTitle} • #${_room.roomId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (_useEmbedFallback)
                  TextButton(
                    onPressed: () {
                      setState(() => _useEmbedFallback = false);
                      _initVideoForRoom(_room, isLateJoin: false);
                    },
                    child: const Text(
                      'Đồng bộ lại',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                if (_isHost)
                  IconButton(
                    tooltip: 'Đổi phim',
                    icon: const Icon(Icons.movie_filter_rounded,
                        color: Colors.white),
                    onPressed: _showChangeMovieDialog,
                  ),
                if (isLandscape)
                  IconButton(
                    tooltip: 'Ẩn các nút điều khiển',
                    icon: const Icon(Icons.visibility_off_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () => _setFullscreenUiVisible(false),
                  ),
                IconButton(
                  tooltip: isLandscape ? 'Thu nhỏ' : 'Toàn màn hình',
                  icon: Icon(
                    isLandscape
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (isLandscape) {
                      _fullscreenUiHideTimer?.cancel();
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                      SystemChrome.setPreferredOrientations(
                        const [DeviceOrientation.portraitUp],
                      );
                    } else {
                      SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.immersiveSticky,
                      );
                      SystemChrome.setPreferredOrientations(const [
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      _setFullscreenUiVisible(true);
                    }
                  },
                ),
              ],
            ),
          ),

        // Bottom Video Controls (Host vs Locked Viewer)
        if (!_useEmbedFallback && showChrome)
          Positioned(
            left: 10,
            right: 10,
            bottom: 6,
            child: _isHost
                ? _buildHostControls()
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_clock_rounded,
                            size: 14, color: Colors.white70),
                        SizedBox(width: 6),
                        Text(
                          'Chủ phòng đang điều khiển phát',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildHostControls() {
    final pos = _playerCurrentSec;
    final dur = _playerDurationSec;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _playerIsPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.replay_10_rounded,
                color: Colors.white, size: 20),
            onPressed: () => _seekToSeconds(pos - 10),
          ),
          Expanded(
            child: Slider(
              value: dur > 0 ? pos.clamp(0.0, dur) : 0.0,
              min: 0.0,
              max: dur > 0 ? dur : 1.0,
              activeColor: kNetflixRed,
              inactiveColor: Colors.white24,
              onChangeEnd: _seekToSeconds,
              onChanged: (v) {
                setState(() => _playerCurrentSec = v);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.forward_10_rounded,
                color: Colors.white, size: 20),
            onPressed: () => _seekToSeconds(pos + 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitView() {
    return SafeArea(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildVideoStage(isLandscape: false),
          ),
          // Thanh công cụ gọn: Mic + Tab Chat / Thành viên
          Container(
            color: kSurfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _buildMicButton(),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _activeTab = 0),
                  child: Text(
                    'Chat',
                    style: TextStyle(
                      color: _activeTab == 0 ? kNetflixRed : kGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _activeTab = 1),
                  child: Text(
                    'Thành viên (${_room.effectiveMemberCount}/5)',
                    style: TextStyle(
                      color: _activeTab == 1 ? kNetflixRed : kGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: backgrounndColor,
              child: _activeTab == 0 ? _buildChatPanel() : _buildMembersPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildVideoStage(isLandscape: true),

        // Khung chat nổi khi có người nhắn (có nút X để ẩn ngay)
        if (_showOverlayChat && _messages.isNotEmpty)
          Positioned(
            left: 14,
            bottom: _showFullscreenUi ? 72 : 16,
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      _chatToastHideTimer?.cancel();
                      setState(() {
                        _showOverlayChat = false;
                        _chatOverlayMuted = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              color: Colors.white70, size: 13),
                          SizedBox(width: 3),
                          Text(
                            'Ẩn chat',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: IgnorePointer(
                    child: ListView.builder(
                      shrinkWrap: true,
                      reverse: true,
                      itemCount: _messages.length.clamp(0, 5),
                      itemBuilder: (_, idx) {
                        final msg = _messages[_messages.length - 1 - idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            msg.type == 'SYSTEM'
                                ? msg.content
                                : '${msg.username}: ${msg.content}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Thanh Floating Pill (Mic, Emoji, Chat, Ẩn UI) — chỉ hiện khi _showFullscreenUi = true
        if (_showFullscreenUi)
          Positioned(
            right: 16,
            bottom: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showLandscapeEmojiBar)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xDD16161D),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['❤️', '😂', '😮', '🔥', '👏']
                          .map(
                            (e) => GestureDetector(
                              onTap: () {
                                _sendReaction(e);
                                _scheduleFullscreenUiHide();
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(e,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xCC16161D),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMicButton(),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Thả cảm xúc',
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: _showLandscapeEmojiBar
                              ? Colors.amber
                              : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() =>
                              _showLandscapeEmojiBar = !_showLandscapeEmojiBar);
                          _scheduleFullscreenUiHide();
                        },
                      ),
                      IconButton(
                        tooltip: _showOverlayChat ? 'Ẩn chat' : 'Hiện chat',
                        icon: Icon(
                          _showOverlayChat
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color:
                              _showOverlayChat ? Colors.amber : Colors.white70,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showOverlayChat = !_showOverlayChat;
                            _chatOverlayMuted = !_showOverlayChat;
                          });
                          _scheduleFullscreenUiHide();
                        },
                      ),
                      IconButton(
                        tooltip: 'Ẩn thanh nút',
                        icon: const Icon(Icons.visibility_off_rounded,
                            color: Colors.white70, size: 19),
                        onPressed: () => _setFullscreenUiVisible(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Nút nhỏ mờ ở góc phải trên để mở lại toàn bộ nút điều khiển khi cần
          Positioned(
            top: 12,
            right: 14,
            child: Opacity(
              opacity: 0.55,
              child: GestureDetector(
                onTap: () => _setFullscreenUiVisible(true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Hiện nút',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleMic,
      child: Tooltip(
        message: _isForceMuted
            ? 'Chủ phòng đã tắt mic của bạn'
            : (_isMuted ? 'Bật mic' : 'Tắt mic'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isForceMuted
                ? const Color(0x33EF4444)
                : (_isMuted ? kCardColor : const Color(0x3322C55E)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isForceMuted
                  ? Colors.redAccent
                  : (_isMuted ? Colors.white24 : const Color(0xFF22C55E)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isForceMuted
                    ? Icons.lock_rounded
                    : (_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded),
                size: 16,
                color: _isForceMuted
                    ? Colors.redAccent
                    : (_isMuted ? kGray : const Color(0xFF22C55E)),
              ),
              const SizedBox(width: 4),
              Text(
                _isForceMuted
                    ? 'Bị khóa mic'
                    : (_isMuted ? 'Mic tắt' : 'Đang bật'),
                style: TextStyle(
                  color: _isForceMuted ? Colors.redAccent : Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, idx) {
              final msg = _messages[idx];
              if (msg.type == 'SYSTEM') {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Text(
                      msg.content,
                      style: const TextStyle(
                        color: kGray,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${msg.username}: ',
                        style: TextStyle(
                          color: msg.userId == _room.hostId
                              ? kNetflixRed
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      TextSpan(
                        text: msg.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          color: kSurfaceColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dãy icon thả cảm xúc đặt gọn ngay trên ô nhập & nút gửi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: ['❤️', '😂', '😮', '🔥', '👏']
                    .map(
                      (e) => GestureDetector(
                        onTap: () => _sendReaction(e),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6, bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kCardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 17)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _sendChat(),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin cùng mọi người...',
                        hintStyle: const TextStyle(color: kGray, fontSize: 13),
                        filled: true,
                        fillColor: kCardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: kNetflixRed),
                    onPressed: _sendChat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersPanel() {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _room.members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) {
        final member = _room.members[idx];
        final isMemberHost = member.userId == _room.hostId;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCardColor,
                  border: Border.all(
                    color: member.isSpeaking && !member.isMuted
                        ? const Color(0xFF22C55E)
                        : Colors.white24,
                    width: member.isSpeaking && !member.isMuted ? 2.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    member.username.isNotEmpty
                        ? member.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isMemberHost) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x33E50914),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Chủ phòng',
                              style: TextStyle(
                                color: kNetflixRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      member.isForceMuted
                          ? 'Đã bị khóa mic'
                          : (member.isMuted ? 'Mic đang tắt' : 'Mic đang bật'),
                      style: TextStyle(
                        color: member.isForceMuted ? Colors.redAccent : kGray,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isHost && member.userId != _myUserId)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: kGray),
                  color: kCardColor,
                  onSelected: (action) {
                    _service.emitHostModeration(
                      roomId: _room.roomId,
                      targetUserId: member.userId,
                      action: action,
                    );
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: member.isForceMuted ? 'UNMUTE_MIC' : 'MUTE_MIC',
                      child: Text(
                        member.isForceMuted ? 'Mở khóa Mic' : 'Tắt Mic',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'TRANSFER_HOST',
                      child: Text(
                        'Chuyển quyền Chủ phòng',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'KICK',
                      child: Text(
                        'Mời ra khỏi phòng',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
