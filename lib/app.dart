import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/pages/splash/firebase_error_page.dart';

class App extends StatelessWidget {
  const App({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        home: FirebaseErrorPage(message: initError!),
      );
    }
    return const _LmsApp();
  }
}

class _LmsApp extends StatefulWidget {
  const _LmsApp();

  @override
  State<_LmsApp> createState() => _LmsAppState();
}

class _LmsAppState extends State<_LmsApp> {
  late final AuthBloc _authBloc;
  late final GoRouterRefreshStream _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _refresh = GoRouterRefreshStream(
      _authBloc.stream.map((s) => s.status).distinct(),
    );
    _router = createRouter(authBloc: _authBloc, refreshListenable: _refresh);
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}