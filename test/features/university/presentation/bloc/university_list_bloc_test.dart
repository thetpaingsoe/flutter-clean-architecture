import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_clean_architecture/core/config/config.dart';
import 'package:flutter_clean_architecture/core/config/constants.dart';
import 'package:flutter_clean_architecture/core/network/api_response.dart';
import 'package:flutter_clean_architecture/features/country/domain/entities/country.dart';
import 'package:flutter_clean_architecture/features/country/domain/usecases/get_all_country_usecase.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_clean_architecture/features/university/domain/usecases/search_universities_usecase.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_bloc.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_event.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'university_list_bloc_test.mocks.dart';

@GenerateMocks([SearchUniversitiesUsercase, GetAllCountryUsecase])
void main() {
  late MockSearchUniversitiesUsercase mockSearchUniversities;
  late MockGetAllCountryUsecase mockGetAllCountries;

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
  final defaultParams = SearchUniversityParams(
    keyword: '',
    country: '',
    offset: Config.offset,
    limit: Config.limit,
  );

  setUp(() {
    mockSearchUniversities = MockSearchUniversitiesUsercase();
    mockGetAllCountries = MockGetAllCountryUsecase();

    when(mockGetAllCountries.call()).thenAnswer((_) async => countries);
    when(
      mockSearchUniversities.call(params: anyNamed('params')),
    ).thenAnswer((_) async => ApiResponse.success(universities, statusCode: 200));
  });

  UniversityListBloc buildBloc() => UniversityListBloc(
    searchUniversitiesUsercase: mockSearchUniversities,
    getAllCountryUsecase: mockGetAllCountries,
  );

  test('initial state is Status.initial', () {
    expect(
      buildBloc().state,
      const UniversityListState(status: Status.initial),
    );
  });

  blocTest<UniversityListBloc, UniversityListState>(
    'emits loading then loaded on UniversityListLoadDataEvent',
    build: buildBloc,
    act: (bloc) => bloc.add(UniversityListLoadDataEvent()),
    expect:
        () => [
          UniversityListState(status: Status.loading, params: defaultParams),
          UniversityListState(
            status: Status.loaded,
            universities: universities,
            countries: countries,
            params: defaultParams,
          ),
        ],
    verify: (_) {
      final captured =
          verify(
            mockSearchUniversities.call(params: captureAnyNamed('params')),
          ).captured.single
              as SearchUniversityParams;
      expect(captured.offset, Config.offset);
      expect(captured.limit, Config.limit);
    },
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'emits loading then error when the search fails',
    build: buildBloc,
    setUp: () {
      when(
        mockSearchUniversities.call(params: anyNamed('params')),
      ).thenAnswer(
        (_) async => ApiResponse.error('Server error', statusCode: 500),
      );
    },
    act: (bloc) => bloc.add(UniversityListLoadDataEvent()),
    expect:
        () => [
          UniversityListState(status: Status.loading, params: defaultParams),
          UniversityListState(
            status: Status.error,
            errorCode: 500,
            errorMessage: 'Server error',
            params: defaultParams,
            countries: countries,
          ),
        ],
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'search with a new country resets the keyword',
    build: buildBloc,
    act:
        (bloc) => bloc.add(
          UniversityListSearchEvent(keyword: 'marywood', country: 'Japan'),
        ),
    expect: () {
      final params = defaultParams.copyWith(keyword: '', country: 'Japan');
      return [
        UniversityListState(status: Status.loading, params: params),
        UniversityListState(
          status: Status.loaded,
          universities: universities,
          countries: countries,
          params: params,
        ),
      ];
    },
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'search with "All" clears the country filter',
    build: buildBloc,
    seed:
        () => UniversityListState(
          status: Status.loaded,
          universities: universities,
          countries: countries,
          params: defaultParams.copyWith(country: 'Japan'),
        ),
    act: (bloc) => bloc.add(UniversityListSearchEvent(keyword: '', country: 'All')),
    expect: () {
      final params = defaultParams.copyWith(keyword: '', country: '');
      return [
        // The loading state keeps the previously loaded list.
        UniversityListState(
          status: Status.loading,
          universities: universities,
          countries: countries,
          params: params,
        ),
        UniversityListState(
          status: Status.loaded,
          universities: universities,
          countries: countries,
          params: params,
        ),
      ];
    },
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'load more appends universities to the existing list',
    build: buildBloc,
    seed:
        () => UniversityListState(
          status: Status.loaded,
          universities: universities,
          countries: countries,
          params: defaultParams,
        ),
    act: (bloc) => bloc.add(UniversityListLoadMoreDataEvent()),
    expect: () {
      final nextParams = defaultParams.copyWith(offset: Config.limit);
      return [
        // Load-more keeps the current list while loading the next page.
        UniversityListState(
          status: Status.loading,
          universities: universities,
          countries: countries,
          params: defaultParams,
        ),
        UniversityListState(
          status: Status.loaded,
          universities: [...universities, ...universities],
          params: nextParams,
        ),
      ];
    },
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'reset clears the keyword and reloads',
    build: buildBloc,
    seed:
        () => UniversityListState(
          status: Status.loaded,
          universities: universities,
          countries: countries,
          params: defaultParams.copyWith(keyword: 'marywood'),
        ),
    act: (bloc) => bloc.add(ResetDataEvent()),
    expect:
        () => [
          // The loading state keeps the previously loaded list.
          UniversityListState(
            status: Status.loading,
            universities: universities,
            countries: countries,
            params: defaultParams,
          ),
          UniversityListState(
            status: Status.loaded,
            universities: universities,
            countries: countries,
            params: defaultParams,
          ),
        ],
  );

  blocTest<UniversityListBloc, UniversityListState>(
    'toggle event flips the app bar search mode',
    build: buildBloc,
    act:
        (bloc) => bloc.add(ActiveToggleSearchOnAppBarEvent(isActive: true)),
    expect:
        () => [
          const UniversityListState(
            status: Status.initial,
            isActiveSearch: true,
          ),
        ],
  );
}
