import 'package:flutter_clean_architecture/core/di/injections.dart';
import 'package:flutter_clean_architecture/features/country/domain/usecases/get_all_country_usecase.dart';
import 'package:flutter_clean_architecture/features/university/domain/usecases/search_universities_usecase.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'university_list_notifier.dart';

/// Exposes the shared usecases to Riverpod.
/// In tests these are overridden with mocks via [ProviderContainer]
/// or [ProviderScope] overrides — no service-locator setup needed.
final searchUniversitiesUsecaseProvider =
    Provider<SearchUniversitiesUsercase>((ref) {
  return di.get<SearchUniversitiesUsercase>();
});

final getAllCountryUsecaseProvider = Provider<GetAllCountryUsecase>((ref) {
  return di.get<GetAllCountryUsecase>();
});

final universityListProvider =
    NotifierProvider<UniversityListNotifier, UniversityListState>(
  UniversityListNotifier.new,
);
