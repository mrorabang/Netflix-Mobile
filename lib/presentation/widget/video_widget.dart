import 'package:flutter/material.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class VideoWidget extends StatelessWidget {
  const VideoWidget({
    Key? key,
    required this.imageUrl,
    this.onTap,
  }) : super(key: key);

  final String imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final validUrl = resolveImageUrl(imageUrl, null);

    return ScaleTap(
      pressedScale: 0.98,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 196,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmoothNetworkImage(
                imageUrl: validUrl,
                cacheWidth: 780,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x14000000),
                      Color(0x8C000000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x80FFFFFF),
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
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
