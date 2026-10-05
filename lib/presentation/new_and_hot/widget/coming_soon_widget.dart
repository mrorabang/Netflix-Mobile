import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import '../../home/widget/custom_button_widget.dart';
import '../../widget/video_widget.dart';

class ComingSoonWidget extends StatelessWidget {
  final String id;
  final String month;
  final String day;
  final String? year;
  final String releaseInfo;
  final String posterPath;
  final String movieName;
  final String decription;

  const ComingSoonWidget({
    Key? key,
    required this.id,
    this.month = '',
    this.day = '',
    this.year,
    this.releaseInfo = 'Sắp ra mắt trên Netflix',
    required this.posterPath,
    required this.movieName,
    required this.decription,
  }) : super(key: key);

  String get displayYear {
    if (year != null && year!.trim().isNotEmpty) {
      return year!.trim();
    }
    if (day.trim().isNotEmpty && day != '2024') {
      return day.trim();
    }
    return '2024';
  }

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
    final yearText = displayYear;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width Video / Poster preview with badges
          Stack(
            children: [
              VideoWidget(
                imageUrl: posterPath,
                onTap: () => _navigateToDetail(context),
              ),
              // Floating Year badge on top-left of poster
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        yearText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title and action buttons row
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
                iconSize: 22,
                textSize: 11,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _navigateToDetail(context),
                child: const CustomButtonWidget(
                  icon: Icons.info_outline,
                  title: "Chi tiết",
                  iconSize: 22,
                  textSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Badges row: Year badge + Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white30, width: 0.8),
                ),
                child: Text(
                  yearText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.5), width: 0.8),
                ),
                child: const Text(
                  "Sắp Chiếu",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                releaseInfo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
    );
  }
}
