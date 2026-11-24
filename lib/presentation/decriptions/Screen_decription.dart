import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/description/description_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/watch/screen_watch.dart';
import 'widget/background_image_widget.dart';
import 'widget/movie_details.dart';
import 'widget/round_text_widget.dart';

class ScreenDescription extends StatelessWidget {
  const ScreenDescription({
    Key? key,
    required this.id,
  }) : super(key: key);
  final String id;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      BlocProvider.of<DescriptionBloc>(context).add(LoadDataMovie(id: id));
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<DescriptionBloc, DescriptionState>(
        builder: (context, state) {
          final imageUrl = resolveImageUrl(state.posterPath, null);
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.red,
              ),
            );
          } else if (state.isError) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
                        size: 56,
                      ),
                      const SizedBox(height: 16),
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
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          BlocProvider.of<DescriptionBloc>(context)
                              .add(LoadDataMovie(id: id));
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text(
                          "Thử lại",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }

          final hasEpisodes = state.episodeList.isNotEmpty;
          final isTrailerOnly = hasEpisodes &&
              state.episodeList.length == 1 &&
              state.episodeList.first.name.toLowerCase() == 'trailer';

          final size = MediaQuery.of(context).size;
          final isLandscape = size.width > size.height;

          if (isLandscape) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  state.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Poster Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 220,
                        height: 330,
                        color: Colors.grey[900],
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(Icons.movie,
                                  size: 60, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Right Column: Title, Badges, Details, Play Button, Episodes
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const RoundText(text: "18+"),
                                kWidth,
                                RoundText(
                                    text: state.status.isEmpty
                                        ? "HD"
                                        : state.status),
                                kWidth,
                                RoundText(text: "⭐ ${state.voteAverage}"),
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
                                height: 1.4,
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
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: Icon(
                                  isTrailerOnly
                                      ? Icons.movie_creation_outlined
                                      : Icons.play_arrow,
                                  size: 26,
                                ),
                                label: Text(
                                  isTrailerOnly
                                      ? "Xem Trailer giới thiệu"
                                      : (state.episodeList.length > 1
                                          ? "Phát tập 1 (${state.episodeList.first.name})"
                                          : "Phát / Xem phim"),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  final ep = state.episodeList.first;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => ScreenWatch(
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
                                      backgroundColor: Colors.grey[850],
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
                                          MaterialPageRoute(
                                            builder: (ctx) => ScreenWatch(
                                              url: ep.linkEmbed,
                                              title:
                                                  "${state.title} - ${ep.name}",
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.amber,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
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
                              ),
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

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackgroundImage(imageUrl: imageUrl),
                  kHeight20,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const RoundText(
                                  text: "18+",
                                ),
                                kWidth,
                                RoundText(
                                    text: state.status.isEmpty ? "HD" : state.status),
                                kWidth,
                                RoundText(text: "⭐ ${state.voteAverage}"),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.add_circle_outline_sharp,
                              size: 28,
                              color: kwhiteColor,
                            )),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.share,
                              color: kwhiteColor,
                              size: 28,
                            ))
                      ],
                    ),
                  ),
                  MovieTitleAndOveriew(
                    title: state.title,
                    overView: state.overview.isEmpty
                        ? "Nội dung phim đang cập nhật..."
                        : state.overview,
                  ),
                  if (hasEpisodes) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: Icon(
                          isTrailerOnly
                              ? Icons.movie_creation_outlined
                              : Icons.play_arrow,
                          size: 28,
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
                            MaterialPageRoute(
                              builder: (ctx) => ScreenWatch(
                                url: ep.linkEmbed,
                                title: "${state.title} - ${ep.name}",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (state.episodeList.length > 1) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Text(
                          "Danh sách tập phim",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.episodeList.map((ep) {
                            return ActionChip(
                              backgroundColor: Colors.grey[850],
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
                                  MaterialPageRoute(
                                    builder: (ctx) => ScreenWatch(
                                      url: ep.linkEmbed,
                                      title: "${state.title} - ${ep.name}",
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ] else ...[
                    // When no playable episodes or trailer available yet
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Colors.amber,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
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
                      ),
                    ),
                  ],
                  kHeight20,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
