import 'dart:io';

import 'package:flutter_clean_architecture/features/university/data/datasources/cache/university_hive_cache_data_source_impl.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late UniversityHiveCacheDataSourceImpl cache;

  final params = SearchUniversityParams(
    keyword: 'marywood',
    country: '',
    offset: 0,
    limit: 10,
  );
  final universities = [
    University(
      name: 'Marywood University',
      stateProvince: '',
      country: 'United States',
      countryCode: 'US',
      webPages: ['http://www.marywood.edu/'],
      domains: ['marywood.edu'],
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('university_cache_test');
    cache = UniversityHiveCacheDataSourceImpl(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('saveSearch + getSearch round-trips', () async {
    await cache.saveSearch(params: params, universities: universities);

    final cached = await cache.getSearch(params: params);

    expect(cached, isNotNull);
    expect(
      cached!.map((u) => u.name),
      universities.map((u) => u.name),
    );
    expect(
      cached.map((u) => u.country),
      universities.map((u) => u.country),
    );
  });

  test('getSearch returns null for uncached params', () async {
    final cached = await cache.getSearch(params: params);

    expect(cached, isNull);
  });

  test('entries are keyed per query', () async {
    final otherParams = SearchUniversityParams(
      keyword: 'other',
      country: '',
      offset: 0,
      limit: 10,
    );
    await cache.saveSearch(params: params, universities: universities);

    expect(await cache.getSearch(params: otherParams), isNull);
    expect(await cache.getSearch(params: params), isNotNull);
  });

  test('getSearch returns null for corrupt entries', () async {
    await box.put(UniversityHiveCacheDataSourceImpl.cacheKey(params), 'garbage');

    expect(await cache.getSearch(params: params), isNull);
  });
}
