import 'package:flutter/material.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/widget/main_card.dart';
import 'package:netflix_clone/presentation/widget/main_title.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MainTitle(title: title),
        ),
        kHeight,
        LimitedBox(
          maxHeight: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
        )
      ],
    );
  }
}
