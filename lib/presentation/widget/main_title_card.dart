import 'package:flutter/material.dart';
import 'package:netflix_clone/presentation/widget/main_card.dart';
import 'package:netflix_clone/presentation/widget/main_title.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class MainTitleCard extends StatelessWidget {
  const MainTitleCard({
    Key? key,
    required this.title,
    required this.posterList,
    required this.id,
    this.titles,
    this.releaseDates,
  }) : super(key: key);

  final String title;
  final List<String?> posterList;
  final List<String?> id;
  final List<String?>? titles;
  final List<String?>? releaseDates;

  @override
  Widget build(BuildContext context) {
    if (posterList.isEmpty) return const SizedBox.shrink();
    final isTv = TvMode.isTv(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTv ? 24 : 14),
          child: MainTitle(title: title),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isTv ? 262 : 214,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isTv ? 18 : 9),
            itemCount: posterList.length,
            itemBuilder: (context, index) {
              final movieId =
                  (index < id.length && id[index] != null) ? id[index]! : '';
              final poster = posterList[index] ?? '';
              final movieTitle = (titles != null && index < titles!.length)
                  ? titles![index]
                  : null;
              final movieYear =
                  (releaseDates != null && index < releaseDates!.length)
                      ? releaseDates![index]
                      : null;

              return MainCard(
                id: movieId,
                imageUrl: poster,
                title: movieTitle,
                releaseDate: movieYear,
              );
            },
          ),
        ),
      ],
    );
  }
}
