import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:netflix_clone/domain/core/api_end_points.dart';
import 'package:netflix_clone/domain/core/failures/main_failure.dart';
import 'package:dartz/dartz.dart';
import 'package:netflix_clone/domain/description/model/description_resp/description_resp.dart';
import '../../domain/description/description_service.dart';

@LazySingleton(as: DescriptionService)
class DescriptionMovie implements DescriptionService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 8000,
    receiveTimeout: 8000,
  ));

  @override
  Future<Either<MainFailure, DescriptionResp>> getMovieDescription(
      {required String id}) async {
    final rawId = id.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final cleanId = rawId.replaceAll(' ', '-').toLowerCase();

    if (cleanId.isEmpty) {
      return const Left(MainFailure.clientFailure());
    }

    final endpoints = [
      'https://phimapi.com/phim/$cleanId',
      '${ApiEndPoints.movieDetail}$cleanId',
      'https://ophim1.com/phim/$cleanId',
    ];

    DescriptionResp? candidateResp;

    for (final url in endpoints) {
      try {
        final response = await _dio.get(url);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          if (data is Map<String, dynamic> &&
              (data['status'] == true || data['status'] == 'success')) {
            final result = DescriptionResp.fromApiJson(data);
            if (result.title != null && result.title!.isNotEmpty) {
              // If this source has playable episodes, return it immediately!
              if (result.episodeList.isNotEmpty) {
                return Right(result);
              }
              candidateResp ??= result;
            }
          }
        }
      } catch (e) {
        log("Detail fetch error for $url: $e");
      }
    }

    if (candidateResp != null) {
      return Right(candidateResp);
    }
    return const Left(MainFailure.serverFailure());
  }
}
