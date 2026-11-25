import 'package:json_annotation/json_annotation.dart';
import 'package:netflix_clone/infrastructure/tmdb/tmdb_4k_service.dart';
import '../../../../core/constants.dart';

part 'discover.g.dart';

@JsonSerializable()
class HotAndNewDataResp {
  @JsonKey(name: 'page')
  int? page;
  @JsonKey(name: 'results')
  List<HotAndNewData> results;

  HotAndNewDataResp({this.page, this.results = const []});

  factory HotAndNewDataResp.fromJson(Map<String, dynamic> json) {
    return _$HotAndNewDataRespFromJson(json);
  }

  factory HotAndNewDataResp.fromApiJson(Map<String, dynamic> json) {
    final responseData = json['data'] is Map ? json['data'] : json;
    final items = (responseData['items'] as List?) ?? (responseData['results'] as List?) ?? [];
    final pathImage = responseData['APP_DOMAIN_CDN_IMAGE'] as String? ?? responseData['pathImage'] as String? ?? '';
    final list = items.map((e) => HotAndNewData.fromApiJson(e as Map<String, dynamic>, pathImage)).toList();
    return HotAndNewDataResp(page: 1, results: list);
  }

  Map<String, dynamic> toJson() => _$HotAndNewDataRespToJson(this);
}

@JsonSerializable()
class HotAndNewData {
  bool? adult;
  @JsonKey(name: 'backdrop_path')
  String? backdropPath;
  @JsonKey(name: 'id')
  String? id;
  @JsonKey(name: 'original_language')
  String? originalLanguage;
  @JsonKey(name: 'original_title')
  String? originalTitle;
  // in cases of tv serices,use orgin name
  @JsonKey(name: 'original_name')
  String? originalName;
  @JsonKey(name: 'overview')
  String? overview;

  @JsonKey(name: 'poster_path')
  String? posterPath;
  @JsonKey(name: 'release_date')
  String? releaseDate;
  @JsonKey(name: 'title')
  String? title;

  HotAndNewData({
    this.adult,
    this.backdropPath,
    this.id,
    this.originalLanguage,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.releaseDate,
    this.title,
  });

  factory HotAndNewData.fromJson(Map<String, dynamic> json) {
    return _$HotAndNewDataFromJson(json);
  }

  factory HotAndNewData.fromApiJson(Map<String, dynamic> json, [String? cdn]) {
    Tmdb4kService.registerFromApiJson(json);
    final poster = resolveImageUrl(json['poster_url'], json['thumb_url'], cdn);
    final backdrop =
        resolveBackdropUrl(json['poster_url'], json['thumb_url'], cdn);
    return HotAndNewData(
      id: json['slug']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      originalTitle:
          json['origin_name'] as String? ?? json['name'] as String? ?? '',
      posterPath: poster,
      backdropPath: backdrop,
      overview: json['content'] as String? ?? '',
      releaseDate: json['year']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$HotAndNewDataToJson(this);
}
