import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
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
    this.releaseInfo = 'Sắp ra mắt trên Nét Lích',
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
    return '2026';
  }

  void _navigateToDetail(BuildContext context) {
    if (id.isNotEmpty) {
      Navigator.push(
        context,
        netflixRoute(ScreenDescription(id: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearText = displayYear;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x18FFFFFF), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              VideoWidget(
                imageUrl: posterPath,
                onTap: () => _navigateToDetail(context),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0A0A0E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0x33FFFFFF), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: kNetflixRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        yearText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<Set<String>>(
                valueListenable: MyListStore.reminderIds,
                builder: (context, remindedSet, _) {
                  final reminded = remindedSet.contains(id);
                  return ScaleTap(
                    enableHaptic: false,
                    onTap: () => MyListStore.toggleReminder(
                      context,
                      id,
                      title: movieName,
                    ),
                    child: CustomButtonWidget(
                      icon: reminded
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      title: reminded ? "Đã nhắc" : "Nhắc tôi",
                      iconSize: 21,
                      textSize: 10.5,
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              ScaleTap(
                onTap: () => _navigateToDetail(context),
                child: const CustomButtonWidget(
                  icon: Icons.info_outline_rounded,
                  title: "Chi tiết",
                  iconSize: 21,
                  textSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x26E50914),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: const Color(0x66E50914), width: 0.8),
                ),
                child: const Text(
                  "Sắp Chiếu",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ),
              Text(
                releaseInfo,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD8D8E4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            decription.isNotEmpty
                ? decription
                : "Bộ phim hấp dẫn sắp có mặt trên Nét Lích. Hãy cùng đón xem những tình tiết bất ngờ và kịch tính nhất!",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kGray,
              fontSize: 13,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}
