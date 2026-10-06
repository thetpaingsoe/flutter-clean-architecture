import '../../../domain/entities/params/search_university_params.dart';
import '../../../domain/entities/university.dart';

/// Keyed cache for university search results.
/// Backed by Hive in production, replaceable in tests.
abstract class UniversityCacheDataSource {
  Future<void> saveSearch({
    required SearchUniversityParams params,
    required List<University> universities,
  });

  /// Returns null when nothing is cached for [params].
  Future<List<University>?> getSearch({
    required SearchUniversityParams params,
  });
}
