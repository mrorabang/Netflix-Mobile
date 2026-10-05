import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/core/strings.dart';
import 'package:netflix_clone/presentation/decriptions/Screen_decription.dart';

const Map<String, String> theLoaiNames = {
  'hanh-dong': 'Hành Động',
  'tinh-cam': 'Tình Cảm',
  'hai-huoc': 'Hài Hước',
  'co-trang': 'Cổ Trang',
  'tam-ly': 'Tâm Lý',
  'hinh-su': 'Hình Sự',
  'chien-tranh': 'Chiến Tranh',
  'the-thao': 'Thể Thao',
  'vo-thuat': 'Võ Thuật',
  'vien-tuong': 'Viễn Tưởng',
  'phieu-luu': 'Phiêu Lưu',
  'khoa-hoc': 'Khoa Học',
  'kinh-di': 'Kinh Dị',
  'am-nhac': 'Âm Nhạc',
  'than-thoai': 'Thần Thoại',
  'tai-lieu': 'Tài Liệu',
  'gia-dinh': 'Gia Đình',
  'chinh-kich': 'Chính Kịch',
  'bi-an': 'Bí Ẩn',
  'hoc-duong': 'Học Đường',
  'kinh-dien': 'Kinh Điển',
  'phim-18': 'Phim 18+',
  'hoat-hinh': 'Hoạt Hình',
  'mien-tay': 'Miền Tây',
};

enum CategoryType {
  phimBo,
  phimLe,
  theLoai,
}

class CategoryMovieItem {
  final String id;
  final String name;
  final String? originName;
  final String posterUrl;
  final String? year;
  final String? episodeCurrent;
  final String? quality;

  CategoryMovieItem({
    required this.id,
    required this.name,
    this.originName,
    required this.posterUrl,
    this.year,
    this.episodeCurrent,
    this.quality,
  });

  factory CategoryMovieItem.fromJson(Map<String, dynamic> json, [String? cdn]) {
    final poster = resolveImageUrl(json['poster_url'], json['thumb_url'], cdn);
    return CategoryMovieItem(
      id: json['slug']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      originName: json['origin_name'] as String?,
      posterUrl: poster,
      year: json['year']?.toString(),
      episodeCurrent: json['episode_current'] as String?,
      quality: json['quality'] as String?,
    );
  }
}

class ScreenCategoryMovies extends StatefulWidget {
  final String initialTitle;
  final CategoryType type;
  final String? initialSlug;

  const ScreenCategoryMovies({
    Key? key,
    required this.initialTitle,
    required this.type,
    this.initialSlug,
  }) : super(key: key);

  @override
  State<ScreenCategoryMovies> createState() => _ScreenCategoryMoviesState();
}

class _ScreenCategoryMoviesState extends State<ScreenCategoryMovies> {
  late CategoryType _currentType;
  late String _currentSlug;
  late String _title;

