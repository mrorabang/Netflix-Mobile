import 'package:flutter/material.dart';

const kWidth = SizedBox(
  width: 10,
);
const kHeight = SizedBox(
  height: 10,
);
const kHeight20 = SizedBox(
  height: 20,
);

const kHeight50 = SizedBox(
  height: 50,
);

// border radius
final BorderRadius kRadius10 = BorderRadius.circular(10);
final BorderRadius kRadius30 = BorderRadius.circular(30);

// image
const mainImage =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
const imageUrltemp1 =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';
const imageUrltemp2 =
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500';

// Textstyle
const TextStyle kHomeTitleText =
    TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

const imageAppendUrl = "";
const mainScrenImage =
    'https://assets.nflxext.com/ffe/siteui/vlv3/ab180a27-b661-44d7-a6d9-940cb32f2f4a/7fb62e44-3180-4e2a-b9c2-b5e1c4a00bc9/VN-vi-20231009-popsignuptwoweeks-perspective_alpha_website_medium.jpg';

/// Lưu URL gốc từ vsmov để tự động fallback nếu ảnh trên CDN TMDB không tồn tại.
final Map<String, String> _tmdbFallbackUrls = <String, String>{};

String? getTmdbFallbackUrl(String url) => _tmdbFallbackUrls[url];

final RegExp _vsmovPrefixedHashRegex = RegExp(
  r'/(?:poster|thumb)_([A-Za-z0-9]{20,40}\.(?:jpg|jpeg|png|webp))$',
  caseSensitive: false,
);

final RegExp _vsmovDirectHashRegex = RegExp(
  r'/storage/images/([A-Za-z0-9]{20,40}\.(?:jpg|jpeg|png|webp))$',
  caseSensitive: false,
);

bool _isVsmovStorageUrl(String url) {
  return url.contains('vsmov.com/storage/images/') ||
      url.contains('vsphim.com/storage/images/');
}

/// Chuyển đổi link ảnh nén thấp của vsmov sang link ảnh HD chính thức của TMDB (`image.tmdb.org`)
/// nếu trích xuất được mã hash ảnh TMDB hợp lệ.
String _upgradeVsmovToTmdbHd(String fullUrl, {String size = 'w780'}) {
  if (!_isVsmovStorageUrl(fullUrl)) return fullUrl;

  String? hashFile;
  final prefixedMatch = _vsmovPrefixedHashRegex.firstMatch(fullUrl);
  if (prefixedMatch != null) {
    hashFile = prefixedMatch.group(1);
  } else {
    final directMatch = _vsmovDirectHashRegex.firstMatch(fullUrl);
    if (directMatch != null) {
      hashFile = directMatch.group(1);
    }
  }

  if (hashFile != null && hashFile.isNotEmpty) {
    final tmdbUrl = 'https://image.tmdb.org/t/p/$size/$hashFile';
    _tmdbFallbackUrls[tmdbUrl] = fullUrl;
    return tmdbUrl;
  }
  return fullUrl;
}

String _normalizeRawUrl(String raw, [String? cdn]) {
  if (raw.isEmpty) {
    return 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800';
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  final cdnUrl = (cdn != null && cdn.isNotEmpty)
      ? cdn
      : 'https://phimimg.com/';
  final cleanCdn = cdnUrl.endsWith('/') ? cdnUrl : '$cdnUrl/';
  final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
  return '$cleanCdn$cleanPath';
}

/// Lấy URL Poster dọc chuẩn HD:
/// - Tự động đảo lại trường bị ngược của `vsmov.com` (nơi `thumb_url` mới chứa `poster_...jpg`,
///   còn `poster_url` lại chứa `thumb_...jpg` chỉ 10KB).
/// - Nâng cấp thẳng lên CDN `image.tmdb.org/t/p/w780` sắc nét gấp ~10 lần.
String resolveImageUrl(
  dynamic posterUrl,
  dynamic thumbUrl, [
  String? cdn,
  String tmdbSize = 'w780',
]) {
  final p = (posterUrl is String) ? posterUrl.trim() : '';
  final t = (thumbUrl is String) ? thumbUrl.trim() : '';

  String chosen = '';
  if (t.contains('/poster_') && !p.contains('/poster_')) {
    // vsmov đặt poster dọc thật ở trường thumb_url
    chosen = t;
  } else if (p.contains('/thumb_') && t.isNotEmpty) {
    chosen = t;
  } else if (p.isNotEmpty) {
    chosen = p;
  } else if (t.isNotEmpty) {
    chosen = t;
  }

  final fullUrl = _normalizeRawUrl(chosen, cdn);
  return _upgradeVsmovToTmdbHd(fullUrl, size: tmdbSize);
}

/// Lấy URL Backdrop ngang (16:9) chuẩn HD cho thẻ video / Mới & Thịnh Hành.
String resolveBackdropUrl(
  dynamic posterUrl,
  dynamic thumbUrl, [
  String? cdn,
  String tmdbSize = 'w780',
]) {
  final p = (posterUrl is String) ? posterUrl.trim() : '';
  final t = (thumbUrl is String) ? thumbUrl.trim() : '';

  String chosen = '';
  if (p.contains('/thumb_')) {
    // vsmov đặt backdrop ngang của TMDB ở trường poster_url (thumb_<hash>.jpg)
    chosen = p;
  } else if (t.isNotEmpty && !t.contains('/poster_')) {
    chosen = t;
  } else if (p.isNotEmpty) {
    chosen = p;
  } else if (t.isNotEmpty) {
    chosen = t;
  }

  final fullUrl = _normalizeRawUrl(chosen, cdn);
  return _upgradeVsmovToTmdbHd(fullUrl, size: tmdbSize);
}

/// Nâng cấp URL poster lên chất lượng cao nhất (`original`) cho Banner Hero & Chi tiết phim.
String upgradeToHighResPoster(String url) {
  if (url.contains('image.tmdb.org/t/p/w780/')) {
    final upgraded = url.replaceFirst('/t/p/w780/', '/t/p/original/');
    final fallback = _tmdbFallbackUrls[url];
    if (fallback != null) {
      _tmdbFallbackUrls[upgraded] = fallback;
    }
    return upgraded;
  }
  return url;
}
