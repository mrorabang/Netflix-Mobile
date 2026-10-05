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
      body: BlocBuilder<DescriptionBloc, DescriptionState>(
        builder: (context, state) {
          final imageUrl = resolveImageUrl(state.posterPath, null);
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            );
          } else if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Không thể tải thông tin phim"),
                  kHeight,
                  ElevatedButton(
                    onPressed: () {
                      BlocProvider.of<DescriptionBloc>(context)
                          .add(LoadDataMovie(id: id));
                    },
                    child: const Text("Thử lại"),
                  )
                ],
              ),
            );
          }
          return ListView(
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
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const RoundText(
                                text: "18+",
                              ),
                              RoundText(
                                  text: state.status.isEmpty ? "HD" : state.status),
                              if (state.voteAverage > 0)
                                RoundText(text: "⭐ ${state.voteAverage}"),
                            ],
                          ),
                        ),
                        IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.add_circle_outline_sharp,
                              size: 28,
                              color: kwhiteColor,
                            )),
                        const SizedBox(width: 12),
                        IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.share,
                              color: kwhiteColor,
                              size: 26,
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
                  if (state.episodeList.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: Text(
                          state.episodeList.length > 1
                              ? "Phát tập 1 (${state.episodeList.first.name})"
                              : "Phát / Xem phim",
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
                                style: const TextStyle(color: Colors.white),
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
