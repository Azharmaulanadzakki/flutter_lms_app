import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/quiz_test.dart';
import '../../domain/game/course_game.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/pages/admin/admin_ar_form_page.dart';
import '../../presentation/pages/admin/admin_ar_list_page.dart';
import '../../presentation/pages/admin/admin_branding_page.dart';
import '../../presentation/pages/admin/admin_course_detail_page.dart';
import '../../presentation/pages/admin/admin_course_form_page.dart';
import '../../presentation/pages/admin/admin_material_form_page.dart';
import '../../presentation/pages/admin/admin_question_form_page.dart';
import '../../presentation/pages/admin/admin_question_list_page.dart';
import '../../presentation/pages/admin/admin_student_detail_page.dart';
import '../../presentation/pages/admin/admin_test_form_page.dart';
import '../../presentation/pages/admin/admin_user_form_page.dart';
import '../../presentation/pages/admin/admin_weights_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/home_gate.dart';
import '../../presentation/pages/landing/landing_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/student/ar/ar_item_page.dart';
import '../../presentation/pages/student/ar/ar_view_mode.dart';
import '../../presentation/pages/student/ar/ar_viewer_entry.dart';
import '../../presentation/pages/student/course_detail/course_detail_page.dart';
import '../../presentation/pages/student/game/course_game_page.dart';
import '../../presentation/pages/student/game/game_home_page.dart';
import '../../presentation/pages/student/game/mission_play_page.dart';
import '../../presentation/pages/student/game/stage_demo_page.dart';
import '../../presentation/pages/student/material_viewer/material_viewer_page.dart';
import '../../presentation/pages/student/progress/progress_detail_page.dart';
import '../../presentation/pages/student/test/test_page.dart';

