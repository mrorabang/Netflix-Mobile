import 'package:flutter/material.dart';
import 'package:netflix_clone/presentation/home/widget/number_card.dart';
import 'package:netflix_clone/presentation/widget/main_title.dart';

class NumberTitleCard extends StatelessWidget {
  const NumberTitleCard({
    Key? key,
    required this.title,
    required this.posterList,
    this.ids = const [],
    this.titles = const [],
  }) : super(key: key);

  final List<String> posterList;
  final List<String?> ids;
  final List<String?> titles;
  final String title;

  @override
  Widget build(BuildContext context) {
    final count = posterList.length > 10 ? 10 : posterList.length;
    if (count == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: MainTitle(title: title),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: count,
            itemBuilder: (context, index) {
              final movieId =
                  (index < ids.length && ids[index] != null) ? ids[index]! : '';
              final movieTitle =
                  (index < titles.length) ? titles[index] : null;
              return NumberCard(
                imageUrl: posterList[index],
                index: index,
                id: movieId,
                title: movieTitle,
              );
            },
          ),
        ),
      ],
    );
  }
}
