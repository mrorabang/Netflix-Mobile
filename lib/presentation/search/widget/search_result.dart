import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/search/widget/search_title.dart';

import '../../decriptions/Screen_decription.dart';

class SearchResult extends StatelessWidget {
  const SearchResult({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchTitleText(title: "Phim & Chương Trình TV"),
        kHeight20,
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1 / 1.7,
                ),
                itemCount: state.searchResultList.length,
                itemBuilder: (context, index) {
                  final movie = state.searchResultList[index];
                  return SearchResultCard(
                    id: movie.id ?? '',
                    imageUrl: movie.posterImageUrl,
                    title: movie.originalTitle,
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class SearchResultCard extends StatelessWidget {
  final String imageUrl;
  final String id;
  final String? title;

  const SearchResultCard({
    Key? key,
    required this.imageUrl,
    required this.id,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ScreenDescription(id: id),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                color: Colors.grey[900],
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.movie_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
