import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/home/widget/custom_button_widget.dart';

class BackgroundCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final String? movieId;

  const BackgroundCard({
    Key? key,
    this.imageUrl,
    this.title,
    this.movieId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final poster = resolveImageUrl(imageUrl, null);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 520,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(poster),
              fit: BoxFit.cover,
            ),
          ),
          foregroundDecoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.2, 0.7, 1],
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                if (title != null && title!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const CustomButtonWidget(
                      icon: Icons.add,
                      title: "Danh sách",
                    ),
                    _playButton(context),
                    GestureDetector(
                      onTap: () {
                        if (movieId != null && movieId!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ScreenDescription(id: movieId!),
                            ),
                          );
                        }
                      },
                      child: const CustomButtonWidget(
                        icon: Icons.info_outline,
                        title: "Chi tiết",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _playButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        if (movieId != null && movieId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ScreenDescription(id: movieId!),
            ),
          );
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: kwhiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      icon: const Icon(
        Icons.play_arrow,
        size: 26,
        color: kBlackColor,
      ),
      label: const Text(
        "Phát",
        style: TextStyle(fontSize: 18, color: kBlackColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
