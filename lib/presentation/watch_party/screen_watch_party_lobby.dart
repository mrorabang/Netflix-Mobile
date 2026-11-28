import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflix_clone/application/home/home_bloc.dart';
import 'package:netflix_clone/core/colors/colors.dart';
import 'package:netflix_clone/core/constants.dart';
import 'package:netflix_clone/core/watch_party/watch_party_config.dart';
import 'package:netflix_clone/domain/core/di/injectable.dart';
import 'package:netflix_clone/domain/description/description_service.dart';
import 'package:netflix_clone/domain/new_and_hot/model/discover.dart';
import 'package:netflix_clone/domain/watch_party/models/watch_party_models.dart';
import 'package:netflix_clone/infrastructure/watch_party/watch_party_service.dart';
import 'package:netflix_clone/presentation/watch_party/screen_watch_party_room.dart';
import 'package:netflix_clone/presentation/widgets/smooth_ui.dart';

class ScreenWatchPartyLobby extends StatefulWidget {
  final String? initialMovieId;
  final String? initialMovieTitle;
  final String? initialPosterUrl;
  final String? initialStreamUrl;
  final bool isEmbeddedTab;

  const ScreenWatchPartyLobby({
    super.key,
    this.initialMovieId,
    this.initialMovieTitle,
    this.initialPosterUrl,
    this.initialStreamUrl,
    this.isEmbeddedTab = false,
  });

  @override
  State<ScreenWatchPartyLobby> createState() => _ScreenWatchPartyLobbyState();
}

class _ScreenWatchPartyLobbyState extends State<ScreenWatchPartyLobby> {
  final _service = WatchPartyService.instance;
  final _searchController = TextEditingController();

  List<WatchPartyRoom> _rooms = [];
  bool _isConnected = false;
  bool _isLoading = true;
  String _searchQuery = '';
  bool _navigatedToRoom = false;

  // Pending create payload in case ALREADY_HAS_ROOM triggers
  Map<String, dynamic>? _pendingCreatePayload;
  String? _pendingJoinRoomId;

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _isConnected = _service.isConnected;
    _service.connect();

