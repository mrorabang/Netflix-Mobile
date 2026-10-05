import 'package:json_annotation/json_annotation.dart';

import '../../../../core/constants.dart';

part 'search_resp.g.dart';

@JsonSerializable()
class SearchResp {
  @JsonKey(name: 'results')
  List<SearchResultData> results;

  SearchResp({this.results = const []});

  factory SearchResp.fromJson(Map<String, dynamic> json) {
    return _$SearchRespFromJson(json);
  }

  factory SearchResp.fromApiJson(Map<String, dynamic> json) {
    final responseData = json['data'] is Map ? json['data'] : json;
    final items = (responseData['items'] as List?) ?? (responseData['results'] as List?) ?? [];
    final pathImage = responseData['APP_DOMAIN_CDN_IMAGE'] as String? ?? responseData['pathImage'] as String? ?? '';
    final list = items.map((e) => SearchResultData.fromApiJson(e as Map<String, dynamic>, pathImage)).toList();
    return SearchResp(results: list);
  }

  Map<String, dynamic> toJson() => _$SearchRespToJson(this);
}

@JsonSerializable()
class SearchResultData {
  @JsonKey(name: 'id')
  String? id;

  @JsonKey(name: 'original_title')
  String? originalTitle;
  @JsonKey(name: 'poster_path')
  String? posterPath;
  @JsonKey(ignore: true)
  String? type;
  @JsonKey(ignore: true)
  int? year;
  @JsonKey(ignore: true)
  String? quality;
  @JsonKey(ignore: true)
  String? episodeCurrent;
  @JsonKey(ignore: true)
  List<String> categories;
  @JsonKey(ignore: true)
  List<String> countries;

  String get posterImageUrl => resolveImageUrl(posterPath, null);

  SearchResultData({
    this.id,
    this.originalTitle,
    this.posterPath,
    this.type,
    this.year,
    this.quality,
    this.episodeCurrent,
    this.categories = const [],
    this.countries = const [],
  });

  factory SearchResultData.fromJson(Map<String, dynamic> json) {
    return _$SearchResultDataFromJson(json);
  }

  factory SearchResultData.fromApiJson(Map<String, dynamic> json, [String? cdn]) {
    final poster = resolveImageUrl(json['poster_url'], json['thumb_url'], cdn);
    
    final rawCats = json['category'];
    List<String> cats = [];
    if (rawCats is List) {
      for (var c in rawCats) {
        if (c is Map) {
          if (c['slug'] != null) cats.add(c['slug'].toString());
          if (c['name'] != null) cats.add(c['name'].toString());
        }
      }
    }

    final rawCountries = json['country'];
    List<String> countrs = [];
    if (rawCountries is List) {
      for (var c in rawCountries) {
        if (c is Map) {
          if (c['slug'] != null) countrs.add(c['slug'].toString());
          if (c['name'] != null) countrs.add(c['name'].toString());
        }
      }
    }

    int? parsedYear;
    if (json['year'] is int) {
      parsedYear = json['year'] as int;
    } else if (json['year'] != null) {
      parsedYear = int.tryParse(json['year'].toString());
    }

    return SearchResultData(
      id: json['slug']?.toString() ?? json['_id']?.toString() ?? '',
      originalTitle: json['name'] as String? ?? json['title'] as String? ?? '',
      posterPath: poster,
      type: json['type'] as String?,
      year: parsedYear,
      quality: json['quality'] as String?,
      episodeCurrent: json['episode_current'] as String?,
      categories: cats,
      countries: countrs,
    );
  }

  Map<String, dynamic> toJson() => _$SearchResultDataToJson(this);
}
