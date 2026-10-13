import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:smk_tkj_lms/presentation/pages/student/material_viewer/widgets/material_viewer_page.dart';

import '../../presentation/pages/student/progress/progress_detail_page.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/landing/landing_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/student/main_shell.dart';
import '../../presentation/pages/student/course_detail/course_detail_page.dart';
import '../../domain/entities/quiz_test.dart';
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
    redirect: (context, state) {
      final status = authBloc.state.status;
      final location = state.matchedLocation;

      // Status login belum diketahui: tahan di splash.
      if (status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.authenticated) {
        final shouldLeave =
            location == '/splash' || publicRoutes.contains(location);
        return shouldLeave ? '/home' : null;
      }

      // Belum login: boleh ke halaman publik, selain itu ke landing.
      return publicRoutes.contains(location) ? null : '/landing';
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const MainShell()),
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
        path: '/progress/:id',
        builder: (context, state) =>
            ProgressDetailPage(courseId: state.pathParameters['id']!),
      ),
    ],
  );
}
