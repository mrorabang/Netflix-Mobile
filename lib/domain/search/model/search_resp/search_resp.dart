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

  String get posterImageUrl => resolveImageUrl(posterPath, null);

  SearchResultData({
    this.id,
    this.originalTitle,
    this.posterPath,
  });

  factory SearchResultData.fromJson(Map<String, dynamic> json) {
    return _$SearchResultDataFromJson(json);
  }

  factory SearchResultData.fromApiJson(Map<String, dynamic> json, [String? cdn]) {
    final poster = resolveImageUrl(json['poster_url'], json['thumb_url'], cdn);
    return SearchResultData(
      id: json['slug']?.toString() ?? json['_id']?.toString() ?? '',
      originalTitle: json['name'] as String? ?? json['title'] as String? ?? '',
      posterPath: poster,
    );
  }

  Map<String, dynamic> toJson() => _$SearchResultDataToJson(this);
}
