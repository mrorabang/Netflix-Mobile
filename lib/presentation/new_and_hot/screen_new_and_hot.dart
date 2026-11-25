import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

import '../../application/hot_and_new/hot_and_new_bloc.dart';
import '../search/screen_search.dart';
import '../widgets/cast_modal.dart';
import 'widget/coming_soon_widget.dart';
import 'widget/everyones_watching_widget.dart';

class ScreenNewAndHot extends StatelessWidget {
  const ScreenNewAndHot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgrounndColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(98),
          child: AppBar(
            backgroundColor: backgrounndColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              "Mới & Thịnh Hành",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
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
              const SizedBox(width: 16),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Colors.black,
                    unselectedLabelColor: const Color(0xFFD0D0DC),
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        height: 34,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "🍿 Sắp Ra Mắt",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        height: 34,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "🔥 Mọi Người Đang Xem",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ComingSoonWidgetList(key: PageStorageKey('coming_soon')),
            EveryOnesWatchingWidgetList(
                key: PageStorageKey('everyones_watching')),
          ],
        ),
      ),
    );
  }
}

Widget _buildFeedSkeleton() {
  return ListView.builder(
    padding: const EdgeInsets.only(top: 10, bottom: 100),
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 3,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 196, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerBox(width: 190, height: 18, borderRadius: 4),
          SizedBox(height: 8),
          ShimmerBox(height: 13, borderRadius: 4),
          SizedBox(height: 5),
          ShimmerBox(width: 240, height: 13, borderRadius: 4),
        ],
      ),
    ),
  );
}

class ComingSoonWidgetList extends StatefulWidget {
  const ComingSoonWidgetList({Key? key}) : super(key: key);

  @override
  State<ComingSoonWidgetList> createState() => _ComingSoonWidgetListState();
}

class _ComingSoonWidgetListState extends State<ComingSoonWidgetList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<HotAndNewBloc>();
      if (bloc.state.comingSoonList.isEmpty && !bloc.state.isLoading) {
        bloc.add(const LoadDataInComingSoon());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kNetflixRed,
      backgroundColor: kSurfaceColor,
      onRefresh: () async {
        context.read<HotAndNewBloc>().add(const LoadDataInComingSoon());
        await Future.delayed(const Duration(milliseconds: 450));
      },
      child: BlocBuilder<HotAndNewBloc, HotAndNewState>(
        builder: (context, state) {
          if (state.isLoading && state.comingSoonList.isEmpty) {
            return _buildFeedSkeleton();
          } else if (state.hasError && state.comingSoonList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Không thể tải danh sách phim",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNetflixRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context
                          .read<HotAndNewBloc>()
                          .add(const LoadDataInComingSoon());
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          } else if (state.comingSoonList.isEmpty) {
            return const Center(
              child: Text(
                "Danh sách đang cập nhật",
                style: TextStyle(color: kGray),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              cacheExtent: 800,
              itemCount: state.comingSoonList.length,
              itemBuilder: (BuildContext context, index) {
                final movie = state.comingSoonList[index];
                final rawDate = movie.releaseDate?.trim() ?? '';
                String year = '2026';
                String releaseInfo = 'Sắp ra mắt trên Nét Lích';

                if (rawDate.isNotEmpty) {
                  if (rawDate.contains('-')) {
                    final parts = rawDate.split('-');
                    year = parts[0];
                    if (parts.length >= 3) {
                      releaseInfo =
                          'Khởi chiếu ${parts[2]}/${parts[1]}/${parts[0]}';
                    } else if (parts.length >= 2) {
                      releaseInfo = 'Khởi chiếu tháng ${parts[1]}/${parts[0]}';
                    }
                  } else {
                    year = rawDate;
                  }
                }

                final image = resolveImageUrl(
                  movie.backdropPath,
                  movie.posterPath,
                );
                final title = (movie.title != null && movie.title!.isNotEmpty)
                    ? movie.title!
                    : (movie.originalTitle ?? 'Phim Nét Lích');

                return ComingSoonWidget(
                  id: movie.id ?? '',
                  year: year,
                  releaseInfo: releaseInfo,
                  posterPath: image,
                  movieName: title,
                  decription: movie.overview ?? '',
                );
              },
            );
          }
        },
      ),
    );
  }
}

class EveryOnesWatchingWidgetList extends StatefulWidget {
  const EveryOnesWatchingWidgetList({Key? key}) : super(key: key);

  @override
  State<EveryOnesWatchingWidgetList> createState() =>
      _EveryOnesWatchingWidgetListState();
}

class _EveryOnesWatchingWidgetListState
    extends State<EveryOnesWatchingWidgetList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<HotAndNewBloc>();
      if (bloc.state.everyOneIsWatchingList.isEmpty && !bloc.state.isLoading) {
        bloc.add(const LoadDataInEveryOnesWatching());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kNetflixRed,
      backgroundColor: kSurfaceColor,
      onRefresh: () async {
        context.read<HotAndNewBloc>().add(const LoadDataInEveryOnesWatching());
        await Future.delayed(const Duration(milliseconds: 450));
      },
      child: BlocBuilder<HotAndNewBloc, HotAndNewState>(
        builder: (context, state) {
          if (state.isLoading && state.everyOneIsWatchingList.isEmpty) {
            return _buildFeedSkeleton();
          } else if (state.hasError && state.everyOneIsWatchingList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Không thể tải danh sách phim",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNetflixRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      context
                          .read<HotAndNewBloc>()
                          .add(const LoadDataInEveryOnesWatching());
                    },
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          } else if (state.everyOneIsWatchingList.isEmpty) {
            return const Center(
              child: Text(
                "Danh sách đang cập nhật",
                style: TextStyle(color: kGray),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              cacheExtent: 800,
              itemCount: state.everyOneIsWatchingList.length,
              itemBuilder: (BuildContext context, index) {
                final tv = state.everyOneIsWatchingList[index];
                final image = resolveImageUrl(
                  tv.backdropPath,
                  tv.posterPath,
                );
                final title = (tv.title != null && tv.title!.isNotEmpty)
                    ? tv.title!
                    : (tv.originalTitle ?? 'Phim Nét Lích');

                return EveryOnesWatchingWidget(
                  id: tv.id ?? '',
                  posterPath: image,
                  movieName: title,
                  decription: tv.overview ?? '',
                );
              },
            );
          }
        },
      ),
    );
  }
}
