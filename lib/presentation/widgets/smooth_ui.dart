// ============================================================================
// FILE: lib/presentation/widgets/smooth_ui.dart
// MỤC ĐÍCH:
//   Cung cấp bộ thành phần UI dùng chung giúp toàn bộ ứng dụng Nét Lích (Flutter)
//   vận hành mượt mà ở tốc độ khung hình cao trên thiết bị di động:
//     1. NetflixScrollBehavior : Cuộn đàn hồi mượt mà (BouncingScrollPhysics).
//     2. ScaleTap              : Hiệu ứng nhấn thu phóng nhẹ + rung xúc giác (Haptic)
//                                kết hợp hỗ trợ điều hướng phím D-pad cho TV.
//     3. ShimmerBox            : Khung xương tải dữ liệu (Skeleton Shimmer) thay thế
//                                vòng xoay loading gây rối mắt và tốn tài nguyên.
//     4. SmoothNetworkImage    : Tải ảnh poster tối ưu bộ nhớ đệm (cacheWidth) kèm
//                                hiệu ứng hiện dần (fade-in) mượt mà.
//     5. MyListStore           : Quản lý trạng thái "+ Danh sách" & "Nhắc tôi" tức thì.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netflix_clone/core/constants.dart';

/// Hành vi cuộn toàn cục: áp dụng hiệu ứng cuộn đàn hồi mượt mà cho cả danh sách dọc và ngang,
/// đồng thời cho phép kéo bằng cảm ứng hoặc chuột trên mọi nền tảng.
class NetflixScrollBehavior extends MaterialScrollBehavior {
  const NetflixScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// Tạo route chuyển trang mượt mà hỗ trợ vuốt cạnh trái để quay lại trên cả Android & iOS.
Route<T> netflixRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

/// Kho lưu trữ nhẹ trong bộ nhớ cho danh sách yêu thích & nhắc lịch chiếu,
/// giúp giao diện phản hồi ngay lập tức khi người dùng nhấn nút.
class MyListStore {
  static final ValueNotifier<Set<String>> savedIds =
      ValueNotifier<Set<String>>(<String>{});
  static final ValueNotifier<Set<String>> reminderIds =
      ValueNotifier<Set<String>>(<String>{});

  static bool isSaved(String? id) =>
      id != null && id.isNotEmpty && savedIds.value.contains(id);

  static bool isReminded(String? id) =>
      id != null && id.isNotEmpty && reminderIds.value.contains(id);

  static bool toggleSaved(BuildContext context, String? id, {String? title}) {
    if (id == null || id.isEmpty) return false;
    HapticFeedback.lightImpact();
    final next = Set<String>.from(savedIds.value);
    final added = !next.contains(id);
    if (added) {
      next.add(id);
    } else {
      next.remove(id);
    }
    savedIds.value = next;

    _showToast(
      context,
      added
          ? 'Đã thêm ${title != null ? '"$title" ' : ''}vào Danh sách của tôi'
          : 'Đã xóa khỏi Danh sách của tôi',
      icon: added ? Icons.check_circle_rounded : Icons.remove_circle_outline,
    );
    return added;
  }

  static bool toggleReminder(BuildContext context, String? id, {String? title}) {
    if (id == null || id.isEmpty) return false;
    HapticFeedback.lightImpact();
    final next = Set<String>.from(reminderIds.value);
    final added = !next.contains(id);
    if (added) {
      next.add(id);
    } else {
      next.remove(id);
    }
    reminderIds.value = next;

    _showToast(
      context,
      added
          ? 'Đã bật nhắc lịch chiếu${title != null ? ' cho "$title"' : ''}'
          : 'Đã tắt nhắc lịch chiếu',
      icon: added
          ? Icons.notifications_active_rounded
          : Icons.notifications_off_outlined,
    );
    return added;
  }

  static void _showToast(
    BuildContext context,
    String message, {
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xF2222226),
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x26FFFFFF), width: 0.8),
        ),
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: [
            Icon(icon, color: const Color(0xFFE50914), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget bọc tương tác chạm đàn hồi (Scale-down khi chạm tay + Scale-up khi focus TV).
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptic;
  final ValueChanged<bool>? onFocusChanged;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.enableHaptic = true,
    this.onFocusChanged,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _isPressed = false;
  bool _isFocused = false;

  void _triggerTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final targetScale =
        _isPressed ? widget.pressedScale : (_isFocused ? 1.05 : 1.0);

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
        widget.onFocusChanged?.call(focused);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _triggerTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.onTap != null ? _triggerTap : null,
        child: AnimatedScale(
          scale: targetScale,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Khối hiệu ứng ánh sáng quét ngang (Shimmer) mượt mà, bọc trong RepaintBoundary
/// để tách biệt việc vẽ lại khỏi cây giao diện xung quanh.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final slide = (_controller.value * 2.4) - 1.2;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(slide - 0.8, -0.2),
                end: Alignment(slide + 0.8, 0.2),
                colors: const [
                  Color(0xFF16161A),
                  Color(0xFF26262E),
                  Color(0xFF16161A),
                ],
                stops: const [0.1, 0.5, 0.9],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tải và hiển thị ảnh mạng chuẩn HD với bộ lọc mipmap (FilterQuality.medium)
/// và cơ chế tự động fallback về URL gốc nếu link CDN TMDB không tìm thấy ảnh.
class SmoothNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final double borderRadius;
  final Alignment alignment;
  final FilterQuality filterQuality;

  const SmoothNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth = 700,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
  });

  @override
  State<SmoothNetworkImage> createState() => _SmoothNetworkImageState();
}

class _SmoothNetworkImageState extends State<SmoothNetworkImage> {
  bool _useFallback = false;

  @override
  void didUpdateWidget(covariant SmoothNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _useFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = getTmdbFallbackUrl(widget.imageUrl);
    final activeUrl = (_useFallback && fallbackUrl != null)
        ? fallbackUrl
        : widget.imageUrl;

    Widget content = Container(
      color: const Color(0xFF141418),
      child: Image.network(
        activeUrl,
        fit: widget.fit,
        alignment: widget.alignment,
        cacheWidth: widget.cacheWidth,
        filterQuality: widget.filterQuality,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              const ShimmerBox(borderRadius: 0),
              child,
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (!_useFallback && fallbackUrl != null && fallbackUrl != activeUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _useFallback = true);
              }
            });
            return const ShimmerBox(borderRadius: 0);
          }
          return Container(
            color: const Color(0xFF18181E),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  color: Color(0xFF52525E),
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  'NÉT LÍCH',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.borderRadius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: content,
      );
    }

    return content;
  }
}

/// Skeleton mô phỏng Trang Chủ trong lúc đang tải dữ liệu lần đầu.
class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 96, bottom: 100),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 0.76,
            child: ShimmerBox(borderRadius: 18),
          ),
        ),
        const SizedBox(height: 24),
        for (int row = 0; row < 3; row++) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 170, height: 20, borderRadius: 6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) =>
                  const ShimmerBox(width: 124, height: 185, borderRadius: 10),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}

/// Skeleton dạng lưới 3 cột cho màn hình Danh mục / Tìm kiếm.
class GridShimmerSkeleton extends StatelessWidget {
  final int crossAxisCount;

  const GridShimmerSkeleton({super.key, this.crossAxisCount = 3});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 1 / 1.75,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerBox(borderRadius: 10)),
          SizedBox(height: 6),
          ShimmerBox(height: 12, width: 90, borderRadius: 4),
          SizedBox(height: 4),
          ShimmerBox(height: 10, width: 48, borderRadius: 4),
        ],
      ),
    );
  }
}