    _subs.add(_service.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
        if (connected) _isLoading = false;
      });
    }));

    _subs.add(_service.lobbyRoomsStream.listen((rooms) {
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    }));

    _subs.add(_service.roomCreatedStream.listen((room) {
      _openRoom(room);
    }));

    _subs.add(_service.roomStateStream.listen((room) {
      _openRoom(room);
    }));

    _subs.add(_service.roomErrorStream.listen(_handleRoomError));

    _refreshRooms();

    if (widget.initialMovieId != null && widget.initialMovieId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCreateRoomSheet();
      });
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshRooms() async {
    setState(() => _isLoading = true);
    await _service.fetchLobbyRooms();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openRoom(WatchPartyRoom room) {
    if (!mounted || _navigatedToRoom) return;
    _navigatedToRoom = true;
    Navigator.push(
      context,
      netflixRoute(ScreenWatchPartyRoom(initialRoom: room)),
    ).then((_) {
      _navigatedToRoom = false;
      if (mounted) {
        _refreshRooms();
      }
    });
  }

  void _handleRoomError(RoomErrorEvent err) {
    if (!mounted) return;
    switch (err.code) {
      case 'ALREADY_HAS_ROOM':
        _showExistingRoomConflictDialog(err.existingRoomId);
        break;
      case 'INVALID_PASSCODE':
        _showSnack('Mã PIN không chính xác. Vui lòng thử lại.', isError: true);
        if (_pendingJoinRoomId != null) {
          _showPasscodeDialog(_pendingJoinRoomId!);
        }
        break;
      case 'RATE_LIMITED':
        final wait = err.retryAfterSec ?? 60;
        _showSnack(
          'Bạn đã nhập sai mã PIN quá nhiều lần. Vui lòng thử lại sau ${wait}s.',
          isError: true,
        );
        break;
      case 'ROOM_FULL':
        _showSnack('Phòng đã đầy (tối đa 5 người).', isError: true);
        break;
      case 'KICKED_FROM_ROOM':
        _showSnack('Bạn không thể vào lại phòng đã bị mời ra.', isError: true);
        break;
      default:
        _showSnack(err.message, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kNetflixRed : kSurfaceColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showExistingRoomConflictDialog(String? existingRoomId) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Bạn đang có phòng hoạt động',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          existingRoomId != null
              ? 'Mỗi tài khoản chỉ có thể tạo hoặc tham gia 1 phòng tại một thời điểm (Mã: $existingRoomId).'
              : 'Mỗi tài khoản chỉ có thể tạo hoặc tham gia 1 phòng tại một thời điểm.',
          style: const TextStyle(color: kGray, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (existingRoomId != null && existingRoomId.isNotEmpty) {
                _service.joinRoom(roomId: existingRoomId);
              }
            },
            child: const Text(
              'Quay lại phòng hiện tại',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNetflixRed),
            onPressed: () {
              Navigator.pop(ctx);
              final payload = _pendingCreatePayload;
              if (payload != null) {
                _service.createRoom(
                  movieId: payload['movieId'] as String,
                  movieTitle: payload['movieTitle'] as String,
                  posterUrl: payload['posterUrl'] as String,
                  streamUrl: payload['streamUrl'] as String,
                  roomName: payload['roomName'] as String,
                  visibility: payload['visibility'] as String,
                  passcode: payload['passcode'] as String?,
                  forceCloseOldRoom: true,
                );
              }
            },
            child: const Text(
              'Đóng phòng cũ & Tạo phòng mới',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasscodeDialog(String roomId) async {
    final pinController = TextEditingController();
    _pendingJoinRoomId = roomId;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Phòng riêng tư',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập mã PIN 4 chữ số để vào phòng $roomId:',
              style: const TextStyle(color: kGray, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: kCardColor,
                hintText: '••••',
                hintStyle: const TextStyle(color: kGray),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNetflixRed),
            onPressed: () {
              final pin = pinController.text.trim();
              if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                _showSnack('Mã PIN phải gồm đúng 4 chữ số.', isError: true);
                return;
              }
              Navigator.pop(ctx);
              _service.joinRoom(roomId: roomId, passcode: pin);
            },
            child: const Text(
              'Vào phòng',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showServerConfigDialog() async {
    final urlCtrl = TextEditingController(text: WatchPartyConfig.serverUrl);
    final nameCtrl = TextEditingController(text: _service.username);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Cài đặt Watch Party',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tên hiển thị của bạn',
                labelStyle: const TextStyle(color: kGray),
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Server URL',
                labelStyle: const TextStyle(color: kGray),
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: kGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNetflixRed),
            onPressed: () {
              _service.username = nameCtrl.text;
              _service.reconnectWithUrl(urlCtrl.text);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Lưu & Kết nối',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRoomSheet() async {
    final homeState = context.read<HomeBloc>().state;
    final availableMovies = <HotAndNewData>[
      ...homeState.trendingMovieList,
      ...homeState.pastYearMovieList,
    ].where((m) => (m.id ?? '').isNotEmpty).toList();

    String selectedId = widget.initialMovieId ??
        (availableMovies.isNotEmpty
            ? (availableMovies.first.id ?? 'demo-movie')
            : 'demo-movie');
    String selectedTitle = widget.initialMovieTitle ??
        (availableMovies.isNotEmpty
            ? (availableMovies.first.title ?? 'Phim Nét Lích')
            : 'Phim Nét Lích');
    String selectedPoster = widget.initialPosterUrl ??
        (availableMovies.isNotEmpty
            ? resolveImageUrl(availableMovies.first.posterPath, null)
            : mainImage);
    String selectedStreamUrl = widget.initialStreamUrl ?? '';

    final roomNameController = TextEditingController(
      text: 'Xem chung cùng ${_service.username}',
    );
    final pinController = TextEditingController();
    final movieSearchController = TextEditingController();
    final dio = Dio(BaseOptions(
      connectTimeout: 8000,
      receiveTimeout: 8000,
    ));

    bool isPrivate = false;
    bool isSubmitting = false;
    bool showMovieSearch = widget.initialMovieId == null || widget.initialMovieId!.isEmpty;
    bool isSearchingMovies = false;
    bool isLoadingMovieDetail = false;
    List<Map<String, dynamic>> searchResults = availableMovies
        .take(10)
        .map((m) => {
              'slug': m.id ?? '',
              'name': m.title ?? 'Phim',
              'poster_url': resolveImageUrl(m.posterPath, null),
              'year': '',
            })
        .toList();
    Timer? searchDebounce;

    Future<void> runMovieSearch(
      String query,
      void Function(void Function()) setModalState,
    ) async {
      setModalState(() => isSearchingMovies = true);
      try {
        final q = query.trim();
        final url = q.isEmpty
            ? 'https://phimapi.com/danh-sach/phim-moi-cap-nhat?page=1'
            : 'https://phimapi.com/v1/api/tim-kiem?keyword=${Uri.encodeComponent(q)}&limit=12';
        final resp = await dio.get(url);
        final data = resp.data;
        final List items = q.isEmpty
            ? (data['items'] as List? ?? [])
            : ((data['data']?['items']) as List? ?? []);
        final String cdn = (q.isEmpty
                ? data['APP_DOMAIN_CDN_IMAGE']
                : data['data']?['APP_DOMAIN_CDN_IMAGE'])
            ?.toString() ??
            'https://phimimg.com';

        setModalState(() {
          searchResults = items.take(12).map<Map<String, dynamic>>((raw) {
            final map = Map<String, dynamic>.from(raw as Map);
            final p = (map['poster_url'] ?? map['thumb_url'] ?? '').toString();
            final fullPoster = p.startsWith('http')
                ? p
                : (p.isNotEmpty ? '$cdn/${p.replaceFirst(RegExp(r'^/'), '')}' : '');
            return {
              'slug': (map['slug'] ?? map['_id'] ?? '').toString(),
              'name': (map['name'] ?? 'Phim').toString(),
              'poster_url': fullPoster,
              'year': (map['year'] ?? '').toString(),
            };
          }).toList();
        });
      } catch (_) {
        // Giữ nguyên danh sách hiện tại nếu mất mạng
      } finally {
        setModalState(() => isSearchingMovies = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tạo phòng Xem Chung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Phim phát trong phòng',
                          style: TextStyle(color: kGray, fontSize: 12.5),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              showMovieSearch = !showMovieSearch;
                            });
                            if (showMovieSearch && searchResults.length <= 1) {
                              runMovieSearch('', setModalState);
                            }
                          },
                          icon: Icon(
                            showMovieSearch ? Icons.close : Icons.search,
                            size: 16,
                            color: kNetflixRed,
                          ),
                          label: Text(
                            showMovieSearch ? 'Đóng tìm kiếm' : 'Tìm phim khác',
                            style: const TextStyle(
                              color: kNetflixRed,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          if (selectedPoster.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                selectedPoster,
                                width: 40,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 54,
                                  color: Colors.white10,
                                  child: const Icon(Icons.movie, color: kGray),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                if (isLoadingMovieDetail)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Đang lấy link phát...',
                                      style: TextStyle(
                                        color: kGray,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showMovieSearch) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: movieSearchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        onChanged: (val) {
                          searchDebounce?.cancel();
                          searchDebounce = Timer(
                            const Duration(milliseconds: 350),
                            () => runMovieSearch(val, setModalState),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Nhập tên phim muốn tìm (VD: Conan, Slime)...',
                          hintStyle: const TextStyle(color: kGray, fontSize: 12.5),
                          prefixIcon: const Icon(Icons.search, color: kGray, size: 20),
                          suffixIcon: isSearchingMovies
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kNetflixRed,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.arrow_forward_rounded,
                                      color: kNetflixRed, size: 20),
                                  onPressed: () => runMovieSearch(
                                      movieSearchController.text, setModalState),
                                ),
                          filled: true,
                          fillColor: kCardColor,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 190),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: searchResults.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'Không tìm thấy phim phù hợp.',
                                    style: TextStyle(color: kGray, fontSize: 12.5),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Colors.white10,
                                ),
                                itemBuilder: (_, i) {
                                  final item = searchResults[i];
                                  final slug = item['slug'] as String;
                                  final name = item['name'] as String;
                                  final poster = item['poster_url'] as String;
                                  final year = item['year'] as String;
                                  return ListTile(
                                    dense: true,
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: poster.isNotEmpty
                                          ? Image.network(
                                              poster,
                                              width: 34,
                                              height: 46,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.movie,
                                                      color: kGray),
                                            )
                                          : const Icon(Icons.movie, color: kGray),
                                    ),
                                    title: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: year.isNotEmpty
                                        ? Text(
                                            year,
                                            style: const TextStyle(
                                                color: kGray, fontSize: 11),
                                          )
                                        : null,
                                    onTap: () async {
                                      setModalState(() {
                                        selectedId = slug;
                                        selectedTitle = name;
                                        if (poster.isNotEmpty) {
                                          selectedPoster = poster;
                                        }
                                        selectedStreamUrl = '';
                                        showMovieSearch = false;
                                        isLoadingMovieDetail = true;
                                      });
                                      final resolved =
                                          await _resolveMovieStreamUrl(slug);
                                      if (ctx.mounted) {
                                        setModalState(() {
                                          selectedStreamUrl = resolved;
                                          isLoadingMovieDetail = false;
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: roomNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tên phòng',
                        labelStyle: const TextStyle(color: kGray),
                        filled: true,
                        fillColor: kCardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPrivate ? 'Phòng Riêng tư' : 'Phòng Công khai',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isPrivate
                                    ? 'Yêu cầu mã PIN 4 số để vào'
                                    : 'Hiển thị trên sảnh chờ cho mọi người',
                                style: const TextStyle(
                                  color: kGray,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: isPrivate,
                            activeThumbColor: kNetflixRed,
                            onChanged: (v) =>
                                setModalState(() => isPrivate = v),
                          ),
                        ],
                      ),
                    ),
                    if (isPrivate) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'Mã PIN (4 chữ số)',
                          labelStyle: const TextStyle(color: kGray),
                          filled: true,
                          fillColor: kCardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNetflixRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final roomName = roomNameController.text.trim();
                                if (roomName.isEmpty) {
                                  _showSnack('Vui lòng nhập tên phòng.',
                                      isError: true);
                                  return;
                                }
                                final pin = pinController.text.trim();
                                if (isPrivate &&
                                    !RegExp(r'^\d{4}$').hasMatch(pin)) {
                                  _showSnack(
                                    'Mã PIN phải gồm đúng 4 chữ số.',
                                    isError: true,
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                String resolvedStream = selectedStreamUrl;
                                if (resolvedStream.isEmpty) {
                                  resolvedStream = await _resolveMovieStreamUrl(
                                      selectedId);
                                }

                                final visibility =
                                    isPrivate ? 'PRIVATE' : 'PUBLIC';
                                _pendingCreatePayload = {
                                  'movieId': selectedId,
                                  'movieTitle': selectedTitle,
                                  'posterUrl': selectedPoster,
                                  'streamUrl': resolvedStream,
                                  'roomName': roomName,
                                  'visibility': visibility,
                                  'passcode': isPrivate ? pin : null,
                                };

                                if (ctx.mounted) Navigator.pop(ctx);
                                _service.createRoom(
                                  movieId: selectedId,
                                  movieTitle: selectedTitle,
                                  posterUrl: selectedPoster,
                                  streamUrl: resolvedStream,
                                  roomName: roomName,
                                  visibility: visibility,
                                  passcode: isPrivate ? pin : null,
                                );
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Tạo phòng & Bắt đầu xem',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _resolveMovieStreamUrl(String movieId) async {
    try {
      final descService = getIt<DescriptionService>();
      final res = await descService.getMovieDescription(id: movieId);
      return res.fold(
        (_) => WatchPartyConfig.fallbackSampleStreamUrl,
        (resp) {
          for (final ep in resp.episodeList) {
            if (ep.linkM3u8.isNotEmpty) return ep.linkM3u8;
          }
          return WatchPartyConfig.fallbackSampleStreamUrl;
        },
      );
    } catch (_) {
      return WatchPartyConfig.fallbackSampleStreamUrl;
    }
  }

  List<WatchPartyRoom> get _filteredRooms {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _rooms;
    return _rooms.where((r) {
      return r.roomId.toLowerCase().contains(q) ||
          r.roomName.toLowerCase().contains(q) ||
          r.movieTitle.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeRoomId = _service.activeRoomId;
    final filtered = _filteredRooms;

    return Scaffold(
      backgroundColor: backgrounndColor,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedTab,
        backgroundColor: backgrounndColor,
        title: Row(
          children: [
            const Text(
              'Party',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isConnected ? const Color(0xFF22C55E) : kNetflixRed,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cài đặt Server & Tên',
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: _showServerConfigDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm tên phòng hoặc nhập mã phòng...',
                      hintStyle: const TextStyle(color: kGray, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: kGray),
                      suffixIcon: _searchQuery.trim().isNotEmpty
                          ? TextButton(
                              onPressed: () {
                                final code = _searchQuery.trim();
                                _showPasscodeDialog(code);
                              },
                              child: const Text(
                                'Vào mã',
                                style: TextStyle(
                                  color: kNetflixRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: kSurfaceColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNetflixRed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: activeRoomId != null && activeRoomId.isNotEmpty
                      ? () => _service.joinRoom(roomId: activeRoomId)
                      : _showCreateRoomSheet,
                  icon: Icon(
                    activeRoomId != null && activeRoomId.isNotEmpty
                        ? Icons.meeting_room_rounded
                        : Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    activeRoomId != null && activeRoomId.isNotEmpty
                        ? 'Quay lại phòng'
                        : 'Tạo phòng mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kNetflixRed,
              backgroundColor: kSurfaceColor,
              onRefresh: _refreshRooms,
              child: _isLoading && filtered.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: kNetflixRed),
                    )
                  : filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    color: kGray,
                                    size: 56,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Chưa có phòng công khai nào',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tạo phòng mới để mời bạn bè cùng xem phim!',
                                    style:
                                        TextStyle(color: kGray, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kNetflixRed,
                                    ),
                                    onPressed: _showCreateRoomSheet,
                                    child: const Text(
                                      'Tạo phòng ngay',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            widget.isEmbeddedTab ? 96 : 32,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final room = filtered[index];
                            return _RoomCard(
                              room: room,
                              onJoin: () {
                                if (room.isFull) return;
                                if (room.isPrivate) {
                                  _showPasscodeDialog(room.roomId);
                                } else {
                                  _service.joinRoom(roomId: room.roomId);
                                }
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final WatchPartyRoom room;
  final VoidCallback onJoin;

  const _RoomCard({required this.room, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final full = room.isFull;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 90,
              child: room.posterUrl.isNotEmpty
                  ? Image.network(
                      room.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: kCardColor,
                        child: const Icon(Icons.movie_rounded, color: kGray),
                      ),
                    )
                  : Container(
                      color: kCardColor,
                      child: const Icon(Icons.movie_rounded, color: kGray),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: full
                            ? Colors.white12
                            : const Color(0x33E50914),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${room.effectiveMemberCount}/${room.maxMembers}',
                        style: TextStyle(
                          color: full ? kGray : kNetflixRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (room.isPrivate)
                      const Icon(Icons.lock_rounded,
                          size: 14, color: Colors.amber),
                    Expanded(
                      child: Text(
                        room.roomName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  room.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chủ phòng: ${room.resolvedHostName} • #${room.roomId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kGray, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: full ? Colors.white12 : kNetflixRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: full ? null : onJoin,
            child: Text(
              full ? 'Đầy' : 'Tham gia',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
