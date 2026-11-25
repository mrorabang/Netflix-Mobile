// ============================================================================
// FILE: lib/infrastructure/tmdb/tmdb_4k_service.dart
// MỤC ĐÍCH:
//   Kết nối trực tiếp tới API `/3/{movie|tv}/{id}/images` của The Movie DB (TMDB)
//   để lấy bộ ảnh chất lượng gốc cao nhất cho ứng dụng Nét Lích:
//     - Banner ngang chuẩn 4K UHD (3840 x 2160, ưu tiên ảnh không chữ `iso_639_1 == null`
//       để không bị cắt chữ khi hiển thị trên mọi tỉ lệ màn hình).
//     - Poster dọc Ultra-HD (2000 x 3000).
//     - Logo tiêu đề phim nền trong suốt (.png) độ phân giải cao.
//
// CÁCH HOẠT ĐỘNG:
//   1. Khi parse JSON từ vsmov / phimapi, các model gọi `registerFromApiJson(json)`
//      để ghi nhớ ánh xạ `slug -> (tmdbId, tmdbType, originName, year)`.
//   2. Khi hiển thị Banner Hero, Chi tiết phim hoặc thẻ Mới & Hot, widget gọi
//      `fetch4kForSlug(slug)` — kết quả được lưu bộ nhớ đệm (in-memory cache) nên
//      mỗi bộ phim chỉ gọi TMDB đúng 1 lần duy nhất trong suốt phiên dùng app.
// ============================================================================

import 'dart:developer';
import 'package:dio/dio.dart';

/// Khóa TMDB dùng chung (hỗ trợ ghi đè qua `--dart-define=TMDB_API_KEY=...` trên CI nếu cần,
/// không phụ thuộc vào file `api_key.dart` đang nằm trong `.gitignore`).
const String _kTmdbApiKey = String.fromEnvironment(
  'TMDB_API_KEY',
  defaultValue: '2155956beab817303ff7118a5497f466',
);

class TmdbMovieHint {
  final String slug;
  final String? tmdbId;
  final String? tmdbType; // 'movie' hoặc 'tv'
  final String? originName;
  final String? title;
  final String? year;

  const TmdbMovieHint({
    required this.slug,
    this.tmdbId,
    this.tmdbType,
    this.originName,
    this.title,
    this.year,
  });
}

class Tmdb4kMedia {
  /// Link banner ngang chuẩn 4K (`3840x2160` hoặc cao nhất hiện có trên TMDB).
  final String? backdrop4kUrl;

  /// Link poster dọc độ phân giải gốc (`2000x3000` hoặc cao nhất hiện có).
  final String? poster4kUrl;

  /// Link logo tiêu đề phim trong suốt (.png) từ TMDB.
  final String? logoUrl;

  /// Chiều rộng thực tế của banner ngang (vd: 3840).
  final int backdropWidth;

  /// Chiều cao thực tế của banner ngang (vd: 2160).
  final int backdropHeight;

  const Tmdb4kMedia({
    this.backdrop4kUrl,
    this.poster4kUrl,
    this.logoUrl,
    this.backdropWidth = 0,
    this.backdropHeight = 0,
  });

  /// Đánh dấu ảnh đạt chuẩn 4K UHD thực thụ (chiều ngang từ 3000px trở lên) hoặc Ultra-HD.
  bool get isTrue4k => backdropWidth >= 3000;

  bool get hasAnyHighRes =>
      (backdrop4kUrl != null && backdrop4kUrl!.isNotEmpty) ||
      (poster4kUrl != null && poster4kUrl!.isNotEmpty);
}

