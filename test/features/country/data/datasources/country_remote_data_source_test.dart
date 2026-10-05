import 'package:flutter_clean_architecture/features/country/data/datasources/remote/country_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getAll falls back to the local list until the api exists', () async {
    // CountryRemoteDataSourceImpl currently reuses the local data source
    // (see the @todo in country_remote_data_source.dart).
    final countries = await CountryRemoteDataSourceImpl().getAll();

    expect(countries, isNotEmpty);
    expect(countries.first.name, 'All');
  });
}
