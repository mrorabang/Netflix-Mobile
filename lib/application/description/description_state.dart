part of 'description_bloc.dart';

@freezed
class DescriptionState with _$DescriptionState {
  const factory DescriptionState(
      {required String title,
      required String overview,
      required String posterPath,
      required String relaseDate,
      required String status,
      required double voteAverage,
      required bool isLoading,
      required bool isError,
      @Default([]) List<EpisodeItemModel> episodeList}) = _Initial;
  factory DescriptionState.initial() => const DescriptionState(
        title: "",
        overview: "",
        posterPath: "",
        relaseDate: "",
        status: "",
        voteAverage: 0,
        isLoading: false,
        isError: false,
        episodeList: [],
      );
}
