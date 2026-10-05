import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/constants.dart';

part 'downloads.freezed.dart';
part 'downloads.g.dart';

@freezed
class Downloads with _$Downloads {
  const factory Downloads({
    @JsonKey(name: "poster_path") required String? posterPath,
    @JsonKey(name: "id") required String? id,
    @JsonKey(name: "title") required String? title,
  }) = _Downloads;

  factory Downloads.fromJson(Map<String, dynamic> json) =>
      _$DownloadsFromJson(json);

  factory Downloads.fromApiJson(Map<String, dynamic> json, [String? cdn]) {
    final poster = resolveImageUrl(json['poster_url'], json['thumb_url'], cdn);
    return Downloads(
      posterPath: poster,
      id: json['slug']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['name'] as String? ?? json['title'] as String? ?? '',
    );
  }
}
