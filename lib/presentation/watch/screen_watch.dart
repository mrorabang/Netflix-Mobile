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
  Timer? _hideTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);

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

  void _seekRelative(int seconds) {
    _revealControlsTemporarily();
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

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _seekRelative(-10);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seekRelative(10);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Focus(
        focusNode: _focusNode,
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
                            colors: [Color(0xD9000000), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          12,
                          MediaQuery.of(context).padding.top + 6,
                          16,
                          16,
                        ),
                        child: Row(
                          children: [
                            ScaleTap(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0x80000000),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 6,
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
