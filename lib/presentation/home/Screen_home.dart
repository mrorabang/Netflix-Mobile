import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/home/home_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/home/widget/background_card.dart';
import 'package:netflix_clone/presentation/widget/main_title_card.dart';

// ignore: must_be_immutable
class ScreenHome extends StatelessWidget {
  ScreenHome({Key? key}) : super(key: key);

  final ValueNotifier<bool> scrollNotifier = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      BlocProvider.of<HomeBloc>(context).add(const GetHomeScreenData());
    });
    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: scrollNotifier,
        builder: (BuildContext context, isScrollingUp, _) {
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final ScrollDirection direction = notification.direction;
              if (direction == ScrollDirection.reverse) {
                scrollNotifier.value = false;
              } else if (direction == ScrollDirection.forward) {
                scrollNotifier.value = true;
              }
              return true;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                BlocProvider.of<HomeBloc>(context)
                    .add(const GetHomeScreenData());
              },
              child: Stack(
                children: [
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        );
                      } else if (state.hasError) {
                        return const Center(
                          child: Text(
                            "Lỗi khi tải dữ liệu phim",
                            style: TextStyle(color: kwhiteColor),
                          ),
                        );
                      }

                      // released past year (phim le)
                      final releasedPastYear = state.pastYearMovieList.map((m) {
                        return resolveImageUrl(m.posterPath, null);
                      }).toList();
                      final releasedPastYearId = state.pastYearMovieList.map((m) {
                        return m.id;
                      }).toList();
                      final releasedPastYearTitles =
                          state.pastYearMovieList.map((m) => m.title).toList();
                      final releasedPastYearYears = state.pastYearMovieList
                          .map((m) => m.releaseDate)
                          .toList();

                      // trending (phim moi cap nhat)
                      final trending = state.trendingMovieList.map((m) {
                        return resolveImageUrl(m.posterPath, null);
                      }).toList();
                      final trendingId = state.trendingMovieList.map((m) {
                        return m.id;
                      }).toList();
                      final trendingTitles =
                          state.trendingMovieList.map((m) => m.title).toList();
                      final trendingYears = state.trendingMovieList
                          .map((m) => m.releaseDate)
                          .toList();

                      // phim bo
                      final trendse = state.tenseDramaMovieList.map((m) {
                        return resolveImageUrl(m.posterPath, null);
                      }).toList();
                      final trendsId = state.tenseDramaMovieList.map((m) {
                        return m.id;
                      }).toList();
                      final trendsTitles = state.tenseDramaMovieList
                          .map((m) => m.title)
                          .toList();
                      final trendsYears = state.tenseDramaMovieList
                          .map((m) => m.releaseDate)
                          .toList();

                      // kham pha
                      final southIndia = state.southIndianMovieList.map((m) {
                        return resolveImageUrl(m.posterPath, null);
                      }).toList();
                      final southIndiaId = state.southIndianMovieList.map((m) {
                        return m.id;
                      }).toList();
                      final southIndiaTitles = state.southIndianMovieList
                          .map((m) => m.title)
                          .toList();
                      final southIndiaYears = state.southIndianMovieList
                          .map((m) => m.releaseDate)
                          .toList();

                      // top tv shows
                      final top10List = state.trendingTvList.take(10).toList();
                      final top10tvShows = top10List.map((m) {
                        return resolveImageUrl(m.posterPath, null);
                      }).toList();
                      final top10tvId = top10List.map((m) => m.id).toList();
                      final top10tvTitles =
                          top10List.map((m) => m.title).toList();
                      final top10tvYears =
                          top10List.map((m) => m.releaseDate).toList();

                      final heroMovie = state.trendingMovieList.isNotEmpty
                          ? state.trendingMovieList.first
                          : null;

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          BackgroundCard(
                            imageUrl: heroMovie?.posterPath,
                            title: heroMovie?.title,
                            movieId: heroMovie?.id,
                          ),
                          kHeight,
                          MainTitleCard(
                            id: trendingId,
                            title: "Phim Mới Cập Nhật",
                            posterList: trending,
                            titles: trendingTitles,
                            releaseDates: trendingYears,
                          ),
                          kHeight,
                          MainTitleCard(
                            id: releasedPastYearId,
                            title: "Phim Lẻ Chiếu Rạp",
                            posterList: releasedPastYear,
                            titles: releasedPastYearTitles,
                            releaseDates: releasedPastYearYears,
                          ),
                          kHeight,
                          if (top10tvShows.isNotEmpty)
                            MainTitleCard(
                              id: top10tvId,
                              title: "Top 10 Phim Bộ Hay Nhất",
                              posterList: top10tvShows,
                              titles: top10tvTitles,
                              releaseDates: top10tvYears,
                            ),
                          kHeight,
                          MainTitleCard(
                            id: trendsId,
                            title: "Phim Đang Thịnh Hành",
                            posterList: trendse,
                            titles: trendsTitles,
                            releaseDates: trendsYears,
                          ),
                          kHeight,
                          MainTitleCard(
                            id: southIndiaId,
                            title: "Được Đề Xuất Cho Bạn",
                            posterList: southIndia,
                            titles: southIndiaTitles,
                            releaseDates: southIndiaYears,
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    top: isScrollingUp ? 0 : -110,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Image.network(
                                    'https://cdn-images-1.medium.com/max/1200/1*ty4NvNrGg4ReETxqU2N3Og.png',
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Text(
                                      "NETFLIX",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.cast,
                                    size: 26,
                                    color: kwhiteColor,
                                  ),
                                  kWidth,
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.red[700],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "N",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Phim Bộ",
                                  style: kHomeTitleText,
                                ),
                                Text(
                                  "Phim Lẻ",
                                  style: kHomeTitleText,
                                ),
                                Text(
                                  "Thể Loại",
                                  style: kHomeTitleText,
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
