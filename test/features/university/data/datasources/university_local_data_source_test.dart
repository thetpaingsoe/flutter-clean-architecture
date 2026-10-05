import 'package:flutter_clean_architecture/features/university/data/datasources/local/university_local_data_source_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The local data source reads the bundled json asset via rootBundle,
  // which requires the Flutter binding in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late UniversityLocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = UniversityLocalDataSourceImpl();
  });

  test('search with empty filters returns a limited success response', () async {
    final response = await dataSource.search('', '', 0, 10);

    expect(response.success, isTrue);
    expect(response.statusCode, 200);
    expect(response.data, isNotNull);
    expect(response.data!, isNotEmpty);
    expect(response.data!.length, lessThanOrEqualTo(10));
  });

  test('search filters by keyword case-insensitively', () async {
    final response = await dataSource.search('marywood', '', 0, 10);

    expect(response.success, isTrue);
    expect(response.data, isNotEmpty);
    expect(
      response.data!.map((u) => u.name.toLowerCase()),
      everyElement(contains('marywood')),
    );
  });

  test('search filters by country', () async {
    final response = await dataSource.search('', 'United States', 0, 10);

    expect(response.success, isTrue);
    expect(response.data, isNotEmpty);
    expect(
      response.data!.map((u) => u.country),
      everyElement('United States'),
    );
  });

  test('search respects the limit', () async {
    final response = await dataSource.search('', '', 0, 5);

    expect(response.success, isTrue);
    expect(response.data!.length, lessThanOrEqualTo(5));
  });
}
