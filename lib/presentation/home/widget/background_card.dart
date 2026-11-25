import 'dart:async';
import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/domain/new_and_hot/model/discover.dart';
import 'package:netflix_clone/infrastructure/tmdb/tmdb_4k_service.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BackgroundCard extends StatefulWidget {
  final String? imageUrl;
  final String? title;
  final String? movieId;
  final List<HotAndNewData> heroMovies;

  const BackgroundCard({
    Key? key,
    this.imageUrl,
    this.title,
    this.movieId,
    this.heroMovies = const [],
  }) : super(key: key);

  @override
  State<BackgroundCard> createState() => _BackgroundCardState();
}

class _BackgroundCardState extends State<BackgroundCard> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _activeIndex = 0;

  List<HotAndNewData> get _slides {
    if (widget.heroMovies.isNotEmpty) {
      return widget.heroMovies.take(6).toList();
    }
    if (widget.movieId != null || widget.imageUrl != null) {
      return [
        HotAndNewData(
          id: widget.movieId,
          title: widget.title,
          posterPath: widget.imageUrl,
          backdropPath: widget.imageUrl,
        ),
      ];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _prefetchAll4kSlides();
  }

  @override
  void didUpdateWidget(covariant BackgroundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heroMovies != widget.heroMovies) {
      _prefetchAll4kSlides();
    }
  }

  void _prefetchAll4kSlides() {
    for (final m in _slides) {
      Tmdb4kService.fetch4kForSlug(
        m.id,
        fallbackTitle: m.originalTitle?.isNotEmpty == true
            ? m.originalTitle
            : m.title,
      );
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      final list = _slides;
      if (!mounted || list.length <= 1 || !_pageController.hasClients) return;
      final next = (_activeIndex + 1) % list.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final size = media.size;
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      final bannerHeight = (size.height * 0.72).clamp(290.0, 410.0);
      return SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _activeIndex = i),
              itemBuilder: (context, index) => _Hero4kSlide(
                movie: slides[index],
                rank: index + 1,
                isLandscape: true,
              ),
            ),
            if (slides.length > 1)
              Positioned(
                right: 24,
                bottom: 20,
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: slides.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: kNetflixRed,
                    dotColor: Color(0x52FFFFFF),
                    dotHeight: 6,
                    dotWidth: 6,
                    expansionFactor: 3,
                    spacing: 5,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Mobile Portrait: Thẻ Banner 4K nổi bo góc kèm hiệu ứng quầng sáng nền
    final topInset = media.padding.top + 94;
    final cardHeight = (size.width * 1.18).clamp(420.0, 500.0);
    final currentMovie = slides[_activeIndex.clamp(0, slides.length - 1)];
    final ambientUrl = resolveImageUrl(
      currentMovie.backdropPath ?? currentMovie.posterPath,
      null,
    );

    return Stack(
      children: [
        // Quầng sáng màu nền đồng bộ theo slide đang chiếu
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: cardHeight + topInset,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Opacity(
                key: ValueKey<String>(ambientUrl),
                opacity: 0.32,
                child: Image.network(
                  ambientUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
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
          padding: EdgeInsets.fromLTRB(14, topInset, 14, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: cardHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0x38FFFFFF),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB8000000),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification) {
                        _autoSlideTimer?.cancel();
                      } else if (n is ScrollEndNotification) {
                        _startAutoSlide();
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: slides.length,
                      onPageChanged: (i) => setState(() => _activeIndex = i),
                      itemBuilder: (context, index) => _Hero4kSlide(
                        movie: slides[index],
                        rank: index + 1,
                        isLandscape: false,
                      ),
                    ),
                  ),
                ),
              ),
              if (slides.length > 1) ...[
                const SizedBox(height: 10),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: slides.length,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: kNetflixRed,
                    dotColor: Color(0x40FFFFFF),
                    dotHeight: 5.5,
                    dotWidth: 6,
                    expansionFactor: 3.2,
                    spacing: 5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero4kSlide extends StatefulWidget {
  final HotAndNewData movie;
  final int rank;
  final bool isLandscape;

  const _Hero4kSlide({
    required this.movie,
    required this.rank,
    required this.isLandscape,
  });

  @override
  State<_Hero4kSlide> createState() => _Hero4kSlideState();
}

class _Hero4kSlideState extends State<_Hero4kSlide> {
  Tmdb4kMedia? _media4k;

  @override
  void initState() {
    super.initState();
    _media4k = Tmdb4kService.getCached(widget.movie.id);
    if (_media4k == null) {
      _load4k();
    }
  }

  @override
  void didUpdateWidget(covariant _Hero4kSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id) {
      _media4k = Tmdb4kService.getCached(widget.movie.id);
      if (_media4k == null) {
        _load4k();
      }
    }
  }

  Future<void> _load4k() async {
    final res = await Tmdb4kService.fetch4kForSlug(
      widget.movie.id,
      fallbackTitle: widget.movie.originalTitle?.isNotEmpty == true
          ? widget.movie.originalTitle
          : widget.movie.title,
    );
    if (mounted && res != null) {
      setState(() => _media4k = res);
    }
  }

  void _openDetail(BuildContext context) {
    final id = widget.movie.id;
    if (id != null && id.isNotEmpty) {
      Navigator.push(context, netflixRoute(ScreenDescription(id: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên Banner 4K (3840x2160) từ TMDB; nếu không có mới dùng Poster 4K (2000x3000) hoặc ảnh dự phòng
    final fallbackImg = upgradeToHighResPoster(
      resolveImageUrl(widget.movie.backdropPath ?? widget.movie.posterPath, null),
    );
    final bannerUrl = _media4k?.backdrop4kUrl ??
        _media4k?.poster4kUrl ??
        fallbackImg;
    final logoUrl = _media4k?.logoUrl;
    final is4kLoaded = _media4k?.hasAnyHighRes == true;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SmoothNetworkImage(
            imageUrl: bannerUrl,
            cacheWidth: null,
            filterQuality: FilterQuality.high,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x2E000000),
                  Colors.transparent,
                  Color(0xAD08080C),
                  Color(0xF508080C),
                ],
                stops: [0.0, 0.38, 0.73, 1.0],
              ),
            ),
          ),

          // Nhãn 4K ULTRA HD góc trên phải của Banner
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xBF0A0A10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: is4kLoaded
                      ? const Color(0xCCFBBF24)
                      : const Color(0x4DFFFFFF),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hd_rounded,
                    size: 14,
                    color: is4kLoaded
                        ? const Color(0xFFFBBF24)
                        : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    is4kLoaded ? "4K ULTRA HD" : "FULL HD",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: is4kLoaded
                          ? const Color(0xFFFBBF24)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logoUrl != null && logoUrl.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 56, maxWidth: 230),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (widget.movie.title != null &&
                    widget.movie.title!.isNotEmpty)
                  Text(
                    widget.movie.title!,
                    maxLines: logoUrl != null ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: logoUrl != null ? 15 : 22,
                      fontWeight: FontWeight.w800,
                      color: logoUrl != null
                          ? const Color(0xFFEAEAF2)
                          : Colors.white,
                      height: 1.2,
                      shadows: const [
                        Shadow(
                          blurRadius: 12,
                          color: Colors.black,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: kNetflixRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "TOP ${widget.rank}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${(widget.movie.releaseDate?.isNotEmpty == true) ? '${widget.movie.releaseDate}  •  ' : ''}Vietsub  •  4K HDR",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDCDCE8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                          final id = widget.movie.id;
                          final isSaved = id != null && savedSet.contains(id);
                          return ScaleTap(
                            pressedScale: 0.95,
                            enableHaptic: false,
                            onTap: () {
                              MyListStore.toggleSaved(
                                context,
                                id,
                                title: widget.movie.title,
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
                                  Icon(
                                    isSaved
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                    size: 21,
                                    color: Colors.white,
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
            ),
          ),
        ],
      ),
    );
  }
}
