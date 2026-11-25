import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../../../core/colors/colors.dart';

class MovieTitleAndOveriew extends StatelessWidget {
  const MovieTitleAndOveriew({
    Key? key,
    required this.title,
    required this.overView,
  }) : super(key: key);

  final String title;
  final String overView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          ReadMoreText(
            overView,
            trimLines: 3,
            colorClickableText: kNetflixRed,
            trimMode: TrimMode.Line,
            trimCollapsedText: " Xem thêm",
            trimExpandedText: " Thu gọn",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFB8B8C7),
              height: 1.48,
            ),
            moreStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            lessStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: kNetflixRed,
            ),
          ),
        ],
      ),
    );
  }
}