import '../../../../core/network/api_response.dart';
import '../../domain/entities/params/search_university_params.dart';
import '../../domain/entities/university.dart';
import '../../domain/repositories/university_repository.dart';
import '../datasources/cache/university_cache_data_source.dart';
import '../datasources/university_data_source.dart';

/// Offline-first repository with a 3-tier strategy:
///
/// 1. Remote — fresh data; on success the cache is refreshed.
/// 2. Hive cache — last good results for the same query (offline mode).
/// 3. Bundled asset — static fallback so a first launch without
///    network (and an empty cache) still shows data.
class UniversityRepositoryImpl extends UniversityRepository {
  final UniversityDataSource universityRemoteDataSource;
  final UniversityCacheDataSource universityCacheDataSource;
  final UniversityDataSource universityAssetDataSource;

  UniversityRepositoryImpl({
    required this.universityRemoteDataSource,
    required this.universityCacheDataSource,
    required this.universityAssetDataSource,
  });

  @override
  Future<ApiResponse<List<University>>> search({
    required SearchUniversityParams params,
  }) async {
    try {
      final remoteResponse = await universityRemoteDataSource.search(
        params.keyword,
        params.country,
        params.offset,
        params.limit,
      );
      if (remoteResponse.success) {
        await universityCacheDataSource.saveSearch(
          params: params,
          universities: remoteResponse.data ?? [],
        );
        return remoteResponse;
      }
    } catch (_) {
      // Unexpected remote failure — fall through to cache below.
    }

    final cached = await universityCacheDataSource.getSearch(params: params);
    if (cached != null && cached.isNotEmpty) {
      return ApiResponse.success(cached, statusCode: 200);
    }

    return universityAssetDataSource.search(
      params.keyword,
      params.country,
      params.offset,
      params.limit,
    );
  }
}
