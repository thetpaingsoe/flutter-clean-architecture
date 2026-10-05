import 'package:flutter_clean_architecture/features/country/data/datasources/local/country_local_data_source.dart';
import 'package:flutter_clean_architecture/features/country/domain/entities/country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CountryLocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = CountryLocalDataSourceImpl();
  });

  test('getAll returns a non-empty list of countries', () async {
    final countries = await dataSource.getAll();

    expect(countries, isNotEmpty);
    expect(countries, everyElement(isA<Country>()));
  });

  test('getAll starts with the "All" filter option', () async {
    final countries = await dataSource.getAll();

    expect(countries.first.name, 'All');
  });

  test('getAll contains expected countries', () async {
    final names = (await dataSource.getAll()).map((c) => c.name).toSet();

    expect(names, containsAll({'United States', 'Myanmar', 'Japan'}));
  });
}
