import 'package:flutter/material.dart';
import 'package:netflix_clone/presentation/widget/main_title_card.dart';

class NumberTitleCard extends StatelessWidget {
  const NumberTitleCard({
    Key? key,
    required this.title,
    required this.posterList,
    this.id,
    this.titles,
    this.releaseDates,
  }) : super(key: key);

  final List<String> posterList;
  final String title;
  final List<String?>? id;
  final List<String?>? titles;
  final List<String?>? releaseDates;

  @override
  Widget build(BuildContext context) {
    return MainTitleCard(
      title: title,
      posterList: posterList,
      id: id ?? List.filled(posterList.length, ''),
      titles: titles,
      releaseDates: releaseDates,
    );
  }
}
