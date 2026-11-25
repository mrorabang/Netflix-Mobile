import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/downloads/downloads_bloc.dart';
import 'package:netflix_clone/application/home/home_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/downloads/widgets/screen_downloads.dart';
import 'package:netflix_clone/presentation/home/Screen_home.dart';
import 'package:netflix_clone/presentation/main_page/widgets/bottom_nav.dart';
import 'package:netflix_clone/presentation/new_and_hot/screen_new_and_hot.dart';
import 'package:netflix_clone/presentation/search/screen_search.dart';

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
    ScreenDownloads(key: PageStorageKey('downloads_screen')),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final downloadsBloc = context.read<DownloadsBloc>();
      if (downloadsBloc.state.downloads.isEmpty) {
        downloadsBloc.add(const DownloadsEvent.getDownloadsImage());
      }
      final homeBloc = context.read<HomeBloc>();
      if (homeBloc.state.trendingMovieList.isEmpty) {
        homeBloc.add(const GetHomeScreenData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      extendBody: true,
      body: ValueListenableBuilder<int>(
        valueListenable: indexChangeNotifier,
        builder: (context, index, _) {
          final safeIndex = index.clamp(0, _pages.length - 1);
          return IndexedStack(
            index: safeIndex,
            children: _pages,
          );
        },
      ),
      bottomNavigationBar: const BottomNaviagtionWidget(),
    );
  }
}
