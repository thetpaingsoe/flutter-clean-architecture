import 'package:flutter_clean_architecture/features/country/data/models/country_model.dart';
import 'package:flutter_clean_architecture/features/country/domain/entities/country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson creates a Country from a map', () {
    final model = CountryModel.fromJson({'name': 'Myanmar'});

    expect(model, isA<Country>());
    expect(model.name, 'Myanmar');
  });

  test('toJson returns a map with the name', () {
    final model = CountryModel(name: 'Myanmar');

    expect(model.toJson(), {'name': 'Myanmar'});
  });

  test('fromJson(toJson(x)) round-trips', () {
    final model = CountryModel.fromJson(CountryModel(name: 'Japan').toJson());

    expect(model.name, 'Japan');
  });
}
