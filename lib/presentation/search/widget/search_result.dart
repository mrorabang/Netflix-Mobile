import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/domain/search/model/search_resp/search_resp.dart';
import 'package:netflix_clone/presentation/search/widget/search_title.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

import '../../decriptions/Screen_decription.dart';

class SearchResult extends StatelessWidget {
  final List<SearchResultData>? items;
  final VoidCallback? onClearFilter;
  final double bottomPadding;

  const SearchResult({
    Key? key,
    this.items,
    this.onClearFilter,
    this.bottomPadding = 20,
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
            const Icon(Icons.search_off_rounded,
                size: 56, color: Color(0xFF626272)),
            const SizedBox(height: 12),
            const Text(
              "Không tìm thấy phim phù hợp",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: 16),
              ScaleTap(
                onTap: onClearFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNetflixRed),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: kNetflixRed, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Xóa bộ lọc",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
            padding: EdgeInsets.fromLTRB(2, 4, 2, bottomPadding),
            cacheExtent: 700,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
              childAspectRatio: 1 / 1.76,
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
        netflixRoute(ScreenDescription(id: widget.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      pressedScale: 0.94,
      onFocusChanged: (focused) => setState(() => _isFocused = focused),
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _isFocused ? Colors.white : const Color(0x18FFFFFF),
                  width: _isFocused ? 2.2 : 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SmoothNetworkImage(
                      imageUrl: widget.imageUrl,
                      cacheWidth: 360,
                    ),
                    if (widget.quality != null && widget.quality!.isNotEmpty)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xBF000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.quality!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (widget.episode != null && widget.episode!.isNotEmpty)
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xD9E50914),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.episode!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          if (widget.title != null && widget.title!.isNotEmpty)
            Text(
              widget.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: _isFocused ? FontWeight.w700 : FontWeight.w600,
                color: _isFocused ? kNetflixRed : Colors.white,
              ),
            ),
          if (widget.year != null)
            Text(
              "${widget.year}",
              style: const TextStyle(
                fontSize: 10.5,
                color: kGray,
              ),
            ),
        ],
      ),
    );
  }
}
