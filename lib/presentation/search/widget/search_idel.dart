import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/search/widget/search_title.dart';

class SearchIdelWidget extends StatelessWidget {
  const SearchIdelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchTitleText(
          title: "Tìm Kiếm Hàng Đầu",
        ),
        kHeight20,
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state.isError) {
                return const Center(child: Text("Lỗi khi tải dữ liệu"));
              } else if (state.ideleList.isEmpty) {
                return const Center(child: Text("Danh sách trống"));
              }
              return ListView.separated(
                shrinkWrap: true,
                itemBuilder: (ctx, index) {
                  final movie = state.ideleList[index];
                  return TopSearchItemTile(
                    id: movie.id ?? '',
                    title: movie.title ?? 'Chưa có tiêu đề',
                    imageUrl: resolveImageUrl(movie.posterPath, null),
                  );
                },
                separatorBuilder: (ctx, index) => kHeight20,
                itemCount: state.ideleList.length,
              );
            },
          ),
        )
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
    return InkWell(
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: screenwidth * 0.35,
              height: 72,
              color: Colors.grey[900],
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, color: Colors.grey),
                ),
              ),
            ),
          ),
          kWidth,
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          kWidth,
          const CircleAvatar(
            backgroundColor: kwhiteColor,
            radius: 20,
            child: CircleAvatar(
              backgroundColor: kBlackColor,
              radius: 18,
              child: Icon(
                CupertinoIcons.play_fill,
                color: kwhiteColor,
                size: 18,
              ),
            ),
          )
        ],
      ),
    );
  }
}
