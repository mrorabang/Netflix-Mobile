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
    final isTv = TvMode.isTv(context);
    final totalW = isTv ? 196.0 : 158.0;
    final totalH = isTv ? 236.0 : 192.0;
    final posterW = isTv ? 152.0 : 122.0;

    return Padding(
      padding: EdgeInsets.only(right: isTv ? 12 : 8),
      child: ScaleTap(
        pressedScale: 0.94,
        showFocusRing: true,
        focusBorderRadius: 12,
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              netflixRoute(ScreenDescription(id: id)),
            );
          }
        },
        child: SizedBox(
          width: totalW,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 8,
                child: Container(
                  width: posterW,
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
                    cacheWidth: isTv ? 900 : 650,
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
                      style: TextStyle(
                        color: backgrounndColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isTv ? 126 : 108,
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
