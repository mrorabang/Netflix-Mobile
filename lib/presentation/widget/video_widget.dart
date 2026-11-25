import 'package:flutter/material.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/infrastructure/tmdb/tmdb_4k_service.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    Key? key,
    required this.imageUrl,
    this.movieId,
    this.movieTitle,
    this.onTap,
  }) : super(key: key);

  final String imageUrl;
  final String? movieId;
  final String? movieTitle;
  final VoidCallback? onTap;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  Tmdb4kMedia? _media4k;

  @override
  void initState() {
    super.initState();
    _media4k = Tmdb4kService.getCached(widget.movieId);
    if (_media4k == null &&
        widget.movieId != null &&
        widget.movieId!.isNotEmpty) {
      _load4k();
    }
  }

  @override
  void didUpdateWidget(covariant VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) {
      _media4k = Tmdb4kService.getCached(widget.movieId);
      if (_media4k == null &&
          widget.movieId != null &&
          widget.movieId!.isNotEmpty) {
        _load4k();
      }
    }
  }

  Future<void> _load4k() async {
    final res = await Tmdb4kService.fetch4kForSlug(
      widget.movieId,
      fallbackTitle: widget.movieTitle,
    );
    if (mounted && res != null) {
      setState(() => _media4k = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validUrl =
        _media4k?.backdrop4kUrl ?? resolveImageUrl(widget.imageUrl, null);
    final is4k = _media4k?.backdrop4kUrl != null;

    return ScaleTap(
      pressedScale: 0.98,
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 204,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmoothNetworkImage(
                imageUrl: validUrl,
                cacheWidth: null,
                filterQuality: FilterQuality.high,
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
              if (is4k)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0A0A10),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xCCFBBF24),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      "4K UHD",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFBBF24),
                        letterSpacing: 0.5,
                      ),
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
