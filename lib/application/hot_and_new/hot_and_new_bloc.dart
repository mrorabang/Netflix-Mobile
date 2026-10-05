import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:netflix_clone/domain/new_and_hot/hot_and_new_service.dart';
import 'package:netflix_clone/domain/new_and_hot/model/discover.dart';

import '../../domain/core/failures/main_failure.dart';

part 'hot_and_new_event.dart';
part 'hot_and_new_state.dart';
part 'hot_and_new_bloc.freezed.dart';

@injectable
class HotAndNewBloc extends Bloc<HotAndNewEvent, HotAndNewState> {
  final HotAndNewService _hotAndNewService;
  HotAndNewBloc(this._hotAndNewService) : super(HotAndNewState.initial()) {
    // get hot and new movie data
    on<LoadDataInComingSoon>((event, emit) async {
      emit(HotAndNewState(
          comingSoonList: state.comingSoonList,
          everyOneIsWatchingList: state.everyOneIsWatchingList,
          isLoading: true,
          hasError: false));
      final _result = await _hotAndNewService.getHotAndNewMovieData();
      final newState = _result.fold((MainFailure f) {
        return HotAndNewState(
            comingSoonList: state.comingSoonList,
            everyOneIsWatchingList: state.everyOneIsWatchingList,
            isLoading: false,
            hasError: state.comingSoonList.isEmpty);
      }, (HotAndNewDataResp resp) {
        return HotAndNewState(
            comingSoonList: resp.results,
            everyOneIsWatchingList: state.everyOneIsWatchingList,
            isLoading: false,
            hasError: false);
      });
      emit(newState);
    });
    // get hot and new tv data
    on<LoadDataInEveryOnesWatching>((event, emit) async {
      emit(HotAndNewState(
          comingSoonList: state.comingSoonList,
          everyOneIsWatchingList: state.everyOneIsWatchingList,
          isLoading: true,
          hasError: false));
      final _result = await _hotAndNewService.getHotAndNewTvData();
      final newState = _result.fold((MainFailure f) {
        return HotAndNewState(
            comingSoonList: state.comingSoonList,
            everyOneIsWatchingList: state.everyOneIsWatchingList,
            isLoading: false,
            hasError: state.everyOneIsWatchingList.isEmpty);
      }, (HotAndNewDataResp resp) {
        return HotAndNewState(
            comingSoonList: state.comingSoonList,
            everyOneIsWatchingList: resp.results,
            isLoading: false,
            hasError: false);
      });
      emit(newState);
    });
  }
}
