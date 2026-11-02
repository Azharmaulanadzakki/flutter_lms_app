import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:smk_tkj_lms/domain/usecases/questions/question_usecases.dart';
import 'package:smk_tkj_lms/presentation/blocs/admin/question_cubits.dart';

import 'data/datasources/admin_remote_datasource.dart';
import 'data/datasources/ar_remote_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/course_remote_datasource.dart';
import 'data/datasources/history_remote_datasource.dart';
import 'data/datasources/progress_remote_datasource.dart';
import 'data/datasources/question_admin_remote_datasource.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/datasources/supabase_storage_datasource.dart';
import 'data/datasources/test_remote_datasource.dart';
import 'data/datasources/user_admin_remote_datasource.dart';

import 'data/repositories/admin_repository_impl.dart';
import 'data/repositories/ar_repository_impl.dart';
import 'data/repositories/ar_storage_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/course_repository_impl.dart';
import 'data/repositories/history_repository_impl.dart';
import 'data/repositories/progress_repository_impl.dart';
import 'data/repositories/question_admin_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/test_repository_impl.dart';
import 'data/repositories/user_admin_repository_impl.dart';

import 'domain/repositories/admin_repository.dart';
import 'domain/repositories/ar_repository.dart';
import 'domain/repositories/ar_storage_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/course_repository.dart';
import 'domain/repositories/history_repository.dart';
import 'domain/repositories/progress_repository.dart';
import 'domain/repositories/question_admin_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/test_repository.dart';
import 'domain/repositories/user_admin_repository.dart';

import 'domain/usecases/admin/admin_course_usecases.dart';
import 'domain/usecases/admin/admin_material_usecases.dart';
import 'domain/usecases/admin/admin_overview_usecases.dart';
import 'domain/usecases/admin/admin_question_usecases.dart';
import 'domain/usecases/admin/admin_test_usecases.dart';
import 'domain/usecases/ar/ar_usecases.dart';
import 'domain/usecases/ar/ar_upload_usecase.dart';
import 'domain/usecases/auth/auth_usecases.dart';
import 'domain/usecases/course/get_course_detail.dart';
import 'domain/usecases/course/get_course_items.dart';
import 'domain/usecases/course/get_dashboard_data.dart';
import 'domain/usecases/progress/get_progress_overview.dart';
import 'domain/usecases/progress/mark_material_completed.dart';
import 'domain/usecases/progress/record_posttest_score.dart';
import 'domain/usecases/progress/record_pretest_score.dart';
import 'domain/usecases/test/test_usecases.dart';
import 'domain/usecases/users/user_usecases.dart';

import 'presentation/blocs/admin/admin_course_detail_cubit.dart';
import 'presentation/blocs/admin/admin_courses_cubit.dart';
import 'presentation/blocs/admin/admin_student_detail_cubit.dart';
import 'presentation/blocs/admin/class_overview_cubit.dart';
import 'presentation/blocs/admin/question_list_cubit.dart';
import 'presentation/blocs/admin/question_overview_cubit.dart';
import 'presentation/blocs/admin/users_cubit.dart';
import 'presentation/blocs/ar/admin_ar_cubit.dart';
import 'presentation/blocs/ar/ar_cubits.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/course_detail/course_detail_bloc.dart';
import 'presentation/blocs/courses/courses_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/material_viewer/material_viewer_bloc.dart';
import 'presentation/blocs/progress/progress_bloc.dart';
import 'presentation/blocs/test/test_bloc.dart';

import 'data/datasources/branding_remote_datasource.dart';
import 'data/repositories/branding_repository_impl.dart';
import 'domain/repositories/branding_repository.dart';
import 'domain/usecases/branding/branding_usecases.dart';
import 'presentation/blocs/branding/branding_cubit.dart';

import 'data/game/game_store_entry.dart';
import 'domain/game/game_store.dart';
import 'domain/usecases/game/game_usecases.dart';
import 'presentation/blocs/game/game_cubits.dart';

import 'data/datasources/game_results_remote_datasource.dart';
import 'data/game/game_outbox_store_entry.dart';
import 'data/repositories/game_results_repository_impl.dart';
import 'domain/game/game_outbox_store.dart';
import 'domain/repositories/game_results_repository.dart';
import 'domain/usecases/game/game_sync_usecases.dart';
import 'presentation/blocs/game/game_sync_cubit.dart';

import 'domain/usecases/game/game_results_usecases.dart';

final sl = GetIt.instance;

