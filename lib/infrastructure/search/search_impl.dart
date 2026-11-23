import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:netflix_clone/domain/search/model/search_resp/search_resp.dart';
import 'package:netflix_clone/domain/core/failures/main_failure.dart';
import 'package:dartz/dartz.dart';
import 'package:netflix_clone/domain/search/search_service.dart';

import '../../domain/core/api_end_points.dart';

@LazySingleton(as: SearchService)
class searchImpl implements SearchService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 8000,
    receiveTimeout: 8000,
  ));

  @override
  Future<Either<MainFailure, SearchResp>> searchMovies(
      {required String movieQuery}) async {
    final query = movieQuery.trim();
    if (query.isEmpty) {
      return Right(SearchResp(results: []));
    }

    try {
      final encoded = Uri.encodeComponent(query);
      final urls = [
        'https://phimapi.com/v1/api/tim-kiem?keyword=$encoded&limit=28',
        '${ApiEndPoints.search}?keyword=$encoded',
      ];

      final Map<String, SearchResultData> uniqueResults = {};

      for (final url in urls) {
        try {
          final response = await _dio.get(url);
          if (response.statusCode == 200 || response.statusCode == 201) {
            final parsed = SearchResp.fromApiJson(response.data);
            for (final item in parsed.results) {
              final key = item.id?.trim() ?? item.originalTitle?.trim() ?? '';
              if (key.isNotEmpty && !uniqueResults.containsKey(key)) {
                uniqueResults[key] = item;
              }
            }
          }
        } catch (e) {
          log("Search error for $url: $e");
        }
      }

      return Right(SearchResp(results: uniqueResults.values.toList()));
    } catch (e) {
      log(e.toString());
      return const Left(MainFailure.clientFailure());
    }
  }
}
