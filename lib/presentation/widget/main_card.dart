import 'package:flutter/material.dart';
import 'package:netflix_clone/core/constants.dart';
import '../decriptions/Screen_decription.dart';

class MainCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final validImageUrl = resolveImageUrl(imageUrl, null);
    final displayTitle = (title != null && title!.trim().isNotEmpty)
        ? title!.trim()
        : '';
    final displayYear = (releaseDate != null && releaseDate!.trim().isNotEmpty)
        ? releaseDate!.trim()
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => ScreenDescription(
                  id: id,
                ),
              ),
            );
          }
        },
        child: SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
              const SizedBox(height: 6),
              Text(
                displayTitle.isNotEmpty ? displayTitle : "Phim Netflix",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 0.8),
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
    );
  }
}
