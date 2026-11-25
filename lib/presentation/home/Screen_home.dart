import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/home/home_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/category/screen_category_movies.dart';
import 'package:netflix_clone/presentation/home/widget/background_card.dart';
import 'package:netflix_clone/presentation/home/widget/number_title_card.dart';
import 'package:netflix_clone/presentation/search/screen_search.dart';
import 'package:netflix_clone/presentation/widget/main_title_card.dart';
import 'package:netflix_clone/presentation/widgets/cast_modal.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({Key? key}) : super(key: key);

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  final ValueNotifier<bool> _showTopBar = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<HomeBloc>();
      if (bloc.state.trendingMovieList.isEmpty && !bloc.state.isLoading) {
        bloc.add(const GetHomeScreenData());
      }
    });
  }

  @override
  void dispose() {
    _showTopBar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;
          final direction = notification.direction;
          if (direction == ScrollDirection.reverse && _showTopBar.value) {
            if (notification.metrics.pixels > 60) {
              _showTopBar.value = false;
            }
          } else if (direction == ScrollDirection.forward &&
              !_showTopBar.value) {
            _showTopBar.value = true;
          }
          return false;
        },
        child: Stack(
          children: [
            RefreshIndicator(
              color: kNetflixRed,
              backgroundColor: kSurfaceColor,
              edgeOffset: 90,
              onRefresh: () async {
                context.read<HomeBloc>().add(const GetHomeScreenData());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state.isLoading && state.trendingMovieList.isEmpty) {
                    return const HomeShimmerSkeleton();
                  } else if (state.hasError && state.trendingMovieList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Color(0xFF7E7E8F),
                              size: 52,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              "Không thể kết nối máy chủ phim",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Kiểm tra kết nối mạng và kéo xuống hoặc nhấn nút bên dưới để tải lại.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kGray, fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            ScaleTap(
                              onTap: () {
                                context
                                    .read<HomeBloc>()
                                    .add(const GetHomeScreenData());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 11),
                                decoration: BoxDecoration(
                                  color: kNetflixRed,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  "Thử lại ngay",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final releasedPastYear = state.pastYearMovieList
                      .map((m) => resolveImageUrl(m.posterPath, null))
                      .toList();
                  final releasedPastYearId =
                      state.pastYearMovieList.map((m) => m.id).toList();
                  final releasedPastYearTitles =
                      state.pastYearMovieList.map((m) => m.title).toList();
                  final releasedPastYearYears = state.pastYearMovieList
                      .map((m) => m.releaseDate)
                      .toList();

                  final trending = state.trendingMovieList
                      .map((m) => resolveImageUrl(m.posterPath, null))
                      .toList();
                  final trendingId =
                      state.trendingMovieList.map((m) => m.id).toList();
                  final trendingTitles =
                      state.trendingMovieList.map((m) => m.title).toList();
                  final trendingYears = state.trendingMovieList
                      .map((m) => m.releaseDate)
                      .toList();

                  final trendse = state.tenseDramaMovieList
                      .map((m) => resolveImageUrl(m.posterPath, null))
                      .toList();
                  final trendsId =
                      state.tenseDramaMovieList.map((m) => m.id).toList();
                  final trendsTitles =
                      state.tenseDramaMovieList.map((m) => m.title).toList();
                  final trendsYears = state.tenseDramaMovieList
                      .map((m) => m.releaseDate)
                      .toList();

                  final southIndia = state.southIndianMovieList
                      .map((m) => resolveImageUrl(m.posterPath, null))
                      .toList();
                  final southIndiaId =
                      state.southIndianMovieList.map((m) => m.id).toList();
                  final southIndiaTitles =
                      state.southIndianMovieList.map((m) => m.title).toList();
                  final southIndiaYears = state.southIndianMovieList
                      .map((m) => m.releaseDate)
                      .toList();

                  final top10List = state.trendingTvList.take(10).toList();
                  final top10tvShows = top10List
                      .map((m) => resolveImageUrl(m.posterPath, null))
                      .toList();
                  final top10tvId = top10List.map((m) => m.id).toList();
                  final top10tvTitles = top10List.map((m) => m.title).toList();

                  final heroMovie = state.trendingMovieList.isNotEmpty
                      ? state.trendingMovieList.first
                      : null;

                  return ListView(
                    padding: EdgeInsets.zero,
                    cacheExtent: 900,
                    children: [
                      BackgroundCard(
                        imageUrl: heroMovie?.posterPath,
                        title: heroMovie?.title,
                        movieId: heroMovie?.id,
                      ),
                      const SizedBox(height: 18),
                      MainTitleCard(
                        id: trendingId,
                        title: "Phim Mới Cập Nhật",
                        posterList: trending,
                        titles: trendingTitles,
                        releaseDates: trendingYears,
                      ),
                      const SizedBox(height: 16),
                      if (top10tvShows.isNotEmpty) ...[
                        NumberTitleCard(
                          title: "Top 10 Phim Bộ Hôm Nay",
                          posterList: top10tvShows,
                          ids: top10tvId,
                          titles: top10tvTitles,
                        ),
                        const SizedBox(height: 18),
                      ],
                      MainTitleCard(
                        id: releasedPastYearId,
                        title: "Phim Lẻ Chiếu Rạp",
                        posterList: releasedPastYear,
                        titles: releasedPastYearTitles,
                        releaseDates: releasedPastYearYears,
                      ),
                      const SizedBox(height: 16),
                      MainTitleCard(
                        id: trendsId,
                        title: "Phim Bộ Đang Thịnh Hành",
                        posterList: trendse,
                        titles: trendsTitles,
                        releaseDates: trendsYears,
                      ),
                      const SizedBox(height: 16),
                      MainTitleCard(
                        id: southIndiaId,
                        title: "Được Đề Xuất Cho Bạn",
                        posterList: southIndia,
                        titles: southIndiaTitles,
                        releaseDates: southIndiaYears,
                      ),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),

            // Thanh Header Kính Mờ trượt mượt mà mà không gây relayout danh sách bên dưới
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showTopBar,
                builder: (context, visible, child) {
                  return AnimatedSlide(
                    offset: visible ? Offset.zero : const Offset(0, -1.05),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: child,
                    ),
                  );
                },
                child: _buildFloatingHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xEB0A0A0E),
                  Color(0xC70A0A0E),
                  Color(0x000A0A0E),
                ],
                stops: [0.0, 0.72, 1.0],
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/netflix_logo.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            "N",
                            style: TextStyle(
                              color: kNetflixRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Nét Lích",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        ScaleTap(
                          onTap: () {
                            Navigator.push(
                              context,
                              netflixRoute(const ScreenSearch()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              CupertinoIcons.search,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ScaleTap(
                          onTap: () => showCastBottomSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.cast_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFFB20710)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "N",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        _buildCategoryPill(
                          label: "Phim Bộ",
                          onTap: () {
                            Navigator.push(
                              context,
                              netflixRoute(
                                const ScreenCategoryMovies(
                                  initialTitle: "Phim Bộ",
                                  type: CategoryType.phimBo,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryPill(
                          label: "Phim Lẻ",
                          onTap: () {
                            Navigator.push(
                              context,
                              netflixRoute(
                                const ScreenCategoryMovies(
                                  initialTitle: "Phim Lẻ",
                                  type: CategoryType.phimLe,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryPill(
                          label: "Thể Loại",
                          hasDropdown: true,
                          onTap: () => showTheLoaiBottomSheet(context),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryPill(
                          label: "Quốc Gia",
                          hasDropdown: true,
                          onTap: () => showQuocGiaBottomSheet(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required VoidCallback onTap,
    bool hasDropdown = false,
  }) {
    return ScaleTap(
      pressedScale: 0.94,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0x38FFFFFF),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
