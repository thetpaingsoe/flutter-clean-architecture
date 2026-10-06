import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../domain/entities/params/search_university_params.dart';
import '../../../domain/entities/university.dart';
import '../../models/university_model.dart';
import 'university_cache_data_source.dart';

/// Hive-backed [UniversityCacheDataSource].
///
/// Stores each search result list as JSON under a key derived from the
/// search params, plus a timestamp for future TTL/expiry policies.
class UniversityHiveCacheDataSourceImpl implements UniversityCacheDataSource {
  static const String boxName = 'university_cache';

  final Box box;

  UniversityHiveCacheDataSourceImpl({required this.box});

  static String cacheKey(SearchUniversityParams params) {
    return '${params.keyword}|${params.country}|${params.offset}|${params.limit}';
  }

  @override
  Future<void> saveSearch({
    required SearchUniversityParams params,
    required List<University> universities,
  }) async {
    final jsonList =
        universities.map((university) => _toJson(university)).toList();
    await box.put(cacheKey(params), {
      'data': jsonEncode(jsonList),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<University>?> getSearch({
    required SearchUniversityParams params,
  }) async {
    try {
      final entry = box.get(cacheKey(params));
      if (entry is! Map || entry['data'] is! String) return null;
      final decoded = jsonDecode(entry['data'] as String) as List;
      return decoded
          .map((e) => UniversityModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<University>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toJson(University university) {
    return UniversityModel(
      name: university.name,
      stateProvince: university.stateProvince,
      country: university.country,
      countryCode: university.countryCode,
      webPages: university.webPages,
      domains: university.domains,
    ).toJson();
  }
}
