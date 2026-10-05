import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';

import '../../application/hot_and_new/hot_and_new_bloc.dart';
import '../search/screen_search.dart';
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
          preferredSize: const Size.fromHeight(95),
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              "Mới & Thịnh Hành",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.search,
                  size: 26,
                  color: kwhiteColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScreenSearch(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.cast,
                size: 24,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              kWidth,
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "🍿 Sắp Ra Mắt",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "🔥 Mọi Người Đang Xem",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
            ComingSoonWidgetList(
              key: Key('coming_soon'),
            ),
            EveryOnesWatchingWidgetList(
              key: Key('everyones_watching'),
            ),
          ],
        ),
      ),
    );
  }
}

class ComingSoonWidgetList extends StatelessWidget {
  const ComingSoonWidgetList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = BlocProvider.of<HotAndNewBloc>(context);
      if (bloc.state.comingSoonList.isEmpty) {
        bloc.add(const LoadDataInComingSoon());
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<HotAndNewBloc>(context)
            .add(const LoadDataInComingSoon());
      },
      child: BlocBuilder<HotAndNewBloc, HotAndNewState>(
        builder: (context, state) {
          if (state.isLoading && state.comingSoonList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            );
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
                    onPressed: () {
                      BlocProvider.of<HotAndNewBloc>(context)
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
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              itemCount: state.comingSoonList.length,
              itemBuilder: (BuildContext context, index) {
                final movie = state.comingSoonList[index];
                final rawDate = movie.releaseDate?.trim() ?? '';
                String year = '2024';
                String releaseInfo = 'Sắp ra mắt trên Netflix';

                if (rawDate.isNotEmpty) {
                  if (rawDate.contains('-')) {
                    final parts = rawDate.split('-');
                    year = parts[0];
                    if (parts.length >= 3) {
                      releaseInfo = 'Khởi chiếu ${parts[2]}/${parts[1]}/${parts[0]}';
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
                    : (movie.originalTitle ?? 'Phim Netflix');

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

class EveryOnesWatchingWidgetList extends StatelessWidget {
  const EveryOnesWatchingWidgetList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = BlocProvider.of<HotAndNewBloc>(context);
      if (bloc.state.everyOneIsWatchingList.isEmpty) {
        bloc.add(const LoadDataInEveryOnesWatching());
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        BlocProvider.of<HotAndNewBloc>(context)
            .add(const LoadDataInEveryOnesWatching());
      },
      child: BlocBuilder<HotAndNewBloc, HotAndNewState>(
        builder: (context, state) {
          if (state.isLoading && state.everyOneIsWatchingList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            );
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
                    onPressed: () {
                      BlocProvider.of<HotAndNewBloc>(context)
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
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: state.everyOneIsWatchingList.length,
              itemBuilder: (BuildContext context, index) {
                final tv = state.everyOneIsWatchingList[index];
                final image = resolveImageUrl(
                  tv.backdropPath,
                  tv.posterPath,
                );
                final title = (tv.title != null && tv.title!.isNotEmpty)
                    ? tv.title!
                    : (tv.originalTitle ?? 'Phim Netflix');

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