/// Dipanggil setelah Firebase berhasil diinisialisasi.
void initDependencies() {
  sl.registerLazySingleton<ArStorageRepository>(
    () => ArStorageRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<BrandingRemoteDataSource>(
    () => BrandingRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<BrandingRepository>(
    () => BrandingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetBrandingUseCase(sl()));
  sl.registerLazySingleton(() => GetBrandingFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveBrandingUseCase(sl()));
  sl.registerLazySingleton(() => UploadBrandingLogoUseCase(sl()));
  sl.registerFactory(() => BrandingCubit(sl()));

  sl.registerLazySingleton(() => UploadArAssetUseCase(sl()));

  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data sources
  sl.registerLazySingleton<SupabaseStorageDataSource>(
    () => SupabaseStorageDataSource(),
  );

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

  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ArRemoteDataSource>(() => ArRemoteDataSource(sl()));

  sl.registerLazySingleton<UserAdminRemoteDataSource>(
    () => UserAdminRemoteDataSource(sl(), sl()),
  );

  sl.registerLazySingleton<QuestionAdminRemoteDataSource>(
    () => QuestionAdminRemoteDataSource(sl()),
  );

  sl.registerLazySingleton(() => SaveTestUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SetTestActiveUseCase(sl(), sl()));

  // Repositories
  sl.registerLazySingleton<QuestionAdminRepository>(
    () => QuestionAdminRepositoryImpl(sl()),
  );
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

  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(sl()));

  sl.registerLazySingleton<ArRepository>(() => ArRepositoryImpl(sl()));

  sl.registerLazySingleton<UserAdminRepository>(
    () => UserAdminRepositoryImpl(sl()),
  );

  // Use cases: auth
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));

  // Use cases: course dan progress siswa
  sl.registerLazySingleton(() => GetCourseItemsUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => GetDashboardDataUseCase(sl()));

  sl.registerLazySingleton(() => GetCourseDetailUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => MarkMaterialCompletedUseCase(sl(), sl()));

  sl.registerLazySingleton(() => RecordPreTestScoreUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => RecordPostTestScoreUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => GetProgressOverviewUseCase(sl(), sl()));

  // Use cases: tes siswa
  sl.registerLazySingleton(() => GetTestOverviewUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => GetAttemptQuestionsUseCase(sl()));

  sl.registerLazySingleton(() => BeginTestUseCase(sl()));

  sl.registerLazySingleton(() => SubmitAnswersUseCase(sl()));

  sl.registerLazySingleton(() => GradeTestUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => GetTestResultUseCase(sl(), sl(), sl(), sl()));

  // Use cases: admin
  sl.registerLazySingleton(() => GetAdminCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetAdminCourseDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetCourseFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveCourseUseCase(sl()));
  sl.registerLazySingleton(() => SetCoursePublishedUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCourseUseCase(sl()));

  sl.registerLazySingleton(() => GetMaterialFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveMaterialUseCase(sl()));
  sl.registerLazySingleton(() => SetMaterialPublishedUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMaterialUseCase(sl()));

  sl.registerLazySingleton(() => GetTestFormUseCase(sl()));

  sl.registerLazySingleton(() => DeleteTestUseCase(sl()));

  sl.registerLazySingleton(() => GetClassOverviewUseCase(sl(), sl(), sl()));

  sl.registerLazySingleton(() => GetStudentUseCase(sl()));
  sl.registerLazySingleton(() => GetProgressWeightsUseCase(sl()));
  sl.registerLazySingleton(() => SaveProgressWeightsUseCase(sl()));

  // Use cases: AR
  sl.registerLazySingleton(() => GetPublishedArItemsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllArItemsUseCase(sl()));
  sl.registerLazySingleton(() => GetArItemUseCase(sl()));
  sl.registerLazySingleton(() => GetArFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveArItemUseCase(sl()));
  sl.registerLazySingleton(() => SetArItemPublishedUseCase(sl()));
  sl.registerLazySingleton(() => DeleteArItemUseCase(sl()));

  // Use cases: pengguna (super admin)
  sl.registerLazySingleton(() => GetAllUsersUseCase(sl()));
  sl.registerLazySingleton(() => GetUserFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveUserUseCase(sl()));
  sl.registerLazySingleton(() => SetUserActiveUseCase(sl()));
  sl.registerLazySingleton(() => SendUserPasswordResetUseCase(sl()));

  // BLoC: autentikasi
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

  // Cubit admin
  sl.registerFactory(() => ClassOverviewCubit(sl()));
  sl.registerFactory(() => AdminCoursesCubit(sl()));

  sl.registerFactory(
    () => AdminCourseDetailCubit(
      getDetail: sl(),
      setCoursePublished: sl(),
      deleteCourse: sl(),
      setMaterialPublished: sl(),
      deleteMaterial: sl(),
      setTestActive: sl(),
      deleteTest: sl(),
    ),
  );

    sl.registerFactory(
    () => AdminStudentDetailCubit(
      getStudent: sl(),
      getOverview: sl(),
      getResults: sl(),
    ),
  );

  // Cubit AR
  sl.registerFactory(() => ArListCubit(sl()));
  sl.registerFactory(() => ArItemCubit(sl()));

  sl.registerFactory(
    () => AdminArCubit(getAll: sl(), setPublished: sl(), deleteItem: sl()),
  );

  // Cubit users
  sl.registerFactory(
    () => UsersCubit(getAll: sl(), setActive: sl(), sendReset: sl()),
  );

  // Use cases: soal (admin)
  sl.registerLazySingleton(() => GetQuestionOverviewUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetQuestionListUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetQuestionFormUseCase(sl()));
  sl.registerLazySingleton(() => SaveQuestionUseCase(sl()));
  sl.registerLazySingleton(() => SetQuestionActiveUseCase(sl()));
  sl.registerLazySingleton(() => DuplicateQuestionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteQuestionUseCase(sl()));
  sl.registerLazySingleton(() => ReorderQuestionsUseCase(sl()));

  sl.registerFactory(() => QuestionOverviewCubit(sl()));
  sl.registerFactory(
    () => QuestionListCubit(
      getList: sl(),
      setActive: sl(),
      duplicate: sl(),
      delete: sl(),
      reorder: sl(),
    ),
  );

  sl.registerLazySingleton<GameLocalStore>(() => PlatformGameStore());
  sl.registerLazySingleton(() => LoadGameProgressUseCase(sl()));
  sl.registerLazySingleton(() => RecordMissionRunUseCase(sl()));
  sl.registerFactory(() => GameHomeCubit(sl()));

  sl.registerLazySingleton<GameOutboxStore>(() => PlatformGameOutboxStore());
  sl.registerLazySingleton<GameResultsRemoteDataSource>(
    () => GameResultsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<GameResultsRepository>(
    () => GameResultsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => SubmitMissionRunUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SyncGameResultsUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetOutboxSummaryUseCase(sl()));
  sl.registerFactory(() => GameSyncCubit(sl(), sl()));

  sl.registerLazySingleton(() => GetStudentGameResultsUseCase(sl()));
}
