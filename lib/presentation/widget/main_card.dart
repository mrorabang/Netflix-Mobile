import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netflix_clone/core/constants.dart';
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
        MaterialPageRoute(
          builder: (ctx) => ScreenDescription(
            id: widget.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validImageUrl = resolveImageUrl(widget.imageUrl, null);
    final displayTitle = (widget.title != null && widget.title!.trim().isNotEmpty)
        ? widget.title!.trim()
        : '';
    final displayYear = (widget.releaseDate != null && widget.releaseDate!.trim().isNotEmpty)
        ? widget.releaseDate!.trim()
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Focus(
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            _openDetail(context);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () => _openDetail(context),
          child: AnimatedScale(
            scale: _isFocused ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFocused ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: _isFocused
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 130,
                        height: 185,
                        color: Colors.grey[900],
                        child: Image.network(
                          validImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red[700],
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.movie_outlined,
                                      color: Colors.grey, size: 40),
                                  SizedBox(height: 6),
                                  Text(
                                    "Netflix",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayTitle.isNotEmpty ? displayTitle : "Phim Netflix",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          _isFocused ? FontWeight.bold : FontWeight.w600,
                      color: _isFocused ? Colors.redAccent : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (displayYear.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            displayYear,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.white24, width: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          "HD",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
