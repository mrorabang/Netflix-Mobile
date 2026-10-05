import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/domain/core/debounce/debounce.dart';
import 'package:netflix_clone/domain/search/model/search_resp/search_resp.dart';
import 'package:netflix_clone/presentation/category/screen_category_movies.dart';
import 'package:netflix_clone/presentation/search/widget/search_idel.dart';
import 'package:netflix_clone/presentation/search/widget/search_result.dart';

class ScreenSearch extends StatefulWidget {
  const ScreenSearch({Key? key}) : super(key: key);

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

class _ScreenSearchState extends State<ScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 600);

  String _selectedType = 'all'; // 'all', 'single', 'series', 'hoathinh'
  String? _selectedGenreSlug;
  String? _selectedGenreName;
  String? _selectedCountrySlug;
  String? _selectedCountryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<SearchBloc>(context).add(const Initalize());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = 'all';
      _selectedGenreSlug = null;
      _selectedGenreName = null;
      _selectedCountrySlug = null;
      _selectedCountryName = null;
    });
  }

  List<SearchResultData> _filterResults(List<SearchResultData> originalList) {
    if (_selectedType == 'all' &&
        _selectedGenreSlug == null &&
        _selectedCountrySlug == null) {
      return originalList;
    }
    return originalList.where((item) {
      // Type filter
      if (_selectedType != 'all') {
        if (_selectedType == 'single') {
          if (item.type != null &&
              item.type != 'single' &&
              !(item.episodeCurrent?.toLowerCase().contains('full') ?? false)) {
            return false;
          }
        } else if (_selectedType == 'series') {
          if (item.type != null && item.type != 'series') return false;
        } else if (_selectedType == 'hoathinh') {
          if (item.type != null && item.type != 'hoathinh') return false;
        }
      }

      // Genre filter
      if (_selectedGenreSlug != null) {
        final hasCategory = item.categories.any((c) {
          final cLow = c.toLowerCase();
          final slugLow = _selectedGenreSlug!.toLowerCase();
          final nameLow = (_selectedGenreName ?? '').toLowerCase();
          return cLow == slugLow ||
              cLow.contains(slugLow) ||
              (nameLow.isNotEmpty && cLow.contains(nameLow));
        });
        if (!hasCategory) return false;
      }

      // Country filter
      if (_selectedCountrySlug != null) {
        final hasCountry = item.countries.any((c) {
          final cLow = c.toLowerCase();
          final slugLow = _selectedCountrySlug!.toLowerCase();
          final nameLow = (_selectedCountryName ?? '').toLowerCase();
          return cLow == slugLow ||
              cLow.contains(slugLow) ||
              (nameLow.isNotEmpty && cLow.contains(nameLow));
        });
        if (!hasCountry) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = _selectedType != 'all' ||
        _selectedGenreSlug != null ||
        _selectedCountrySlug != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar row with Back button
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.white70,
                        size: 20,
                      ),
                      suffixIcon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.white54,
                        size: 18,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      placeholder: "Tìm kiếm phim, diễn viên...",
                      placeholderStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          BlocProvider.of<SearchBloc>(context)
                              .add(const Initalize());
                          return;
                        }
                        _debouncer.run(() {
                          BlocProvider.of<SearchBloc>(context).add(
                            SerachMovie(movieQuery: value.trim()),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(
                      label: "Tất cả",
                      isSelected: !hasActiveFilter,
                      onTap: _clearFilters,
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      label: "Phim Lẻ",
                      isSelected: _selectedType == 'single',
                      onTap: () {
                        setState(() {
                          _selectedType =
                              _selectedType == 'single' ? 'all' : 'single';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      label: "Phim Bộ",
                      isSelected: _selectedType == 'series',
                      onTap: () {
                        setState(() {
                          _selectedType =
                              _selectedType == 'series' ? 'all' : 'series';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      label: "Hoạt Hình",
                      isSelected: _selectedType == 'hoathinh',
                      onTap: () {
                        setState(() {
                          _selectedType =
                              _selectedType == 'hoathinh' ? 'all' : 'hoathinh';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      label: _selectedGenreName != null
                          ? "Thể loại: $_selectedGenreName ✕"
                          : "Thể Loại ▾",
                      isSelected: _selectedGenreSlug != null,
                      onTap: () {
                        if (_selectedGenreSlug != null) {
                          setState(() {
                            _selectedGenreSlug = null;
                            _selectedGenreName = null;
                          });
                        } else {
                          showTheLoaiBottomSheet(
                            context,
                            onSelected: (slug, name) {
                              setState(() {
                                _selectedGenreSlug = slug;
                                _selectedGenreName = name;
                              });
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildChip(
                      label: _selectedCountryName != null
                          ? "Quốc gia: $_selectedCountryName ✕"
                          : "Quốc Gia ▾",
                      isSelected: _selectedCountrySlug != null,
                      onTap: () {
                        if (_selectedCountrySlug != null) {
                          setState(() {
                            _selectedCountrySlug = null;
                            _selectedCountryName = null;
                          });
                        } else {
                          showQuocGiaBottomSheet(
                            context,
                            onSelected: (slug, name) {
                              setState(() {
                                _selectedCountrySlug = slug;
                                _selectedCountryName = name;
                              });
                            },
                          );
                        }
                      },
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                "Xóa lọc",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Content: Idle list or Search results
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      );
                    }
                    if (_searchController.text.trim().isEmpty &&
                        state.searchResultList.isEmpty) {
                      return const SearchIdelWidget();
                    }

                    final filtered = _filterResults(state.searchResultList);
                    return SearchResult(
                      items: filtered,
                      onClearFilter: _clearFilters,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
