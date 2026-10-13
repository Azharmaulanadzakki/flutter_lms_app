import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/course_remote_datasource.dart';
import 'data/datasources/history_remote_datasource.dart';
import 'data/datasources/progress_remote_datasource.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/datasources/test_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/course_repository_impl.dart';
import 'data/repositories/history_repository_impl.dart';
import 'data/repositories/progress_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/test_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/course_repository.dart';
import 'domain/repositories/history_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/test_repository.dart';
import 'domain/usecases/auth/auth_usecases.dart';
import 'domain/usecases/course/get_course_detail.dart';
import 'domain/usecases/course/get_course_items.dart';
import 'domain/usecases/course/get_dashboard_data.dart';
import 'domain/usecases/progress/get_progress_overview.dart';
import 'domain/usecases/progress/mark_material_completed.dart';
import 'domain/usecases/progress/record_posttest_score.dart';
import 'domain/usecases/progress/record_pretest_score.dart';
import 'domain/usecases/test/test_usecases.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/course_detail/course_detail_bloc.dart';
import 'presentation/blocs/courses/courses_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/material_viewer/material_viewer_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'presentation/blocs/test/test_bloc.dart';

final sl = GetIt.instance;

/// Dipanggil setelah Firebase berhasil diinisialisasi.
void initDependencies() {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl(), sl()),
  );
  sl.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProgressRemoteDataSource>(
    () => ProgressRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TestRemoteDataSource>(
    () => TestRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<HistoryRemoteDataSource>(
    () => HistoryRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<CourseRepository>(() => CourseRepositoryImpl(sl()));
  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TestRepository>(() => TestRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(sl()),
  );

  // Use cases: auth
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));

  // Use cases: course dan progress
  sl.registerLazySingleton(() => GetCourseItemsUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetDashboardDataUseCase(sl()));
  sl.registerLazySingleton(() => GetCourseDetailUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => MarkMaterialCompletedUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RecordPreTestScoreUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => RecordPostTestScoreUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetProgressOverviewUseCase(sl(), sl()));

  // Use cases: test
  sl.registerLazySingleton(() => GetTestOverviewUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetAttemptQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => BeginTestUseCase(sl()));
  sl.registerLazySingleton(() => SubmitAnswersUseCase(sl()));
  sl.registerLazySingleton(() => GradeTestUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetTestResultUseCase(sl(), sl(), sl(), sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      watchAuthState: sl(),
      signIn: sl(),
      register: sl(),
      signOut: sl(),
      sendPasswordReset: sl(),
    ),
  );
  sl.registerFactory(() => DashboardBloc(sl()));
  sl.registerFactory(() => CoursesBloc(sl()));
  sl.registerFactory(() => CourseDetailBloc(sl()));
  sl.registerFactory(
    () => MaterialViewerBloc(getCourseDetail: sl(), markCompleted: sl()),
  );
  sl.registerFactory(
    () => TestBloc(
      getOverview: sl(),
      begin: sl(),
      submitAnswers: sl(),
      grade: sl(),
      getResult: sl(),
    ),
  );
  sl.registerFactory(() => ProgressBloc(sl()));
}