class Tmdb4kService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: 7000,
      receiveTimeout: 7000,
    ),
  );

  static final Map<String, TmdbMovieHint> _hintsBySlug =
      <String, TmdbMovieHint>{};
  static final Map<String, Tmdb4kMedia?> _cacheBySlug =
      <String, Tmdb4kMedia?>{};
  static final Map<String, Future<Tmdb4kMedia?>> _inflight =
      <String, Future<Tmdb4kMedia?>>{};

  /// Trích xuất và lưu thông tin TMDB từ mỗi object phim trả về của vsmov / phimapi.
  static void registerFromApiJson(Map<String, dynamic> json) {
    final rawSlug =
        (json['slug']?.toString() ?? json['_id']?.toString() ?? '').trim();
    if (rawSlug.isEmpty) return;

    String? tmdbId;
    String? tmdbType;
    final tmdbRaw = json['tmdb'];
    if (tmdbRaw is Map) {
      final idStr = tmdbRaw['id']?.toString().trim() ?? '';
      if (idStr.isNotEmpty && idStr != '0' && idStr != 'null') {
        tmdbId = idStr;
      }
      final typeStr = tmdbRaw['type']?.toString().trim().toLowerCase() ?? '';
      if (typeStr == 'movie' || typeStr == 'tv') {
        tmdbType = typeStr;
      }
    }

    // Suy đoán movie/tv dự phòng nếu API chỉ trả về trường `type` của phim
    if (tmdbType == null) {
      final itemType = json['type']?.toString().toLowerCase() ?? '';
      if (itemType == 'series' || itemType == 'tvshows') {
        tmdbType = 'tv';
      } else if (itemType == 'single') {
        tmdbType = 'movie';
      }
    }

    final existing = _hintsBySlug[rawSlug];
    _hintsBySlug[rawSlug] = TmdbMovieHint(
      slug: rawSlug,
      tmdbId: tmdbId ?? existing?.tmdbId,
      tmdbType: tmdbType ?? existing?.tmdbType,
      originName:
          (json['origin_name'] as String?)?.trim() ?? existing?.originName,
      title: (json['name'] as String? ?? json['title'] as String?)?.trim() ??
          existing?.title,
      year: json['year']?.toString() ?? existing?.year,
    );
  }

  /// Lấy nhanh từ bộ nhớ đệm nếu đã tải trước đó (không cần chờ bất đồng bộ).
  static Tmdb4kMedia? getCached(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    return _cacheBySlug[slug];
  }

  /// Tải bộ ảnh 4K (Backdrop 3840x2160 + Poster 2000x3000 + Logo PNG) từ TMDB theo slug.
  static Future<Tmdb4kMedia?> fetch4kForSlug(
    String? slug, {
    String? fallbackTitle,
  }) async {
    if (slug == null || slug.trim().isEmpty) return null;
    final key = slug.trim();

    if (_cacheBySlug.containsKey(key)) {
      return _cacheBySlug[key];
    }
    if (_inflight.containsKey(key)) {
      return _inflight[key]!;
    }

    final future = _resolveInternal(key, fallbackTitle: fallbackTitle);
    _inflight[key] = future;
    try {
      final result = await future;
      _cacheBySlug[key] = result;
      return result;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<Tmdb4kMedia?> _resolveInternal(
    String slug, {
    String? fallbackTitle,
  }) async {
    try {
      final hint = _hintsBySlug[slug];
      String? tmdbId = hint?.tmdbId;
      String tmdbType = hint?.tmdbType ?? 'movie';

      // Nếu nguồn phim chưa gắn sẵn tmdb.id thì tự động tìm trên TMDB bằng tên gốc
      if (tmdbId == null || tmdbId.isEmpty) {
        final searchQuery = (hint?.originName?.isNotEmpty == true)
            ? hint!.originName!
            : (hint?.title?.isNotEmpty == true ? hint!.title! : fallbackTitle);
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final found = await _searchTmdb(searchQuery.trim(), year: hint?.year);
          if (found != null && found.length == 2) {
            tmdbId = found[0];
            tmdbType = found[1];
          }
        }
      }

      if (tmdbId == null || tmdbId.isEmpty) return null;

      // Gọi /images (thử loại hiện tại trước, nếu 404 thì tự thử sang movie <-> tv)
      Map<String, dynamic>? imagesData =
          await _fetchImagesJson(tmdbType, tmdbId);
      if (imagesData == null) {
        final altType = tmdbType == 'movie' ? 'tv' : 'movie';
        imagesData = await _fetchImagesJson(altType, tmdbId);
      }
      if (imagesData == null) return null;

      return _pickBest4kAssets(imagesData);
    } catch (e) {
      log('TMDB 4K resolve error for $slug: $e');
      return null;
    }
  }

  static Future<List<String>?> _searchTmdb(
    String query, {
    String? year,
  }) async {
    try {
      final resp = await _dio.get(
        '/search/multi',
        queryParameters: {
          'api_key': _kTmdbApiKey,
          'query': query,
          'include_adult': false,
        },
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final results = (resp.data['results'] as List?) ?? const [];
        for (final item in results) {
          if (item is Map) {
            final mediaType = item['media_type']?.toString();
            final id = item['id']?.toString();
            if ((mediaType == 'movie' || mediaType == 'tv') &&
                id != null &&
                id.isNotEmpty) {
              return <String>[id, mediaType!];
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> _fetchImagesJson(
    String type,
    String id,
  ) async {
    try {
      final resp = await _dio.get(
        '/$type/$id/images',
        queryParameters: {
          'api_key': _kTmdbApiKey,
          'include_image_language': 'vi,en,null',
        },
      );
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        return resp.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Chấm điểm & chọn ra tấm Banner 4K (3840x2160), Poster Ultra-HD (2000x3000) và Logo PNG tốt nhất.
  static Tmdb4kMedia _pickBest4kAssets(Map<String, dynamic> data) {
    final backdrops = (data['backdrops'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final posters = (data['posters'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final logos = (data['logos'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    String? bestBackdropUrl;
    int bestW = 0;
    int bestH = 0;

    if (backdrops.isNotEmpty) {
      backdrops.sort((a, b) {
        final wA = (a['width'] as num?)?.toInt() ?? 0;
        final wB = (b['width'] as num?)?.toInt() ?? 0;
        // Ưu tiên hàng đầu các tấm đạt chuẩn 4K thực (width >= 3840 hoặc >= 3000)
        final tierA = wA >= 3840 ? 3 : (wA >= 2560 ? 2 : (wA >= 1920 ? 1 : 0));
        final tierB = wB >= 3840 ? 3 : (wB >= 2560 ? 2 : (wB >= 1920 ? 1 : 0));
        if (tierA != tierB) return tierB.compareTo(tierA);

        // Trong cùng phân khúc 4K, ưu tiên ảnh không chữ (iso_639_1 == null) để ghép Logo PNG cực đẹp
        final langA = a['iso_639_1'];
        final langB = b['iso_639_1'];
        final cleanA = langA == null ? 2 : (langA == 'vi' ? 1 : 0);
        final cleanB = langB == null ? 2 : (langB == 'vi' ? 1 : 0);
        if (cleanA != cleanB) return cleanB.compareTo(cleanA);

        final voteA = (a['vote_average'] as num?)?.toDouble() ?? 0;
        final voteB = (b['vote_average'] as num?)?.toDouble() ?? 0;
        if (voteA != voteB) return voteB.compareTo(voteA);

        return wB.compareTo(wA);
      });

      final top = backdrops.first;
      final path = top['file_path']?.toString() ?? '';
      if (path.isNotEmpty) {
        bestBackdropUrl = 'https://image.tmdb.org/t/p/original$path';
        bestW = (top['width'] as num?)?.toInt() ?? 0;
        bestH = (top['height'] as num?)?.toInt() ?? 0;
      }
    }

    String? bestPosterUrl;
    if (posters.isNotEmpty) {
      posters.sort((a, b) {
        final wA = (a['width'] as num?)?.toInt() ?? 0;
        final wB = (b['width'] as num?)?.toInt() ?? 0;
        final tierA = wA >= 2000 ? 2 : (wA >= 1000 ? 1 : 0);
        final tierB = wB >= 2000 ? 2 : (wB >= 1000 ? 1 : 0);
        if (tierA != tierB) return tierB.compareTo(tierA);

        final langA = a['iso_639_1'];
        final langB = b['iso_639_1'];
        final scoreLangA = langA == 'vi' ? 3 : (langA == 'en' ? 2 : 1);
        final scoreLangB = langB == 'vi' ? 3 : (langB == 'en' ? 2 : 1);
        if (scoreLangA != scoreLangB) return scoreLangB.compareTo(scoreLangA);

        final voteA = (a['vote_average'] as num?)?.toDouble() ?? 0;
        final voteB = (b['vote_average'] as num?)?.toDouble() ?? 0;
        return voteB.compareTo(voteA);
      });

      final topPoster = posters.first;
      final path = topPoster['file_path']?.toString() ?? '';
      if (path.isNotEmpty) {
        bestPosterUrl = 'https://image.tmdb.org/t/p/original$path';
      }
    }

    String? bestLogoUrl;
    if (logos.isNotEmpty) {
      final pngLogos = logos
          .where((l) =>
              (l['file_path']?.toString().toLowerCase().endsWith('.png') ??
                  false))
          .toList();
      final pool = pngLogos.isNotEmpty ? pngLogos : logos;
      pool.sort((a, b) {
        final langA = a['iso_639_1'];
        final langB = b['iso_639_1'];
        final sA = langA == 'vi' ? 3 : (langA == 'en' ? 2 : 1);
        final sB = langB == 'vi' ? 3 : (langB == 'en' ? 2 : 1);
        if (sA != sB) return sB.compareTo(sA);
        final wA = (a['width'] as num?)?.toInt() ?? 0;
        final wB = (b['width'] as num?)?.toInt() ?? 0;
        return wB.compareTo(wA);
      });
      final logoPath = pool.first['file_path']?.toString() ?? '';
      if (logoPath.isNotEmpty) {
        bestLogoUrl = 'https://image.tmdb.org/t/p/w500$logoPath';
      }
    }

    return Tmdb4kMedia(
      backdrop4kUrl: bestBackdropUrl,
      poster4kUrl: bestPosterUrl,
      logoUrl: bestLogoUrl,
      backdropWidth: bestW,
      backdropHeight: bestH,
    );
  }
}
