import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netflix_clone/core/colors/colors.dart';

ValueNotifier<int> indexChangeNotifier = ValueNotifier(0);

class _NavItemSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<_NavItemSpec> _navItems = [
  _NavItemSpec(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Trang chủ',
  ),
  _NavItemSpec(
    icon: Icons.local_fire_department_outlined,
    activeIcon: Icons.local_fire_department_rounded,
    label: 'Mới & Hot',
  ),
  _NavItemSpec(
    icon: CupertinoIcons.search,
    activeIcon: CupertinoIcons.search,
    label: 'Tìm kiếm',
  ),
  _NavItemSpec(
    icon: Icons.download_outlined,
    activeIcon: Icons.download_rounded,
    label: 'Tải xuống',
  ),
];

class BottomNaviagtionWidget extends StatelessWidget {
  const BottomNaviagtionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: indexChangeNotifier,
      builder: (context, currentIndex, _) {
        return RepaintBoundary(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xE00C0C12),
                  border: Border(
                    top: BorderSide(color: Color(0x1FFFFFFF), width: 0.6),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isSelected = index == currentIndex;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (indexChangeNotifier.value != index) {
                                HapticFeedback.selectionClick();
                                indexChangeNotifier.value = index;
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.12 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 23,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF7E7E8F),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF7E7E8F),
                                    letterSpacing: 0.1,
                                  ),
                                  child: Text(item.label),
                                ),
                                const SizedBox(height: 3),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: isSelected ? 14 : 0,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: kNetflixRed,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
