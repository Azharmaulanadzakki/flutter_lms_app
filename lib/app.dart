import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/branding/branding_cubit.dart';
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
  late final BrandingCubit _branding;
  late final GoRouterRefreshStream _refresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthStarted());
    _branding = sl<BrandingCubit>()..load();
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
    _branding.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _branding),
      ],
      child: BlocBuilder<BrandingCubit, BrandingState>(
        buildWhen: (prev, curr) =>
            prev.branding.appName != curr.branding.appName,
        builder: (context, state) => MaterialApp.router(
          title: state.branding.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
