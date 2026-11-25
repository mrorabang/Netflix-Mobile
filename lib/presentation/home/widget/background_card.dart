import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class BackgroundCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? movieId;

  const BackgroundCard({
    Key? key,
    this.imageUrl,
    this.title,
    this.movieId,
  }) : super(key: key);

  void _openDetail(BuildContext context) {
    if (movieId != null && movieId!.isNotEmpty) {
      Navigator.push(
        context,
        netflixRoute(ScreenDescription(id: movieId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = upgradeToHighResPoster(resolveImageUrl(imageUrl, null));
    final media = MediaQuery.of(context);
    final size = media.size;
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      final bannerHeight = (size.height * 0.68).clamp(280.0, 390.0);
      return SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SmoothNetworkImage(imageUrl: poster, cacheWidth: null),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x8A0A0A0E),
                    Colors.transparent,
                    Color(0xB30A0A0E),
                    backgrounndColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.78, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: _buildHeroControls(context, isCardStyle: false),
            ),
          ],
        ),
      );
    }

    // Giao diện Mobile Portrait: Thẻ Hero nổi bo góc chuẩn Netflix hiện đại
    final topInset = media.padding.top + 96;
    final cardHeight = (size.width * 1.24).clamp(430.0, 520.0);

    return Stack(
      children: [
        // Quầng sáng mờ phía sau tạo chiều sâu cho đầu trang chủ
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: cardHeight + topInset,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.28,
              child: Image.network(
                poster,
                fit: BoxFit.cover,
                cacheWidth: 240,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0A0A0E),
                    Color(0x990A0A0E),
                    backgrounndColor,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, topInset, 16, 4),
          child: ScaleTap(
            pressedScale: 0.985,
            onTap: () => _openDetail(context),
            child: Container(
              height: cardHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x33FFFFFF),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmoothNetworkImage(
                      imageUrl: poster,
                      cacheWidth: null,
                      alignment: Alignment.topCenter,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x26000000),
                            Colors.transparent,
                            Color(0x9908080C),
                            Color(0xF208080C),
                          ],
                          stops: [0.0, 0.42, 0.75, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildHeroControls(context, isCardStyle: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroControls(BuildContext context, {required bool isCardStyle}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nhãn phân loại nổi bật
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: kNetflixRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "TOP 1",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "Mới cập nhật  •  Vietsub  •  FHD",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE0E0EA),
              ),
            ),
          ],
        ),
        if (title != null && title!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            title!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.18,
              letterSpacing: -0.3,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ScaleTap(
                pressedScale: 0.95,
                onTap: () => _openDetail(context),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 26,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Phát",
                        style: TextStyle(
                          fontSize: 15.5,
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: MyListStore.savedIds,
                builder: (context, savedSet, _) {
                  final isSaved =
                      movieId != null && savedSet.contains(movieId);
                  return ScaleTap(
                    pressedScale: 0.95,
                    enableHaptic: false,
                    onTap: () {
                      MyListStore.toggleSaved(
                        context,
                        movieId,
                        title: title,
                      );
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xCC2A2A35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSaved
                              ? const Color(0x99FFFFFF)
                              : const Color(0x2EFFFFFF),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isSaved
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              key: ValueKey<bool>(isSaved),
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isSaved ? "Đã lưu" : "Danh sách",
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
