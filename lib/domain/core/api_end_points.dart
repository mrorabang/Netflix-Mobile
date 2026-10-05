import 'package:netflix_clone/core/strings.dart';

class ApiEndPoints {
  static const trending = "$kBaseUrl/api/danh-sach/phim-moi-cap-nhat?page=1";
  static const downloads = "$kBaseUrl/api/danh-sach/phim-moi-cap-nhat?page=1";
  static const search = '$kBaseUrl/api/tim-kiem';
  static const hotAndNewMovie = '$kBaseUrl/api/danh-sach/phim-le?page=1&limit=28';
  static const hotAndNewTv = '$kBaseUrl/api/danh-sach/phim-bo?page=1&limit=28';
  static const hoatHinh = '$kBaseUrl/api/danh-sach/hoat-hinh?page=1&limit=28';
  static const tvShows = '$kBaseUrl/api/danh-sach/tv-shows?page=1&limit=28';
  static const movieDetail = '$kBaseUrl/api/phim/';

  static String theLoai(String slug, [int page = 1]) =>
      '$kBaseUrl/api/the-loai/$slug?page=$page&limit=28';
  static String quocGia(String slug, [int page = 1]) =>
      '$kBaseUrl/api/quoc-gia/$slug?page=$page&limit=28';
  static String phimBoPage([int page = 1]) =>
      '$kBaseUrl/api/danh-sach/phim-bo?page=$page&limit=28';
  static String phimLePage([int page = 1]) =>
      '$kBaseUrl/api/danh-sach/phim-le?page=$page&limit=28';
}
