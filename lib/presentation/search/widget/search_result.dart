import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/domain/search/model/search_resp/search_resp.dart';
import 'package:netflix_clone/presentation/search/widget/search_title.dart';

import '../../decriptions/Screen_decription.dart';

class SearchResult extends StatelessWidget {
  final List<SearchResultData>? items;
  final VoidCallback? onClearFilter;

  const SearchResult({
    Key? key,
    this.items,
    this.onClearFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items != null) {
      return _buildContent(context, items!);
    }
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return _buildContent(context, state.searchResultList);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<SearchResultData> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[600]),
            const SizedBox(height: 12),
            const Text(
              "Không tìm thấy phim phù hợp",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClearFilter,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.red, size: 16),
                label: const Text(
                  "Xóa bộ lọc",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = screenWidth > MediaQuery.of(context).size.height;
    final crossAxisCount = screenWidth > 1200
        ? 7
        : (screenWidth > 800 ? 6 : (isLandscape ? 5 : 3));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchTitleText(title: "Kết Quả Tìm Kiếm (${list.length})"),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 14,
              childAspectRatio: 1 / 1.78,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final movie = list[index];
              return SearchResultCard(
                id: movie.id ?? '',
                imageUrl: movie.posterImageUrl,
                title: movie.originalTitle,
                quality: movie.quality,
                episode: movie.episodeCurrent,
                year: movie.year,
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchResultCard extends StatefulWidget {
  final String imageUrl;
  final String id;
  final String? title;
  final String? quality;
  final String? episode;
  final int? year;

  const SearchResultCard({
    Key? key,
    required this.imageUrl,
    required this.id,
    this.title,
    this.quality,
    this.episode,
    this.year,
  }) : super(key: key);

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  bool _isFocused = false;

  void _openDetail(BuildContext context) {
    if (widget.id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ScreenDescription(id: widget.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
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
          scale: _isFocused ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
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
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[900],
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.movie_outlined,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        if (widget.quality != null && widget.quality!.isNotEmpty)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                widget.quality!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (widget.episode != null && widget.episode!.isNotEmpty)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.red[800],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                widget.episode!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (widget.title != null && widget.title!.isNotEmpty)
                Text(
                  widget.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        _isFocused ? FontWeight.bold : FontWeight.w600,
                    color: _isFocused ? Colors.redAccent : Colors.white,
                  ),
                ),
              if (widget.year != null)
                Text(
                  "${widget.year}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
