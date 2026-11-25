import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';
import 'package:share_plus/share_plus.dart';
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
        netflixRoute(ScreenDescription(id: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScaleTap(
                onTap: () {
                  Share.share(
                    'Xem ngay "$movieName" đang cực hot trên Nét Lích!',
                  );
                },
                child: const CustomButtonWidget(
                  icon: Icons.share_outlined,
                  title: "Chia sẻ",
                  iconSize: 21,
                  textSize: 10.5,
                ),
              ),
              const SizedBox(width: 14),
              ValueListenableBuilder<Set<String>>(
                valueListenable: MyListStore.savedIds,
                builder: (context, savedSet, _) {
                  final saved = savedSet.contains(id);
                  return ScaleTap(
                    enableHaptic: false,
                    onTap: () => MyListStore.toggleSaved(
                      context,
                      id,
                      title: movieName,
                    ),
                    child: CustomButtonWidget(
                      icon: saved ? Icons.check_rounded : Icons.add_rounded,
                      title: saved ? "Đã lưu" : "Danh sách",
                      iconSize: 22,
                      textSize: 10.5,
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              ScaleTap(
                onTap: () => _navigateToDetail(context),
                child: const CustomButtonWidget(
                  icon: Icons.play_arrow_rounded,
                  title: "Phát",
                  iconSize: 23,
                  textSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0x4DFFFFFF), width: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "FHD",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "🔥 Đang thịnh hành nhất",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF5252),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            decription.isNotEmpty
                ? decription
                : "Phim đang nhận được nhiều sự quan tâm từ khán giả với nội dung lôi cuốn, kịch tính và hấp dẫn từng khoảnh khắc.",
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
