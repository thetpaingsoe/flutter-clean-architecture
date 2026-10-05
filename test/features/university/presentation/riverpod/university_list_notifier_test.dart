import 'package:flutter_clean_architecture/core/config/config.dart';
import 'package:flutter_clean_architecture/core/config/constants.dart';
import 'package:flutter_clean_architecture/core/network/api_response.dart';
import 'package:flutter_clean_architecture/features/country/domain/entities/country.dart';
import 'package:flutter_clean_architecture/features/country/domain/usecases/get_all_country_usecase.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_clean_architecture/features/university/domain/usecases/search_universities_usecase.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_state.dart';
import 'package:flutter_clean_architecture/features/university/presentation/riverpod/providers/university_list_notifier.dart';
import 'package:flutter_clean_architecture/features/university/presentation/riverpod/providers/university_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'university_list_notifier_test.mocks.dart';

@GenerateMocks([SearchUniversitiesUsercase, GetAllCountryUsecase])
void main() {
  late MockSearchUniversitiesUsercase mockSearchUniversities;
  late MockGetAllCountryUsecase mockGetAllCountries;
  late ProviderContainer container;

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
  final countries = [Country(name: 'All'), Country(name: 'United States')];

  setUp(() {
    mockSearchUniversities = MockSearchUniversitiesUsercase();
    mockGetAllCountries = MockGetAllCountryUsecase();

    when(mockGetAllCountries.call()).thenAnswer((_) async => countries);
    when(
      mockSearchUniversities.call(params: anyNamed('params')),
    ).thenAnswer((_) async => ApiResponse.success(universities, statusCode: 200));

    container = ProviderContainer(
      overrides: [
        searchUniversitiesUsecaseProvider.overrideWithValue(
          mockSearchUniversities,
        ),
        getAllCountryUsecaseProvider.overrideWithValue(mockGetAllCountries),
      ],
    );
    addTearDown(container.dispose);
  });

  UniversityListState readState() =>
      container.read(universityListProvider);
  UniversityListNotifier readNotifier() =>
      container.read(universityListProvider.notifier);

  test('initial state is Status.initial', () {
    expect(readState(), const UniversityListState(status: Status.initial));
  });

  test('loadData loads universities and countries', () async {
    await readNotifier().loadData();

    expect(readState().status, Status.loaded);
    expect(readState().universities, universities);
    expect(readState().countries, countries);
    expect(readState().params.offset, Config.offset);
    expect(readState().params.limit, Config.limit);

    final captured =
        verify(
          mockSearchUniversities.call(params: captureAnyNamed('params')),
        ).captured.single
            as SearchUniversityParams;
    expect(captured.offset, Config.offset);
    expect(captured.limit, Config.limit);
  });

  test('loadData surfaces errors', () async {
    when(
      mockSearchUniversities.call(params: anyNamed('params')),
    ).thenAnswer(
      (_) async => ApiResponse.error('Server error', statusCode: 500),
    );

    await readNotifier().loadData();

    expect(readState().status, Status.error);
    expect(readState().errorCode, 500);
    expect(readState().errorMessage, 'Server error');
    expect(readState().countries, countries);
  });

  test('search with a new country resets the keyword', () async {
    await readNotifier().search(keyword: 'marywood', country: 'Japan');

    expect(readState().status, Status.loaded);
    expect(readState().params.keyword, '');
    expect(readState().params.country, 'Japan');
  });

  test('search with "All" clears the country filter', () async {
    await readNotifier().search(keyword: '', country: 'Japan');
    expect(readState().params.country, 'Japan');

    await readNotifier().search(keyword: '', country: 'All');

    expect(readState().status, Status.loaded);
    expect(readState().params.country, '');
  });

  test('loadMore appends universities to the existing list', () async {
    await readNotifier().loadData();
    await readNotifier().loadMore();

    expect(readState().status, Status.loaded);
    expect(readState().universities, [...universities, ...universities]);
    expect(readState().params.offset, Config.limit);
  });

  test('resetData clears the keyword and reloads', () async {
    await readNotifier().search(keyword: 'marywood', country: 'Japan');
    await readNotifier().resetData();

    expect(readState().status, Status.loaded);
    expect(readState().params.keyword, '');
    expect(readState().universities, universities);
  });

  test('setSearchActive flips the app bar search mode', () {
    readNotifier().setSearchActive(true);

    expect(readState().isActiveSearch, isTrue);

    readNotifier().setSearchActive(false);

    expect(readState().isActiveSearch, isFalse);
  });
}
