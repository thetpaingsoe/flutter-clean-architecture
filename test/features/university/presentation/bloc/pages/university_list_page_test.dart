import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/core/di/injections.dart';
import 'package:flutter_clean_architecture/core/network/api_response.dart';
import 'package:flutter_clean_architecture/features/country/domain/entities/country.dart';
import 'package:flutter_clean_architecture/features/country/domain/usecases/get_all_country_usecase.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_clean_architecture/features/university/domain/usecases/search_universities_usecase.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/pages/university_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'university_list_page_test.mocks.dart';

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

  setUp(() async {
    await di.reset();
    mockSearchUniversities = MockSearchUniversitiesUsercase();
    mockGetAllCountries = MockGetAllCountryUsecase();
    di.registerSingleton<SearchUniversitiesUsercase>(mockSearchUniversities);
    di.registerSingleton<GetAllCountryUsecase>(mockGetAllCountries);

    when(mockGetAllCountries.call()).thenAnswer((_) async => countries);
    when(
      mockSearchUniversities.call(params: anyNamed('params')),
    ).thenAnswer((_) async => ApiResponse.success(universities, statusCode: 200));
  });

  tearDown(() async => di.reset());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UniversityListPage()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows universities and country filters after loading', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
    expect(find.textContaining('Marywood University'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
  });

  testWidgets('tapping a country chip searches with that country', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();

    final captured =
        verify(
          mockSearchUniversities.call(params: captureAnyNamed('params')),
        ).captured;
    final lastParams = captured.last as SearchUniversityParams;
    expect(lastParams.country, 'United States');
  });

  testWidgets('search icon toggles the search field and searches', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'marywood');
    await tester.pumpAndSettle();

    final captured =
        verify(
          mockSearchUniversities.call(params: captureAnyNamed('params')),
        ).captured;
    final lastParams = captured.last as SearchUniversityParams;
    expect(lastParams.keyword, 'marywood');
    expect(find.textContaining('Marywood University'), findsOneWidget);
  });

  testWidgets('close icon resets search mode and reloads', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Flutter Clean Architecture'), findsOneWidget);
  });
}
