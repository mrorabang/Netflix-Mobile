import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/home/home_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/home/Screen_home.dart';
import 'package:netflix_clone/presentation/main_page/widgets/bottom_nav.dart';
import 'package:netflix_clone/presentation/main_page/widgets/tv_side_nav.dart';
import 'package:netflix_clone/presentation/new_and_hot/screen_new_and_hot.dart';
import 'package:netflix_clone/presentation/search/screen_search.dart';
import 'package:netflix_clone/presentation/watch_party/screen_watch_party_lobby.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class ScreenMainPage extends StatefulWidget {
  const ScreenMainPage({Key? key}) : super(key: key);

  @override
  State<ScreenMainPage> createState() => _ScreenMainPageState();
}

class _ScreenMainPageState extends State<ScreenMainPage> {
  late final List<Widget> _pages = const [
    ScreenHome(key: PageStorageKey('home_screen')),
    ScreenNewAndHot(key: PageStorageKey('new_and_hot_screen')),
    ScreenSearch(
      key: PageStorageKey('search_tab_screen'),
      isEmbeddedTab: true,
    ),
    ScreenWatchPartyLobby(
      key: PageStorageKey('party_tab_screen'),
      isEmbeddedTab: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final homeBloc = context.read<HomeBloc>();
      if (homeBloc.state.trendingMovieList.isEmpty) {
        homeBloc.add(const GetHomeScreenData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTv = TvMode.isTv(context);

    final pageBody = ValueListenableBuilder<int>(
      valueListenable: indexChangeNotifier,
      builder: (context, index, _) {
        final safeIndex = index.clamp(0, _pages.length - 1);
        return IndexedStack(
          index: safeIndex,
          children: _pages,
        );
      },
    );

    if (isTv) {
      return Scaffold(
        backgroundColor: backgrounndColor,
        body: Row(
          children: [
            const TvSideNavigationRail(),
            Expanded(child: pageBody),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgrounndColor,
      extendBody: true,
      body: pageBody,
      bottomNavigationBar: const BottomNaviagtionWidget(),
    );
  }
}
