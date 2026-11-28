import 'package:json_annotation/json_annotation.dart';
import 'package:netflix_clone/infrastructure/tmdb/tmdb_4k_service.dart';
import '../../../../core/constants.dart';

part 'description_resp.g.dart';

class EpisodeItemModel {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  EpisodeItemModel({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    this.linkM3u8 = '',
  });

  String get streamUrl => linkM3u8.isNotEmpty ? linkM3u8 : linkEmbed;

  factory EpisodeItemModel.fromJson(Map<String, dynamic> json) {
    final m3u8 = (json['link_m3u8'] as String? ?? '').trim();
    String link = (json['link_embed'] as String? ?? '').trim();
    if (link.isEmpty) {
      link = m3u8;
    }
    return EpisodeItemModel(
      name: (json['name'] as String? ?? 'Full').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      filename: (json['filename'] as String? ?? '').trim(),
      linkEmbed: link,
      linkM3u8: m3u8,
    );
  }
}

@JsonSerializable()
class DescriptionResp {
  bool? adult;
  @JsonKey(name: 'backdrop_path')
  String? backdropPath;

  int? budget;

  String? homepage;
  int? id;
  @JsonKey(name: 'imdb_id')
  String? imdbId;
  @JsonKey(name: 'original_language')
  String? originalLanguage;
  @JsonKey(name: 'original_title')
  String? originalTitle;
  String? overview;
  double? popularity;
  @JsonKey(name: 'poster_path')
  String? posterPath;
  @JsonKey(name: 'release_date')
  String? releaseDate;
  int? revenue;
  int? runtime;

  String? status;
  String? tagline;
  String? title;
  bool? video;
  @JsonKey(name: 'vote_average')
  double? voteAverage;
  @JsonKey(name: 'vote_count')
  int? voteCount;

  @JsonKey(ignore: true)
  List<EpisodeItemModel> episodeList;

  DescriptionResp({
    this.adult,
    this.backdropPath,
    this.budget,
    this.homepage,
    this.id,
    this.imdbId,
    this.originalLanguage,
    this.originalTitle,
    this.overview,
    this.popularity,
    this.posterPath,
    this.releaseDate,
    this.revenue,
    this.runtime,
    this.status,
    this.tagline,
    this.title,
    this.video,
    this.voteAverage,
    this.voteCount,
    this.episodeList = const [],
  });

  factory DescriptionResp.fromJson(Map<String, dynamic> json) {
    return _$DescriptionRespFromJson(json);
  }

  factory DescriptionResp.fromApiJson(Map<String, dynamic> json) {
    final movie = (json['movie'] as Map<String, dynamic>?) ??
        (json['data'] is Map ? (json['data']['item'] as Map<String, dynamic>?) : null) ??
        {};
    if (movie.isNotEmpty) {
      Tmdb4kService.registerFromApiJson(movie);
    }
    final episodesRaw = (json['episodes'] as List?) ??
        (json['data'] is Map ? (json['data']['episodes'] as List?) : null) ??
        [];
    List<EpisodeItemModel> epList = [];

    // Search all servers to find one that has episodes with links
    for (final srv in episodesRaw) {
      if (srv is Map<String, dynamic>) {
        final serverData = srv['server_data'] as List? ?? [];
        final items = serverData
            .whereType<Map<String, dynamic>>()
            .map((e) => EpisodeItemModel.fromJson(e))
            .where((ep) => ep.linkEmbed.isNotEmpty)
            .toList();
        if (items.isNotEmpty) {
          epList = items;
          break;
        }
      }
    }

    // If still empty, check for trailer_url
    final trailer = (movie['trailer_url'] as String? ?? '').trim();
    if (epList.isEmpty && trailer.isNotEmpty) {
      epList.add(EpisodeItemModel(
        name: 'Trailer',
        slug: 'trailer',
        filename: 'Trailer',
        linkEmbed: trailer,
      ));
    }

    // Clean HTML from overview
    String rawContent = (movie['content'] as String? ?? '').trim();
    rawContent = rawContent
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final cdn = json['APP_DOMAIN_CDN_IMAGE'] as String? ??
        (json['data'] is Map ? json['data']['APP_DOMAIN_CDN_IMAGE'] as String? : null) ??
        (movie['poster_url']?.toString().startsWith('http') == true
            ? null
            : 'https://phimimg.com');

    final poster = resolveImageUrl(movie['poster_url'], movie['thumb_url'], cdn);
    final double? vote = double.tryParse(movie['tmdb']?['vote_average']?.toString() ?? '');

    final quality = movie['quality'] as String? ?? 'HD';
    final lang = movie['lang'] as String? ?? 'Vietsub';
    String time = (movie['time'] as String? ?? '').trim();
    if (time.isNotEmpty && !time.contains('phút') && !time.endsWith('m')) {
      time = '${time}m';
    }
    final statusStr = [quality, lang, time].where((s) => s.isNotEmpty).join(' • ');

    return DescriptionResp(
      id: 0,
      title: (movie['name'] as String? ?? movie['title'] as String? ?? '').trim(),
      originalTitle: (movie['origin_name'] as String? ?? '').trim(),
      overview: rawContent,
      posterPath: poster,
      backdropPath: poster,
      releaseDate: movie['year']?.toString() ?? '',
      status: statusStr,
      voteAverage: vote ?? 8.5,
      episodeList: epList,
    );
  }

  Map<String, dynamic> toJson() => _$DescriptionRespToJson(this);
}
