import 'package:flutter/foundation.dart';

/// Configuration for the Watch Party signaling & sync server.
class WatchPartyConfig {
  WatchPartyConfig._();

  static String? _customServerUrl;
  static const String _envServerUrl =
      String.fromEnvironment('WATCH_PARTY_URL');

  /// Default server URL:
  /// - Uses `--dart-define=WATCH_PARTY_URL=...` if provided
  /// - Android emulator reaches host machine via `http://10.0.2.2:4000`
  /// - iOS simulator / Desktop / Web reaches host machine via `http://localhost:4000`
  static String get defaultServerUrl {
    if (_envServerUrl.isNotEmpty) return _envServerUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }

  static String get serverUrl => _customServerUrl ?? defaultServerUrl;

  static void setServerUrl(String? url) {
    final trimmed = url?.trim() ?? '';
    _customServerUrl = trimmed.isEmpty ? null : trimmed;
  }

  /// Fallback sample HLS stream if a movie only has an HTML embed link.
  static const String fallbackSampleStreamUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
}
