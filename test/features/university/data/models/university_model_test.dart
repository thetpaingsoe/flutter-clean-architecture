import 'package:flutter_clean_architecture/features/university/data/models/university_model.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fullJson = {
    'name': 'Marywood University',
    'state-province': null,
    'country': 'United States',
    'alpha_two_code': 'US',
    'web_pages': ['http://www.marywood.edu/'],
    'domains': ['marywood.edu'],
  };

  test('fromJson maps all fields, defaulting null state-province to ""', () {
    final model = UniversityModel.fromJson(fullJson);

    expect(model, isA<University>());
    expect(model.name, 'Marywood University');
    expect(model.stateProvince, '');
    expect(model.country, 'United States');
    expect(model.countryCode, 'US');
    expect(model.webPages, ['http://www.marywood.edu/']);
    expect(model.domains, ['marywood.edu']);
  });

  test('fromJson defaults missing keys to empty values', () {
    final model = UniversityModel.fromJson({'name': 'Test University'});

    expect(model.name, 'Test University');
    expect(model.stateProvince, '');
    expect(model.country, '');
    expect(model.countryCode, '');
    expect(model.webPages, isEmpty);
    expect(model.domains, isEmpty);
  });

  test('toJson returns the api-shaped map', () {
    final model = UniversityModel.fromJson(fullJson);

    expect(model.toJson(), {
      'name': 'Marywood University',
      'state-province': '',
      'country': 'United States',
      'alpha_two_code': 'US',
      'web_pages': ['http://www.marywood.edu/'],
      'domains': ['marywood.edu'],
    });
  });

  test('fromJson(toJson(x)) round-trips', () {
    final model = UniversityModel.fromJson(fullJson);
    final roundTripped = UniversityModel.fromJson(model.toJson());

    expect(roundTripped.toJson(), model.toJson());
  });
}
