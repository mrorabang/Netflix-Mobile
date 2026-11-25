import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/downloads/downloads_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/category/screen_category_movies.dart';
import 'package:netflix_clone/presentation/search/screen_search.dart';
import 'package:netflix_clone/presentation/widgets/cast_modal.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class ScreenDownloads extends StatelessWidget {
  const ScreenDownloads({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      appBar: AppBar(
        backgroundColor: backgrounndColor,
        automaticallyImplyLeading: false,
        title: const Text(
          "Tải Xuống",
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
              Navigator.push(context, netflixRoute(const ScreenSearch()));
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: const [
          _SmartDownloadsBanner(),
          SizedBox(height: 24),
          _DownloadsShowcaseSection(),
          SizedBox(height: 20),
          _DownloadsActionsSection(),
        ],
      ),
    );
  }
}

class _SmartDownloadsBanner extends StatefulWidget {
  const _SmartDownloadsBanner();

  @override
  State<_SmartDownloadsBanner> createState() => _SmartDownloadsBannerState();
}

class _SmartDownloadsBannerState extends State<_SmartDownloadsBanner> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0x262563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF60A5FA),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tải xuống thông minh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Tự động tải tập tiếp theo qua Wi-Fi",
                  style: TextStyle(
                    color: kGray,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            activeTrackColor: kNetflixRed,
            onChanged: (v) => setState(() => _enabled = v),
          ),
        ],
      ),
    );
  }
}

class _DownloadsShowcaseSection extends StatelessWidget {
  const _DownloadsShowcaseSection();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final boxSide = (size.width * 0.78).clamp(250.0, 330.0);

    return Column(
      children: [
        const Text(
          "Tải xuống dành riêng cho bạn",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Chúng tôi sẽ gợi ý những bộ phim và series hợp gu nhất để bạn luôn có sẵn nội dung thưởng thức mọi lúc, kể cả khi ngoại tuyến.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kGray,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        BlocBuilder<DownloadsBloc, DownloadsState>(
          builder: (context, state) {
            if (state.isLoading && state.downloads.isEmpty) {
              return SizedBox(
                width: boxSide,
                height: boxSide,
                child: Center(
                  child: ShimmerBox(
                    width: boxSide * 0.75,
                    height: boxSide * 0.75,
                    borderRadius: boxSide,
                  ),
                ),
              );
            }

            final img1 = state.downloads.isNotEmpty
                ? resolveImageUrl(state.downloads[0].posterPath, null)
                : mainImage;
            final img2 = state.downloads.length > 1
                ? resolveImageUrl(state.downloads[1].posterPath, null)
                : img1;
            final img3 = state.downloads.length > 2
                ? resolveImageUrl(state.downloads[2].posterPath, null)
                : img1;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (context, t, _) {
                return SizedBox(
                  width: boxSide,
                  height: boxSide,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: boxSide * 0.78,
                        height: boxSide * 0.78,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x38E50914),
                              Color(0x14FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(62 * t, 10),
                        child: Transform.rotate(
                          angle: (15 * pi / 180) * t,
                          child: _FanPosterCard(
                            imageUrl: img1,
                            width: boxSide * 0.42,
                            height: boxSide * 0.62,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(-62 * t, 10),
                        child: Transform.rotate(
                          angle: (-15 * pi / 180) * t,
                          child: _FanPosterCard(
                            imageUrl: img2,
                            width: boxSide * 0.42,
                            height: boxSide * 0.62,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.92 + 0.08 * t,
                        child: _FanPosterCard(
                          imageUrl: img3,
                          width: boxSide * 0.48,
                          height: boxSide * 0.70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _FanPosterCard extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const _FanPosterCard({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SmoothNetworkImage(
        imageUrl: imageUrl,
        cacheWidth: 380,
        borderRadius: 11,
      ),
    );
  }
}

class _DownloadsActionsSection extends StatelessWidget {
  const _DownloadsActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTap(
          pressedScale: 0.97,
          onTap: () {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: kCardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                content: const Text(
                  "Đã kích hoạt gói Tải xuống thông minh qua Wi-Fi!",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Thiết lập ngay",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ScaleTap(
          pressedScale: 0.97,
          onTap: () {
            Navigator.push(
              context,
              netflixRoute(
                const ScreenCategoryMovies(
                  initialTitle: "Phim Đề Xuất Tải Xuống",
                  type: CategoryType.phimBo,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Khám phá phim có thể tải",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
