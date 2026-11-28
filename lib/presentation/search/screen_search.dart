import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/search/search_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/domain/core/debounce/debounce.dart';
import 'package:netflix_clone/domain/search/model/search_resp/search_resp.dart';
import 'package:netflix_clone/presentation/category/screen_category_movies.dart';
import 'package:netflix_clone/presentation/search/widget/search_idel.dart';
import 'package:netflix_clone/presentation/search/widget/search_result.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class ScreenSearch extends StatefulWidget {
  final bool isEmbeddedTab;

  const ScreenSearch({
    Key? key,
    this.isEmbeddedTab = false,
  }) : super(key: key);

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

class _ScreenSearchState extends State<ScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  String _selectedType = 'all';
  String? _selectedGenreSlug;
  String? _selectedGenreName;
  String? _selectedCountrySlug;
  String? _selectedCountryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<SearchBloc>();
      if (bloc.state.ideleList.isEmpty && !bloc.state.isLoading) {
        bloc.add(const Initalize());
      }
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
        backgroundColor: backgrounndColor,
        body: SafeArea(
          bottom: !widget.isEmbeddedTab,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!widget.isEmbeddedTab) ...[
                      ScaleTap(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: CupertinoSearchTextField(
                        controller: _searchController,
                        backgroundColor: kCardColor,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            CupertinoIcons.search,
                            color: Color(0xFFB0B0C0),
                            size: 19,
                          ),
                        ),
                        suffixIcon: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Color(0xFF8E8E9E),
                          size: 18,
                        ),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14.5),
                        placeholder: "Tìm phim, diễn viên, đạo diễn...",
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF78788A),
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            context.read<SearchBloc>().add(const Initalize());
                            setState(() {});
                            return;
                          }
                          _debouncer.run(() {
                            if (!mounted) return;
                            context.read<SearchBloc>().add(
                                  SerachMovie(movieQuery: value.trim()),
                                );
                          });
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                if (TvMode.isTv(context)) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          "Gợi ý nhanh TV:  ",
                          style: TextStyle(
                            fontSize: 12,
                            color: kGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        for (final kw in const [
                          'Hành Động',
                          'Hàn Quốc',
                          'Cổ Trang',
                          'Kinh Dị',
                          'Hoạt Hình',
                          'Âu Mỹ',
                          'Việt Nam',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ScaleTap(
                              showFocusRing: true,
                              focusBorderRadius: 16,
                              onTap: () {
                                _searchController.text = kw;
                                context
                                    .read<SearchBloc>()
                                    .add(SerachMovie(movieQuery: kw));
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0x26FFFFFF)),
                                ),
                                child: Text(
                                  kw,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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
                            _selectedType = _selectedType == 'hoathinh'
                                ? 'all'
                                : 'hoathinh';
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
                        ScaleTap(
                          onTap: _clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x26E50914),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0x80E50914), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close,
                                    size: 14, color: kNetflixRed),
                                SizedBox(width: 4),
                                Text(
                                  "Xóa lọc",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w700,
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
                const SizedBox(height: 12),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const GridShimmerSkeleton();
                      }
                      if (_searchController.text.trim().isEmpty &&
                          state.searchResultList.isEmpty) {
                        return SearchIdelWidget(
                          bottomPadding: widget.isEmbeddedTab ? 90 : 16,
                        );
                      }

                      final filtered = _filterResults(state.searchResultList);
                      return SearchResult(
                        items: filtered,
                        onClearFilter: _clearFilters,
                        bottomPadding: widget.isEmbeddedTab ? 90 : 16,
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
    return ScaleTap(
      pressedScale: 0.94,
      showFocusRing: true,
      focusBorderRadius: 20,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : kSurfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0x26FFFFFF),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFFE2E2EC),
          ),
        ),
      ),
    );
  }
}
