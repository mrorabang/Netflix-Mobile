import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/description/description_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/infrastructure/tmdb/tmdb_4k_service.dart';
import 'package:netflix_clone/presentation/watch/screen_watch.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'widget/movie_details.dart';
import 'widget/round_text_widget.dart';

class ScreenDescription extends StatefulWidget {
  const ScreenDescription({
    Key? key,
    required this.id,
  }) : super(key: key);

  final String id;

  @override
  State<ScreenDescription> createState() => _ScreenDescriptionState();
}

class _ScreenDescriptionState extends State<ScreenDescription> {
  static const int _episodesPerChunk = 24;
  int _selectedChunk = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DescriptionBloc>().add(LoadDataMovie(id: widget.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      body: BlocBuilder<DescriptionBloc, DescriptionState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoadingSkeleton(context);
          } else if (state.isError) {
            return _buildErrorView(context);
          }

          final tmdb4k = Tmdb4kService.getCached(widget.id);
          final imageUrl = tmdb4k?.backdrop4kUrl ??
              tmdb4k?.poster4kUrl ??
              upgradeToHighResPoster(resolveImageUrl(state.posterPath, null));
          final hasEpisodes = state.episodeList.isNotEmpty;
          final isTrailerOnly = hasEpisodes &&
              state.episodeList.length == 1 &&
              state.episodeList.first.name.toLowerCase() == 'trailer';

          final size = MediaQuery.of(context).size;
          final isLandscape = size.width > size.height;

          if (isLandscape) {
            return _buildLandscapeDetail(
              context,
              state: state,
              imageUrl: imageUrl,
              hasEpisodes: hasEpisodes,
              isTrailerOnly: isTrailerOnly,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: (size.height * 0.52).clamp(360.0, 460.0),
                pinned: true,
                stretch: true,
                backgroundColor: backgrounndColor,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Center(
                    child: ScaleTap(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmoothNetworkImage(
                        imageUrl: imageUrl,
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
                              Color(0x73000000),
                              Colors.transparent,
                              Color(0x8C0A0A0E),
                              backgrounndColor,
                            ],
                            stops: [0.0, 0.35, 0.78, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0x2622C55E),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0x6622C55E),
                                width: 0.7,
                              ),
                            ),
                            child: const Text(
                              "Đề xuất 98%",
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const RoundText(text: "16+"),
                          if (tmdb4k?.hasAnyHighRes == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0x26FBBF24),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0x99FBBF24),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                "4K ULTRA HD",
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          RoundText(
                            text: state.status.isEmpty ? "FHD" : state.status,
                          ),
                          if (state.voteAverage > 0)
                            RoundText(
                              text:
                                  "⭐ ${state.voteAverage.toStringAsFixed(1)}",
                            ),
                        ],
                      ),
                    ),
                    MovieTitleAndOveriew(
                      title: state.title,
                      overView: state.overview.isEmpty
                          ? "Nội dung phim đang cập nhật..."
                          : state.overview,
                    ),

                    // Nút Phát chính nổi bật
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      child: hasEpisodes
                          ? ScaleTap(
                              pressedScale: 0.97,
                              onTap: () {
                                final ep = state.episodeList.first;
                                Navigator.push(
                                  context,
                                  netflixRoute(
                                    ScreenWatch(
                                      url: ep.linkEmbed,
                                      title: "${state.title} - ${ep.name}",
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isTrailerOnly
                                          ? Icons.movie_creation_outlined
                                          : Icons.play_arrow_rounded,
                                      size: 28,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isTrailerOnly
                                          ? "Xem Trailer giới thiệu"
                                          : (state.episodeList.length > 1
                                              ? "Phát ngay • ${state.episodeList.first.name}"
                                              : "Phát phim ngay"),
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildUpdatingNotice(),
                    ),

                    // Hàng nút tác vụ phụ: Danh sách, Đánh giá, Chia sẻ
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: MyListStore.savedIds,
                            builder: (context, savedSet, _) {
                              final saved = savedSet.contains(widget.id);
                              return _buildActionIcon(
                                icon: saved
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                label: saved ? "Đã lưu" : "Danh sách",
                                isActive: saved,
                                onTap: () => MyListStore.toggleSaved(
                                  context,
                                  widget.id,
                                  title: state.title,
                                ),
                              );
                            },
                          ),
                          _buildActionIcon(
                            icon: Icons.thumb_up_alt_outlined,
                            label: "Yêu thích",
                            onTap: () => MyListStore.toggleSaved(
                              context,
                              widget.id,
                              title: state.title,
                            ),
                          ),
                          _buildActionIcon(
                            icon: Icons.share_outlined,
                            label: "Chia sẻ",
                            onTap: () {
                              Share.share(
                                'Xem phim "${state.title}" chất lượng cao trên Nét Lích!',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    if (hasEpisodes && state.episodeList.length > 1)
                      _buildEpisodeSection(context, state),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEpisodeSection(BuildContext context, DescriptionState state) {
    final total = state.episodeList.length;
    final chunkCount = (total / _episodesPerChunk).ceil();
    final safeChunk = _selectedChunk.clamp(0, chunkCount - 1);
    final start = safeChunk * _episodesPerChunk;
    final end = (start + _episodesPerChunk).clamp(0, total);
    final visibleEpisodes = state.episodeList.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0x1FFFFFFF), height: 20),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: kNetflixRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Danh sách tập ($total)",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (chunkCount > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(chunkCount, (idx) {
                  final from = idx * _episodesPerChunk + 1;
                  final to = ((idx + 1) * _episodesPerChunk).clamp(1, total);
                  final active = idx == safeChunk;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ScaleTap(
                      onTap: () => setState(() => _selectedChunk = idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? kNetflixRed : kCardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: active
                                ? kNetflixRed
                                : const Color(0x24FFFFFF),
                          ),
                        ),
                        child: Text(
                          "Tập $from - $to",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : const Color(0xFFB8B8C7),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemCount: visibleEpisodes.length,
            itemBuilder: (context, index) {
              final ep = visibleEpisodes[index];
              final isFirst = start + index == 0;
              return ScaleTap(
                pressedScale: 0.94,
                onTap: () {
                  Navigator.push(
                    context,
                    netflixRoute(
                      ScreenWatch(
                        url: ep.linkEmbed,
                        title: "${state.title} - ${ep.name}",
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isFirst
                        ? const Color(0x2EE50914)
                        : kCardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFirst
                          ? const Color(0x80E50914)
                          : const Color(0x1FFFFFFF),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        size: 15,
                        color: isFirst
                            ? kNetflixRed
                            : const Color(0xFF9E9EAE),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          ep.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ScaleTap(
      pressedScale: 0.9,
      enableHaptic: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0x2EE50914)
                    : const Color(0x18FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? kNetflixRed
                      : const Color(0x26FFFFFF),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFB8B8C7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0x26FFC107),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Phim đang cập nhật tập mới",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Tập phim đang được hệ thống đồng bộ. Bạn vui lòng quay lại sau ít phút!",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const ShimmerBox(height: 410, borderRadius: 0),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  ShimmerBox(width: 90, height: 24, borderRadius: 6),
                  SizedBox(width: 8),
                  ShimmerBox(width: 44, height: 24, borderRadius: 6),
                  SizedBox(width: 8),
                  ShimmerBox(width: 56, height: 24, borderRadius: 6),
                ],
              ),
              SizedBox(height: 14),
              ShimmerBox(width: 240, height: 26, borderRadius: 6),
              SizedBox(height: 12),
              ShimmerBox(height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerBox(height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerBox(width: 180, height: 14, borderRadius: 4),
              SizedBox(height: 20),
              ShimmerBox(height: 48, borderRadius: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                "Không thể tải thông tin phim",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Dữ liệu phim đang được cập nhật hoặc kết nối mạng không ổn định.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kGray, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ScaleTap(
                onTap: () {
                  context
                      .read<DescriptionBloc>()
                      .add(LoadDataMovie(id: widget.id));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                  decoration: BoxDecoration(
                    color: kNetflixRed,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        "Thử lại",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeDetail(
    BuildContext context, {
    required DescriptionState state,
    required String imageUrl,
    required bool hasEpisodes,
    required bool isTrailerOnly,
  }) {
    return Scaffold(
      backgroundColor: backgrounndColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          state.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 210,
              height: 315,
              child: SmoothNetworkImage(
                imageUrl: imageUrl,
                cacheWidth: 500,
                borderRadius: 12,
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const RoundText(text: "16+"),
                        RoundText(
                            text: state.status.isEmpty ? "FHD" : state.status),
                        if (state.voteAverage > 0)
                          RoundText(
                            text: "⭐ ${state.voteAverage.toStringAsFixed(1)}",
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.overview.isEmpty
                          ? "Nội dung phim đang cập nhật..."
                          : state.overview,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kGray,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (hasEpisodes) ...[
                      ElevatedButton.icon(
                        autofocus: true,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(
                          isTrailerOnly
                              ? Icons.movie_creation_outlined
                              : Icons.play_arrow_rounded,
                          size: 26,
                        ),
                        label: Text(
                          isTrailerOnly
                              ? "Xem Trailer giới thiệu"
                              : (state.episodeList.length > 1
                                  ? "Phát tập 1 (${state.episodeList.first.name})"
                                  : "Phát / Xem phim"),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final ep = state.episodeList.first;
                          Navigator.push(
                            context,
                            netflixRoute(
                              ScreenWatch(
                                url: ep.linkEmbed,
                                title: "${state.title} - ${ep.name}",
                              ),
                            ),
                          );
                        },
                      ),
                      if (state.episodeList.length > 1) ...[
                        const SizedBox(height: 18),
                        const Text(
                          "Danh sách tập phim",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.episodeList.map((ep) {
                            return ActionChip(
                              backgroundColor: kCardColor,
                              label: Text(
                                ep.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  netflixRoute(
                                    ScreenWatch(
                                      url: ep.linkEmbed,
                                      title: "${state.title} - ${ep.name}",
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ] else ...[
                      _buildUpdatingNotice(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
