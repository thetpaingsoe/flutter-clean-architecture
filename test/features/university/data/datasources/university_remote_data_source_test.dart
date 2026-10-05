import 'package:dio/dio.dart';
import 'package:flutter_clean_architecture/core/network/dio_client.dart';
import 'package:flutter_clean_architecture/features/university/data/datasources/remote/university_remote_data_source_impl.dart';
import 'package:flutter_clean_architecture/features/university/domain/entities/university.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only DioClient that serves a real Dio backed by an interceptor,
/// so no mock code generation is needed.
class _FakeDioClient extends DioClient {
  final Dio _fakeDio;

  _FakeDioClient(this._fakeDio) : super('https://example.com');

  @override
  Dio get instance => _fakeDio;
}

Dio _dioWith({
  required Object? Function(RequestOptions options) handler,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, interceptorHandler) {
        try {
          final data = handler(options);
          interceptorHandler.resolve(
            Response(requestOptions: options, data: data, statusCode: 200),
          );
        } on DioException catch (e) {
          interceptorHandler.reject(e);
        }
      },
    ),
  );
  return dio;
}

void main() {
  final apiJson = [
    {
      'name': 'Marywood University',
      'state-province': null,
      'country': 'United States',
      'alpha_two_code': 'US',
      'web_pages': ['http://www.marywood.edu/'],
      'domains': ['marywood.edu'],
    },
  ];

  test('search maps the response and builds the query url', () async {
    String? requestedPath;
    final dataSource = UniversityRemoteDataSourceImpl(
      dioClient: _FakeDioClient(
        _dioWith(
          handler: (options) {
            requestedPath = options.path;
            return apiJson;
          },
        ),
      ),
    );

    final response = await dataSource.search('marywood', 'United States', 0, 10);

    expect(
      requestedPath,
      '/search?offset=0&limit=10&name=marywood&country=United States',
    );
    expect(response.success, isTrue);
    expect(response.statusCode, 200);
    expect(response.data, isA<List<University>>());
    expect(response.data!.single.name, 'Marywood University');
  });

  test('search omits empty keyword and country from the query url', () async {
    String? requestedPath;
    final dataSource = UniversityRemoteDataSourceImpl(
      dioClient: _FakeDioClient(
        _dioWith(
          handler: (options) {
            requestedPath = options.path;
            return apiJson;
          },
        ),
      ),
    );

    await dataSource.search('', '', 0, 10);

    expect(requestedPath, '/search?offset=0&limit=10');
  });

  test('search returns an error response on DioException', () async {
    final dataSource = UniversityRemoteDataSourceImpl(
      dioClient: _FakeDioClient(
        _dioWith(
          handler: (_) {
            throw DioException(
              requestOptions: RequestOptions(path: '/search'),
              message: 'Connection failed',
              type: DioExceptionType.connectionError,
            );
          },
        ),
      ),
    );

    final response = await dataSource.search('marywood', '', 0, 10);

    expect(response.success, isFalse);
    expect(response.message, 'Connection failed');
  });
}
