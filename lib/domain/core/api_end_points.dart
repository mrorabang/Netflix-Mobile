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
}
