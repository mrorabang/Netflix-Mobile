import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
import '../decriptions/Screen_decription.dart';

class MainCard extends StatefulWidget {
  final String imageUrl;
  final String id;
  final String? title;
  final String? releaseDate;

  const MainCard({
    Key? key,
    required this.imageUrl,
    required this.id,
    this.title,
    this.releaseDate,
  }) : super(key: key);

  @override
  State<MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<MainCard> {
  bool _isFocused = false;

  void _openDetail(BuildContext context) {
    if (widget.id.isNotEmpty) {
      Navigator.push(
        context,
        netflixRoute(ScreenDescription(id: widget.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validImageUrl = resolveImageUrl(widget.imageUrl, null);
    final displayTitle =
        (widget.title != null && widget.title!.trim().isNotEmpty)
            ? widget.title!.trim()
            : '';
    final rawYear =
        (widget.releaseDate != null && widget.releaseDate!.trim().isNotEmpty)
            ? widget.releaseDate!.trim()
            : '';
    final displayYear =
        rawYear.contains('-') ? rawYear.split('-').first : rawYear;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ScaleTap(
        pressedScale: 0.94,
        onFocusChanged: (focused) => setState(() => _isFocused = focused),
        onTap: () => _openDetail(context),
        child: SizedBox(
          width: 124,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 124,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isFocused
                        ? Colors.white
                        : const Color(0x18FFFFFF),
                    width: _isFocused ? 2.2 : 0.8,
                  ),
                  boxShadow: _isFocused
                      ? const [
                          BoxShadow(
                            color: Color(0x99E50914),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmoothNetworkImage(
                        imageUrl: validImageUrl,
                        cacheWidth: 650,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x00000000),
                              Color(0xAD000000),
                            ],
                            stops: [0.0, 0.68, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xBF000000),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0x33FFFFFF),
                              width: 0.6,
                            ),
                          ),
                          child: const Text(
                            "HD",
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      if (displayYear.isNotEmpty)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xCCE50914),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayYear,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayTitle.isNotEmpty ? displayTitle : "Phim Nét Lích",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w600,
                  color: _isFocused ? kNetflixRed : const Color(0xFFEDEDED),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
