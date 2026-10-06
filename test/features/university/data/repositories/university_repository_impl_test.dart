import 'package:flutter_clean_architecture/core/network/api_response.dart';
import 'package:flutter_clean_architecture/features/university/data/datasources/cache/university_cache_data_source.dart';
import 'package:flutter_clean_architecture/features/university/data/repositories/university_repository_impl.dart';
import 'package:flutter_clean_architecture/features/university/data/datasources/university_data_source.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'university_repository_impl_test.mocks.dart';

@GenerateMocks([UniversityDataSource, UniversityCacheDataSource])
void main() {
  late UniversityRepositoryImpl repository;
  late MockUniversityDataSource mockRemoteDataSource;
  late MockUniversityDataSource mockAssetDataSource;
  late MockUniversityCacheDataSource mockCacheDataSource;

  final testUniversities = [
    University(
      name: 'University A',
      stateProvince: 'State A',
      country: 'Country A',
      countryCode: 'CA',
      webPages: ['www.universityA.edu'],
      domains: ['universityA.edu'],
    ),
  ];

  SearchUniversityParams params = SearchUniversityParams(
    keyword: 'University',
    country: '',
    offset: 0,
    limit: 10,
  );

  setUp(() {
    mockRemoteDataSource = MockUniversityDataSource();
    mockAssetDataSource = MockUniversityDataSource();
    mockCacheDataSource = MockUniversityCacheDataSource();
    repository = UniversityRepositoryImpl(
      universityRemoteDataSource: mockRemoteDataSource,
      universityCacheDataSource: mockCacheDataSource,
      universityAssetDataSource: mockAssetDataSource,
    );
  });

  test('remote success returns remote data and refreshes the cache', () async {
    when(mockRemoteDataSource.search(any, any, any, any)).thenAnswer(
      (_) async => ApiResponse.success(testUniversities, statusCode: 200),
    );

    final result = await repository.search(params: params);

    expect(result.data, testUniversities);
    verify(
      mockCacheDataSource.saveSearch(
        params: anyNamed('params'),
        universities: testUniversities,
      ),
    ).called(1);
    verifyNever(mockAssetDataSource.search(any, any, any, any));
  });

  test('remote error falls back to cached data when available', () async {
    when(mockRemoteDataSource.search(any, any, any, any)).thenAnswer(
      (_) async => ApiResponse.error('Server error', statusCode: 500),
    );
    when(
      mockCacheDataSource.getSearch(params: anyNamed('params')),
    ).thenAnswer((_) async => testUniversities);

    final result = await repository.search(params: params);

    expect(result.success, isTrue);
    expect(result.data, testUniversities);
    verifyNever(mockAssetDataSource.search(any, any, any, any));
  });

  test('remote throw falls back to cached data when available', () async {
    when(
      mockRemoteDataSource.search(any, any, any, any),
    ).thenThrow(Exception('No connection'));
    when(
      mockCacheDataSource.getSearch(params: anyNamed('params')),
    ).thenAnswer((_) async => testUniversities);

    final result = await repository.search(params: params);

    expect(result.success, isTrue);
    expect(result.data, testUniversities);
  });

  test(
    'remote error with empty cache falls back to the bundled asset',
    () async {
      final assetUniversities = [
        University(
          name: 'Asset University',
          stateProvince: '',
          country: 'Country A',
          countryCode: 'CA',
          webPages: [],
          domains: [],
        ),
      ];
      when(mockRemoteDataSource.search(any, any, any, any)).thenAnswer(
        (_) async => ApiResponse.error('Server error', statusCode: 500),
      );
      when(
        mockCacheDataSource.getSearch(params: anyNamed('params')),
      ).thenAnswer((_) async => null);
      when(mockAssetDataSource.search(any, any, any, any)).thenAnswer(
        (_) async => ApiResponse.success(assetUniversities, statusCode: 200),
      );

      final result = await repository.search(params: params);

      expect(result.success, isTrue);
      expect(result.data, assetUniversities);
      verify(mockAssetDataSource.search('University', '', 0, 10)).called(1);
    },
  );
}
