import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Allow landscape rotation for movie watching
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);

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
    _focusNode.dispose();
    // Restore orientation support
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
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: WebViewWidget(controller: _controller),
                ),
                // Top overlay with back button and movie title
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 26),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
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
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
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
