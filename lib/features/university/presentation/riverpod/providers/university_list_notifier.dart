import 'package:flutter_clean_architecture/core/config/config.dart';
import 'package:flutter_clean_architecture/core/config/constants.dart';
import 'package:flutter_clean_architecture/features/country/domain/usecases/get_all_country_usecase.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/params/search_university_params.dart';
import 'package:flutter_clean_architecture/features/university/domain/usecases/search_universities_usecase.dart';
import 'package:flutter_clean_architecture/features/university/presentation/bloc/bloc/university_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'university_providers.dart';

/// Riverpod counterpart of [UniversityListBloc].
///
/// Consumes the exact same usecases; only the state-management
/// mechanism differs (method calls instead of events).
class UniversityListNotifier extends Notifier<UniversityListState> {
  SearchUniversitiesUsercase get _searchUniversities =>
      ref.read(searchUniversitiesUsecaseProvider);
  GetAllCountryUsecase get _getAllCountries =>
      ref.read(getAllCountryUsecaseProvider);

  @override
  UniversityListState build() {
    return const UniversityListState(status: Status.initial);
  }

  Future<void> loadData() async {
    final params = state.params.copyWith(
      offset: Config.offset,
      limit: Config.limit,
    );
    await _loadUniversities(params);
  }

  Future<void> loadMore() async {
    state = state.copyWith(status: Status.loading);

    final params = state.params.copyWith(
      offset: state.params.offset + Config.limit,
    );
    final response = await _searchUniversities.call(params: params);

    if (response.success) {
      final updatedList = List.of(state.universities)
        ..addAll(response.data ?? []);
      state = state.copyWith(
        universities: updatedList,
        status: Status.loaded,
        params: params,
      );
    } else {
      state = state.copyWith(
        status: Status.error,
        errorCode: response.statusCode!,
        errorMessage: response.message!,
        params: params,
      );
    }
  }

  Future<void> search({required String keyword, required String country}) async {
    final currentCountry = state.params.country;

    // Since we added the All condition in country,
    // we have to make sure the correct country is selected.
    // That means we don't always use the incoming value,
    // we also check the data from state to keep the current country.
    final newCountry = switch (country) {
      "All" => "",
      "" => currentCountry,
      _ => country,
    };

    final isSameCountry = newCountry == currentCountry;

    // If country is not same, reset keyword and do a reset load.
    final newKeyword = isSameCountry ? keyword : "";
    final isReset = !isSameCountry;

    final params = state.params.copyWith(
      keyword: newKeyword,
      country: newCountry,
      offset: Config.offset,
      limit: Config.limit,
    );

    await _loadUniversities(params, reset: isReset);
  }

  Future<void> resetData() async {
    final newParams = state.params.copyWith(
      keyword: "",
      offset: Config.offset,
      limit: Config.limit,
    );
    await _loadUniversities(newParams, reset: true);
  }

  void setSearchActive(bool isActive) {
    state = state.copyWith(isActiveSearch: isActive);
  }

  Future<void> _loadUniversities(
    SearchUniversityParams params, {
    bool reset = false,
  }) async {
    state = state.copyWith(status: Status.loading, params: params);

    final countries = await _getAllCountries.call();
    final response = await _searchUniversities.call(params: params);

    if (response.success) {
      state = state.copyWith(
        status: Status.loaded,
        universities: response.data ?? [],
        params: params,
        countries: countries,
        isActiveSearch: reset ? false : state.isActiveSearch,
      );
    } else {
      state = state.copyWith(
        status: Status.error,
        errorCode: response.statusCode!,
        errorMessage: response.message!,
        params: params,
        countries: countries,
      );
    }
  }
}
