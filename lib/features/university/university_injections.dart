import 'package:hive_ce/hive.dart';

import '../../core/di/injections.dart';
import 'data/datasources/cache/university_cache_data_source.dart';
import 'data/datasources/cache/university_hive_cache_data_source_impl.dart';
import 'data/datasources/local/university_local_data_source_impl.dart';
import 'data/datasources/remote/university_remote_data_source_impl.dart';
import 'domain/repositories/university_repository.dart';
import 'domain/usecases/search_universities_usecase.dart';
import 'data/repositories/university_repository_impl.dart';

Future<void> initUniversityInjection() async {
  // Offline-first stack: remote -> Hive cache -> bundled asset.
  final cacheBox = await Hive.openBox(
    UniversityHiveCacheDataSourceImpl.boxName,
  );
  di.registerSingleton<UniversityCacheDataSource>(
    UniversityHiveCacheDataSourceImpl(box: cacheBox),
  );

  // Init Repo and UseCases
  di.registerSingleton<UniversityRepository>(
    UniversityRepositoryImpl(
      universityRemoteDataSource: UniversityRemoteDataSourceImpl(
        dioClient: di.get(),
      ),
      universityCacheDataSource: di.get(),
      universityAssetDataSource: UniversityLocalDataSourceImpl(),
    ),
  );
  di.registerSingleton<SearchUniversitiesUsercase>(
    SearchUniversitiesUsercase(universityRepository: di.get()),
  );
}