/// Membuat GoRouter me-refresh redirect setiap status login berubah.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
}) {
  // Halaman yang boleh dibuka tanpa login.
  const publicRoutes = {'/landing', '/login', '/register', '/forgot-password'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 56),
              const SizedBox(height: 12),
              Text(
                'Alamat ${state.uri} tidak dikenal.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ke beranda'),
              ),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final location = state.matchedLocation;

      // Status login belum diketahui: tahan di splash.
      if (status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.authenticated) {
        if (location == '/splash' || publicRoutes.contains(location)) {
          return '/home';
        }

        final user = authBloc.state.user;

        // Panel admin untuk staf (guru, admin, super admin).
        if (location.startsWith('/admin') && !(user?.isStaff ?? false)) {
          return '/home';
        }
        // Manajemen pengguna hanya untuk super admin.
        if (location.startsWith('/admin/users') &&
            !(user?.isSuperAdmin ?? false)) {
          return '/home';
        }
        // Pengaturan aplikasi hanya untuk admin dan super admin.
        if (location == '/admin/branding' && !(user?.isAdmin ?? false)) {
          return '/home';
        }
        return null;
      }

      // Belum login: boleh ke halaman publik, selain itu ke landing.
      return publicRoutes.contains(location) ? null : '/landing';
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeGate()),

      // ---------- Siswa: course ----------
      GoRoute(
        path: '/course/:id',
        builder: (context, state) =>
            CourseDetailPage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/course/:id/material/:materialId',
        builder: (context, state) => MaterialViewerPage(
          courseId: state.pathParameters['id']!,
          materialId: state.pathParameters['materialId']!,
        ),
      ),
      GoRoute(
        path: '/course/:id/test/:type',
        builder: (context, state) => TestPage(
          courseId: state.pathParameters['id']!,
          type: state.pathParameters['type'] == 'post'
              ? TestType.post
              : TestType.pre,
        ),
      ),
      GoRoute(
        path: '/course/:id/game',
        builder: (context, state) =>
            CourseGamePage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/progress/:id',
        builder: (context, state) =>
            ProgressDetailPage(courseId: state.pathParameters['id']!),
      ),

      // ---------- Siswa: AR ----------
      // '/ar/test' harus di atas '/ar/:id'.
      GoRoute(
        path: '/ar/test',
        builder: (context, state) =>
            const ArViewerScreen(mode: ArViewMode.selfTest),
      ),
      GoRoute(
        path: '/ar/:id',
        builder: (context, state) =>
            ArItemPage(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ar/:id/view',
        builder: (context, state) => ArViewerScreen(
          itemId: state.pathParameters['id']!,
          mode: ArViewMode.model3d,
        ),
      ),
      GoRoute(
        path: '/ar/:id/marker',
        builder: (context, state) => ArViewerScreen(
          itemId: state.pathParameters['id']!,
          mode: ArViewMode.marker,
        ),
      ),

      // ---------- Siswa: game ----------
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameHomePage(),
      ),
      GoRoute(
        path: '/game/stage-demo',
        builder: (context, state) => const StageDemoPage(),
      ),
      GoRoute(
        path: '/game/mission/:id',
        builder: (context, state) {
          final extra = state.extra;
          return MissionPlayPage(
            missionId: state.pathParameters['id']!,
            courseContext: extra is GameCourseContext ? extra : null,
          );
        },
      ),

      // ---------- Admin ----------
      // '/admin/course/new' harus di atas '/admin/course/:id'.
      GoRoute(
        path: '/admin/course/new',
        builder: (context, state) => const AdminCourseFormPage(),
      ),
      GoRoute(
        path: '/admin/course/:id',
        builder: (context, state) =>
            AdminCourseDetailPage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/course/:id/edit',
        builder: (context, state) =>
            AdminCourseFormPage(courseId: state.pathParameters['id']!),
      ),
      // '/material/new' harus di atas '/material/:mid'.
      GoRoute(
        path: '/admin/course/:id/material/new',
        builder: (context, state) =>
            AdminMaterialFormPage(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/course/:id/material/:mid',
        builder: (context, state) => AdminMaterialFormPage(
          courseId: state.pathParameters['id']!,
          materialId: state.pathParameters['mid']!,
        ),
      ),
      GoRoute(
        path: '/admin/course/:id/test/:type',
        builder: (context, state) => AdminTestFormPage(
          courseId: state.pathParameters['id']!,
          type: state.pathParameters['type'] == 'post'
              ? TestType.post
              : TestType.pre,
        ),
      ),
      GoRoute(
        path: '/admin/student/:uid',
        builder: (context, state) =>
            AdminStudentDetailPage(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/admin/weights',
        builder: (context, state) => const AdminWeightsPage(),
      ),
      GoRoute(
        path: '/admin/branding',
        builder: (context, state) => const AdminBrandingPage(),
      ),

      // Model AR. '/admin/ar/new' harus di atas '/admin/ar/:id'.
      GoRoute(
        path: '/admin/ar',
        builder: (context, state) => const AdminArListPage(),
      ),
      GoRoute(
        path: '/admin/ar/new',
        builder: (context, state) => const AdminArFormPage(),
      ),
      GoRoute(
        path: '/admin/ar/:id',
        builder: (context, state) =>
            AdminArFormPage(itemId: state.pathParameters['id']!),
      ),

      // Pengguna (super admin). '/new' harus di atas '/:uid'.
      GoRoute(
        path: '/admin/users/new',
        builder: (context, state) => const AdminUserFormPage(),
      ),
      GoRoute(
        path: '/admin/users/:uid',
        builder: (context, state) =>
            AdminUserFormPage(uid: state.pathParameters['uid']!),
      ),

      // Soal. '/new' harus di atas '/:qid'.
      GoRoute(
        path: '/admin/test/:testId/questions',
        builder: (context, state) =>
            AdminQuestionListPage(testId: state.pathParameters['testId']!),
      ),
      GoRoute(
        path: '/admin/test/:testId/questions/new',
        builder: (context, state) =>
            AdminQuestionFormPage(testId: state.pathParameters['testId']!),
      ),
      GoRoute(
        path: '/admin/test/:testId/questions/:qid',
        builder: (context, state) => AdminQuestionFormPage(
          testId: state.pathParameters['testId']!,
          questionId: state.pathParameters['qid']!,
        ),
      ),
    ],
  );
}