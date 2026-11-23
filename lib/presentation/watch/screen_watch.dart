import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      playUrl = 'https://player.phimapi.com/player/?url=${Uri.encodeComponent(playUrl)}';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(playUrl));
  }

  @override
  void dispose() {
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
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            autofocus: true,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
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
    );
  }
}
