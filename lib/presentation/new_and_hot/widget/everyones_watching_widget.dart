import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import '../../home/widget/custom_button_widget.dart';
import '../../widget/video_widget.dart';

class EveryOnesWatchingWidget extends StatelessWidget {
  final String id;
  final String posterPath;
  final String movieName;
  final String decription;

  const EveryOnesWatchingWidget({
    Key? key,
    this.id = '',
    required this.posterPath,
    required this.movieName,
    required this.decription,
  }) : super(key: key);

  void _navigateToDetail(BuildContext context) {
    if (id.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ScreenDescription(id: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoWidget(
            imageUrl: posterPath,
            onTap: () => _navigateToDetail(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToDetail(context),
                  child: Text(
                    movieName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const CustomButtonWidget(
                icon: Icons.share,
                title: "Chia sẻ",
                iconSize: 22,
                textSize: 11,
              ),
              const SizedBox(width: 14),
              const CustomButtonWidget(
                icon: Icons.add,
                title: "Danh sách",
                iconSize: 22,
                textSize: 11,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _navigateToDetail(context),
                child: const CustomButtonWidget(
                  icon: Icons.play_arrow,
                  title: "Phát",
                  iconSize: 24,
                  textSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  "HD",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Đang thịnh hành nhất",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            decription.isNotEmpty
                ? decription
                : "Phim đang nhận được nhiều sự quan tâm từ khán giả với nội dung lôi cuốn, kịch tính và hấp dẫn từng khoảnh khắc.",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
