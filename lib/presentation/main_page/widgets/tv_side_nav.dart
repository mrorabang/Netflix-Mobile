// ============================================================================
// FILE: lib/presentation/main_page/widgets/tv_side_nav.dart
// MỤC ĐÍCH:
//   Thanh điều hướng dọc bên trái (Side Navigation Rail) chuẩn giao diện Netflix TV
//   dành riêng cho Android TV / TV Box / màn hình lớn ngang.
//   Cho phép người dùng bấm phím D-Pad Trái từ bất kỳ hàng phim nào để chuyển nhanh
//   giữa: Tìm kiếm, Trang chủ, Mới & Hot, Phim Bộ, Phim Lẻ, Thể Loại, Quốc Gia và Tải xuống.
//   Khi được trỏ bằng Remote, thanh tự động mở rộng mượt mà để hiện nhãn tiếng Việt.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/presentation/category/screen_category_movies.dart';
import 'package:netflix_clone/presentation/main_page/widgets/bottom_nav.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class TvSideNavigationRail extends StatefulWidget {
  const TvSideNavigationRail({super.key});

  @override
  State<TvSideNavigationRail> createState() => _TvSideNavigationRailState();
}

class _TvSideNavigationRailState extends State<TvSideNavigationRail> {
  bool _railHasFocus = false;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      onFocusChange: (hasFocus) {
        setState(() => _railHasFocus = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: _railHasFocus ? 196 : 74,
        decoration: const BoxDecoration(
          color: Color(0xF208080D),
          border: Border(
            right: BorderSide(color: Color(0x1FFFFFFF), width: 0.8),
          ),
        ),
        child: SafeArea(
          right: false,
          child: ValueListenableBuilder<int>(
            valueListenable: indexChangeNotifier,
            builder: (context, currentIndex, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  // Logo Nét Lích trên đầu thanh TV Rail
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/netflix_logo.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text(
                            "N",
                            style: TextStyle(
                              color: kNetflixRed,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        if (_railHasFocus) ...[
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Nét Lích TV",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Danh sách các mục điều hướng TV
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          _TvRailItem(
                            icon: CupertinoIcons.search,
                            label: "Tìm kiếm",
                            expanded: _railHasFocus,
                            isSelected: currentIndex == 2,
                            onTap: () => indexChangeNotifier.value = 2,
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.home_rounded,
                            label: "Trang chủ",
                            expanded: _railHasFocus,
                            isSelected: currentIndex == 0,
                            onTap: () => indexChangeNotifier.value = 0,
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.local_fire_department_rounded,
                            label: "Mới & Hot",
                            expanded: _railHasFocus,
                            isSelected: currentIndex == 1,
                            onTap: () => indexChangeNotifier.value = 1,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                                color: Color(0x1FFFFFFF), height: 1),
                          ),
                          _TvRailItem(
                            icon: Icons.tv_rounded,
                            label: "Phim Bộ",
                            expanded: _railHasFocus,
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                netflixRoute(
                                  const ScreenCategoryMovies(
                                    initialTitle: "Phim Bộ",
                                    type: CategoryType.phimBo,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.movie_creation_outlined,
                            label: "Phim Lẻ",
                            expanded: _railHasFocus,
                            isSelected: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                netflixRoute(
                                  const ScreenCategoryMovies(
                                    initialTitle: "Phim Lẻ",
                                    type: CategoryType.phimLe,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.grid_view_rounded,
                            label: "Thể Loại",
                            expanded: _railHasFocus,
                            isSelected: false,
                            onTap: () => showTheLoaiBottomSheet(context),
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.public_rounded,
                            label: "Quốc Gia",
                            expanded: _railHasFocus,
                            isSelected: false,
                            onTap: () => showQuocGiaBottomSheet(context),
                          ),
                          const SizedBox(height: 6),
                          _TvRailItem(
                            icon: Icons.groups_rounded,
                            label: "Party",
                            expanded: _railHasFocus,
                            isSelected: currentIndex == 3,
                            onTap: () => indexChangeNotifier.value = 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TvRailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvRailItem({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvRailItem> createState() => _TvRailItemState();
}

class _TvRailItemState extends State<_TvRailItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      pressedScale: 0.96,
      enableHaptic: false,
      onFocusChanged: (f) => setState(() => _isFocused = f),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _isFocused
              ? Colors.white
              : (widget.isSelected
                  ? const Color(0x2EE50914)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? Colors.white
                : (widget.isSelected
                    ? const Color(0x80E50914)
                    : Colors.transparent),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 22,
              color: _isFocused
                  ? Colors.black
                  : (widget.isSelected
                      ? Colors.white
                      : const Color(0xFF9A9AAA)),
            ),
            if (widget.expanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: _isFocused || widget.isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: _isFocused
                        ? Colors.black
                        : (widget.isSelected
                            ? Colors.white
                            : const Color(0xFFC4C4D4)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
