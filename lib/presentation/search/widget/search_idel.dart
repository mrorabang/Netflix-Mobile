import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/search/widget/search_title.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class SearchIdelWidget extends StatelessWidget {
  final double bottomPadding;

  const SearchIdelWidget({
    Key? key,
    this.bottomPadding = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchTitleText(
          title: "Tìm Kiếm Hàng Đầu",
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state.isLoading) {
                return ListView.separated(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const ShimmerBox(
                    height: 76,
                    borderRadius: 12,
                  ),
                );
              } else if (state.isError) {
                return const Center(
                  child: Text(
                    "Lỗi khi tải xu hướng tìm kiếm",
                    style: TextStyle(color: kGray),
                  ),
                );
              } else if (state.ideleList.isEmpty) {
                return const Center(
                  child: Text(
                    "Danh sách đang cập nhật",
                    style: TextStyle(color: kGray),
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.only(bottom: bottomPadding),
                cacheExtent: 600,
                itemBuilder: (ctx, index) {
                  final movie = state.ideleList[index];
                  return TopSearchItemTile(
                    id: movie.id ?? '',
                    title: movie.title ?? 'Chưa có tiêu đề',
                    imageUrl: resolveImageUrl(movie.posterPath, null),
                  );
                },
                separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                itemCount: state.ideleList.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class TopSearchItemTile extends StatelessWidget {
  const TopSearchItemTile({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.id,
  }) : super(key: key);

  final String id;
  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final isLandscape = screenwidth > MediaQuery.of(context).size.height;
    final imageWidth = isLandscape ? 146.0 : screenwidth * 0.33;
    final imageHeight = isLandscape ? 82.0 : 72.0;

    return ScaleTap(
      pressedScale: 0.97,
      onTap: () {
        if (id.isNotEmpty) {
          Navigator.push(
            context,
            netflixRoute(ScreenDescription(id: id)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14FFFFFF), width: 0.7),
        ),
        child: Row(
          children: [
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: SmoothNetworkImage(
                imageUrl: imageUrl,
                cacheWidth: 650,
                borderRadius: 8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0x66FFFFFF), width: 1.4),
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
