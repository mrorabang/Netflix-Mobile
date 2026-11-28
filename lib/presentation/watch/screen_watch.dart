import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class ScreenWatch extends StatefulWidget {
  final String url;
  final String title;

  const ScreenWatch({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<ScreenWatch> createState() => _ScreenWatchState();
}

class _ScreenWatchState extends State<ScreenWatch> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showControls = true;
  String? _osdActionLabel;
  IconData? _osdActionIcon;
  Timer? _hideTimer;
  Timer? _osdTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (TvMode.isNativeAndroidTv) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
      ]);
    }

    _scheduleHideControls();

    String playUrl = widget.url.trim();
    if (playUrl.contains('.m3u8') && !playUrl.contains('player')) {
      playUrl =
          'https://player.phimapi.com/player/?url=${Uri.encodeComponent(playUrl)}';
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _injectAutoPlay();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(playUrl));

    _controller = controller;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isLoading) {
        setState(() => _showControls = false);
      }
    });
  }

  void _revealControlsTemporarily() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleHideControls();
  }

  void _showOsdFeedback(IconData icon, String label) {
    _osdTimer?.cancel();
    setState(() {
      _osdActionIcon = icon;
      _osdActionLabel = label;
    });
    _osdTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() {
          _osdActionLabel = null;
          _osdActionIcon = null;
        });
      }
    });
  }

  void _injectAutoPlay() {
    const js = '''
      (function() {
        function tryPlay() {
          try {
            if (window.jwplayer && typeof window.jwplayer === 'function') {
              var p = window.jwplayer();
              if (p && typeof p.play === 'function') {
                p.setMute(false);
                p.play();
              }
            }
          } catch(e) {}

          var v = document.querySelector('video');
          if (v) {
            v.muted = false;
            v.play().catch(function() {
              v.muted = true;
              v.play().then(function() {
                setTimeout(function() { v.muted = false; }, 300);
              }).catch(function() {});
            });
          }

          var buttons = document.querySelectorAll(
            '.jw-display-icon-container, .jw-icon-playback, .art-icon-state, .dplayer-play-icon, button.play, .play-button, .vjs-big-play-button'
          );
          buttons.forEach(function(b) {
            try { b.click(); } catch(e) {}
          });
        }

        tryPlay();
        var count = 0;
        var timer = setInterval(function() {
          count++;
          tryPlay();
          var v = document.querySelector('video');
          if ((v && !v.paused) || count > 20) {
            clearInterval(timer);
          }
        }, 350);
      })();
    ''';
    _controller.runJavaScript(js);
  }

  void _togglePlayPause() {
    _revealControlsTemporarily();
    _showOsdFeedback(Icons.play_arrow_rounded, 'Phát / Tạm dừng');
    const js = '''
      (function() {
        try {
          if (window.jwplayer && typeof window.jwplayer === 'function') {
            var p = window.jwplayer();
            if (p) {
              p.getState() === 'playing' ? p.pause() : p.play();
              return;
            }
          }
        } catch(e) {}
        var v = document.querySelector('video');
        if (v) {
          v.paused ? v.play() : v.pause();
        }
      })();
    ''';
    _controller.runJavaScript(js);
  }

  void _setPlaying(bool play) {
    _revealControlsTemporarily();
    _showOsdFeedback(
      play ? Icons.play_arrow_rounded : Icons.pause_rounded,
      play ? 'Tiếp tục phát' : 'Tạm dừng',
    );
    final js = '''
      (function() {
        try {
          if (window.jwplayer && typeof window.jwplayer === 'function') {
            var p = window.jwplayer();
            if (p) {
              ${play ? 'p.play();' : 'p.pause();'}
              return;
            }
          }
        } catch(e) {}
        var v = document.querySelector('video');
        if (v) {
          ${play ? 'v.play();' : 'v.pause();'}
        }
      })();
    ''';
    _controller.runJavaScript(js);
  }

  void _seekRelative(int seconds) {
    _revealControlsTemporarily();
    _showOsdFeedback(
      seconds < 0 ? Icons.replay_10_rounded : Icons.forward_10_rounded,
      seconds < 0 ? 'Lùi ${seconds.abs()} giây' : 'Tua +$seconds giây',
    );
    final js = '''
      (function() {
        try {
          if (window.jwplayer && typeof window.jwplayer === 'function') {
            var p = window.jwplayer();
            if (p) {
              p.seek(Math.max(0, p.getPosition() + ($seconds)));
              return;
            }
          }
        } catch(e) {}
        var v = document.querySelector('video');
        if (v) {
          v.currentTime = Math.max(0, v.currentTime + ($seconds));
        }
      })();
    ''';
    _controller.runJavaScript(js);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlayPause();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.mediaPlay) {
      _setPlaying(true);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.mediaPause) {
      _setPlaying(false);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaRewind) {
      _seekRelative(-10);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaFastForward) {
      _seekRelative(10);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _revealControlsTemporarily();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _osdTimer?.cancel();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (TvMode.isNativeAndroidTv) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTv = TvMode.isTv(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _revealControlsTemporarily(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: WebViewWidget(controller: _controller),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xE6000000), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          isTv ? 28 : 12,
                          MediaQuery.of(context).padding.top + (isTv ? 18 : 6),
                          isTv ? 28 : 16,
                          20,
                        ),
                        child: Row(
                          children: [
                            ScaleTap(
                              onTap: () => Navigator.of(context).pop(),
                              showFocusRing: true,
                              focusBorderRadius: 24,
                              child: Container(
                                width: isTv ? 44 : 38,
                                height: isTv ? 44 : 38,
                                decoration: BoxDecoration(
                                  color: const Color(0x99000000),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: isTv ? 20 : 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: isTv ? 20 : 15.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Trung tâm OSD thông báo thao tác Remote (Tua ±10s / Phát / Tạm dừng)
                if (_osdActionLabel != null && _osdActionIcon != null)
                  Center(
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0D0D12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _osdActionIcon,
                              color: kNetflixRed,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _osdActionLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Thanh gợi ý phím điều khiển Remote dưới đáy trên Android TV
                if (isTv)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 260),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xD9000000)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _TvRemoteHintChip(
                                keyLabel: 'OK / ⏯',
                                actionLabel: 'Phát • Tạm dừng',
                              ),
                              SizedBox(width: 18),
                              _TvRemoteHintChip(
                                keyLabel: '◀ / ▶',
                                actionLabel: 'Tua ±10 giây',
                              ),
                              SizedBox(width: 18),
                              _TvRemoteHintChip(
                                keyLabel: 'BACK',
                                actionLabel: 'Quay lại',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: kNetflixRed,
                      strokeWidth: 2.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvRemoteHintChip extends StatelessWidget {
  final String keyLabel;
  final String actionLabel;

  const _TvRemoteHintChip({
    required this.keyLabel,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Color(0xFFD4D4DC),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
