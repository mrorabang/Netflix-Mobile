import 'package:json_annotation/json_annotation.dart';
import '../../../../core/constants.dart';

part 'description_resp.g.dart';

class EpisodeItemModel {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;

  EpisodeItemModel({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
  });

  factory EpisodeItemModel.fromJson(Map<String, dynamic> json) {
    return EpisodeItemModel(
      name: json['name'] as String? ?? 'Full',
      slug: json['slug'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      linkEmbed: json['link_embed'] as String? ?? '',
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
    final movie = json['movie'] as Map<String, dynamic>? ?? {};
    final episodesRaw = json['episodes'] as List? ?? [];
    List<EpisodeItemModel> epList = [];
    if (episodesRaw.isNotEmpty) {
      final firstServer = episodesRaw[0] as Map<String, dynamic>? ?? {};
      final serverData = firstServer['server_data'] as List? ?? [];
      epList = serverData.map((e) => EpisodeItemModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    final poster = resolveImageUrl(movie['poster_url'], movie['thumb_url']);
    final double? vote = double.tryParse(movie['tmdb']?['vote_average']?.toString() ?? '');

    final quality = movie['quality'] as String? ?? 'HD';
    final lang = movie['lang'] as String? ?? 'Vietsub';
    final time = movie['time'] as String? ?? '';
    final statusStr = [quality, lang, if (time.isNotEmpty) '${time}m'].where((s) => s.isNotEmpty).join(' • ');

    return DescriptionResp(
      id: 0,
      title: movie['name'] as String? ?? '',
      originalTitle: movie['origin_name'] as String? ?? '',
      overview: movie['content'] as String? ?? '',
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
