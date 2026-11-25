import 'package:bordered_text/bordered_text.dart';
import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class NumberCard extends StatelessWidget {
  const NumberCard({
    Key? key,
    required this.index,
    required this.imageUrl,
    this.id = '',
    this.title,
  }) : super(key: key);

  final String imageUrl;
  final int index;
  final String id;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final validUrl = resolveImageUrl(imageUrl, null);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ScaleTap(
        pressedScale: 0.94,
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              netflixRoute(ScreenDescription(id: id)),
            );
          }
        },
        child: SizedBox(
          width: 158,
          height: 192,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 8,
                child: Container(
                  width: 122,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x22FFFFFF),
                      width: 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SmoothNetworkImage(
                    imageUrl: validUrl,
                    cacheWidth: 360,
                    borderRadius: 9,
                  ),
                ),
              ),
              Positioned(
                left: index == 9 ? -4 : 4,
                bottom: -14,
                child: IgnorePointer(
                  child: BorderedText(
                    strokeWidth: 4.5,
                    strokeColor: const Color(0xFFDADAE2),
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: backgrounndColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 108,
                        height: 1.0,
                        letterSpacing: -6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
