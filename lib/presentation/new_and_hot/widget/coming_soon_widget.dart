import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import '../../home/widget/custom_button_widget.dart';
import '../../widget/video_widget.dart';

class ComingSoonWidget extends StatelessWidget {
  final String id;
  final String month;
  final String day;
  final String posterPath;
  final String movieName;
  final String decription;

  const ComingSoonWidget({
    Key? key,
    required this.id,
    required this.month,
    required this.day,
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
      padding: const EdgeInsets.only(bottom: 24, right: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left date pillar
          SizedBox(
            width: 55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  month.isNotEmpty ? month : "NĂM",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.isNotEmpty ? day : "2024",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
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
                      icon: Icons.notifications_none,
                      title: "Nhắc tôi",
                      iconSize: 20,
                      textSize: 11,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _navigateToDetail(context),
                      child: const CustomButtonWidget(
                        icon: Icons.info_outline,
                        title: "Chi tiết",
                        iconSize: 20,
                        textSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Sắp ra mắt trên Netflix",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  decription.isNotEmpty
                      ? decription
                      : "Bộ phim hấp dẫn sắp có mặt trên Netflix. Hãy cùng đón xem những tình tiết bất ngờ và kịch tính nhất!",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