  final List<CategoryMovieItem> _movies = [];
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;

  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 12000,
    receiveTimeout: 12000,
  ));

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
    _currentSlug = widget.initialSlug ?? 'hanh-dong';
    _title = widget.initialTitle;

    _scrollController.addListener(_onScroll);
    _fetchMovies(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 350) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMovies(isRefresh: false);
      }
    }
  }

  String _buildUrl(int page) {
    switch (_currentType) {
      case CategoryType.phimBo:
        return 'https://phimapi.com/v1/api/danh-sach/phim-bo?page=$page&limit=28';
      case CategoryType.phimLe:
        return 'https://phimapi.com/v1/api/danh-sach/phim-le?page=$page&limit=28';
      case CategoryType.theLoai:
        return 'https://phimapi.com/v1/api/the-loai/$_currentSlug?page=$page&limit=28';
    }
  }

  String _buildFallbackUrl(int page) {
    switch (_currentType) {
      case CategoryType.phimBo:
        return '$kBaseUrl/api/danh-sach/phim-bo?page=$page&limit=28';
      case CategoryType.phimLe:
        return '$kBaseUrl/api/danh-sach/phim-le?page=$page&limit=28';
      case CategoryType.theLoai:
        return '$kBaseUrl/api/the-loai/$_currentSlug?page=$page&limit=28';
    }
  }

  Future<void> _fetchMovies({required bool isRefresh}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final targetPage = isRefresh ? 1 : _page + 1;

    try {
      List<dynamic> items = [];
      String? cdn;

      // 1. Try Primary URL
      try {
        final url = _buildUrl(targetPage);
        final response = await _dio.get(url);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final rawData = response.data;
          final responseData = (rawData is Map && rawData['data'] is Map)
              ? rawData['data']
              : rawData;
          items = (responseData['items'] as List?) ??
              (responseData['results'] as List?) ??
              [];
          cdn = responseData['APP_DOMAIN_CDN_IMAGE'] as String? ??
              responseData['pathImage'] as String?;
        }
      } catch (primaryErr) {
        log("Primary API failed: $primaryErr");
      }

      // 2. If primary items is empty, try Fallback URL
      if (items.isEmpty) {
        try {
          final fallbackUrl = _buildFallbackUrl(targetPage);
          final response = await _dio.get(fallbackUrl);
          if (response.statusCode == 200 || response.statusCode == 201) {
            final rawData = response.data;
            final responseData = (rawData is Map && rawData['data'] is Map)
                ? rawData['data']
                : rawData;
            items = (responseData['items'] as List?) ??
                (responseData['results'] as List?) ??
                [];
            cdn = responseData['APP_DOMAIN_CDN_IMAGE'] as String? ??
                responseData['pathImage'] as String?;
          }
        } catch (fallbackErr) {
          log("Fallback API failed: $fallbackErr");
        }
      }

      final newItems = items
          .map((e) =>
              CategoryMovieItem.fromJson(e as Map<String, dynamic>, cdn))
          .toList();

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _movies.clear();
          }
          _movies.addAll(newItems);
          _page = targetPage;
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = false;
          _hasMore = newItems.isNotEmpty && newItems.length >= 20;
        });
      }
    } catch (e) {
      log("Error fetching category movies: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          if (isRefresh) {
            _hasError = _movies.isEmpty;
          }
        });
      }
    }
  }

  void _switchType(CategoryType newType, {String? slug, String? title}) {
    if (_currentType == newType && slug == _currentSlug && !widget.key.toString().contains('force')) {
      return;
    }
    setState(() {
      _currentType = newType;
      if (slug != null) _currentSlug = slug;
      if (title != null) {
        _title = title;
      } else {
        switch (newType) {
          case CategoryType.phimBo:
            _title = "Phim Bộ";
            break;
          case CategoryType.phimLe:
            _title = "Phim Lẻ";
            break;
          case CategoryType.theLoai:
            _title = theLoaiNames[_currentSlug] ?? "Thể Loại";
            break;
        }
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _fetchMovies(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          const Icon(Icons.cast, color: Colors.white, size: 24),
          const SizedBox(width: 14),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                "N",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter switcher row
          _buildFilterBar(),
          // Movie Grid
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main 3 categories row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildTypeChip(
                  label: "Phim Bộ",
                  isSelected: _currentType == CategoryType.phimBo,
                  onTap: () => _switchType(CategoryType.phimBo),
                ),
                const SizedBox(width: 8),
                _buildTypeChip(
                  label: "Phim Lẻ",
                  isSelected: _currentType == CategoryType.phimLe,
                  onTap: () => _switchType(CategoryType.phimLe),
                ),
                const SizedBox(width: 8),
                _buildTypeChip(
                  label: _currentType == CategoryType.theLoai
                      ? "Thể loại: ${theLoaiNames[_currentSlug] ?? 'Chọn'}"
                      : "Thể Loại ▾",
                  isSelected: _currentType == CategoryType.theLoai,
                  onTap: () {
                    showTheLoaiBottomSheet(
                      context,
                      currentSlug: _currentSlug,
                      onSelected: (slug, name) {
                        _switchType(CategoryType.theLoai, slug: slug, title: name);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // If genre mode is active, display horizontal scrollable genre quick-pick chips
          if (_currentType == CategoryType.theLoai) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: theLoaiNames.entries.map((entry) {
                  final isSelected = entry.key == _currentSlug;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (_) {
                        _switchType(
                          CategoryType.theLoai,
                          slug: entry.key,
                          title: entry.value,
                        );
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white30,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _movies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_hasError && _movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            const Text(
              "Không thể tải danh sách phim",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _fetchMovies(isRefresh: true),
              child: const Text("Thử lại"),
            )
          ],
        ),
      );
    }

    if (_movies.isEmpty) {
      return RefreshIndicator(
        color: Colors.red,
        backgroundColor: Colors.black,
        onRefresh: () => _fetchMovies(isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_filter_outlined,
                      color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    "Không có phim nào trong danh mục này",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _fetchMovies(isRefresh: true),
                    child: const Text("Tải lại"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.red,
      backgroundColor: Colors.black,
      onRefresh: () => _fetchMovies(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 12,
                childAspectRatio: 1 / 1.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final movie = _movies[index];
                  return _buildMovieCard(movie);
                },
                childCount: _movies.length,
              ),
            ),
          ),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          if (!_hasMore && _movies.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "Đã hiển thị hết danh sách",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(CategoryMovieItem movie) {
    return GestureDetector(
      onTap: () {
        if (movie.id.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ScreenDescription(id: movie.id),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster image with rounded corners and badges
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey[900],
                    child: Image.network(
                      movie.posterUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Quality badge (HD / FHD)
                  if (movie.quality != null && movie.quality!.isNotEmpty)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          movie.quality!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Episode badge (e.g. Tập 12 / Hoàn tất)
                  if (movie.episodeCurrent != null &&
                      movie.episodeCurrent!.isNotEmpty)
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          movie.episodeCurrent!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Movie title
          Text(
            movie.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          // Release year
          if (movie.year != null && movie.year!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              movie.year!,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hiển thị Modal BottomSheet chọn thể loại phong cách Netflix
void showTheLoaiBottomSheet(
  BuildContext context, {
  String? currentSlug,
  Function(String slug, String name)? onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    "Chọn Thể Loại",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Grid of Genres
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                ),
                itemCount: theLoaiNames.length,
                itemBuilder: (context, index) {
                  final entry = theLoaiNames.entries.elementAt(index);
                  final slug = entry.key;
                  final name = entry.value;
                  final isSelected = slug == currentSlug;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (onSelected != null) {
                        onSelected(slug, name);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScreenCategoryMovies(
                              initialTitle: name,
                              type: CategoryType.theLoai,
                              initialSlug: slug,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red[800]
                            : const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
