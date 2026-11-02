import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart';
import '../../blocs/ar/ar_cubits.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/courses/courses_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../widgets/state_views.dart';
import 'ar/ar_scanner_page.dart';
import 'courses_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'progress/progress_page.dart';

/// Kerangka halaman siswa: bottom navigation + 5 tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);

    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<DashboardBloc>()..add(DashboardRequested(user.uid)),
        ),
        BlocProvider(
          create: (_) => sl<CoursesBloc>()..add(CoursesRequested(user.uid)),
        ),
        // Dimuat saat tab dibuka, bukan saat aplikasi mulai.
        BlocProvider(create: (_) => sl<ProgressBloc>()),
        BlocProvider(create: (_) => sl<ArListCubit>()),
      ],
      // Builder: supaya context di bawah ini sudah bisa menemukan provider.
      child: Builder(
        builder: (context) => Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomePage(onSeeAllCourses: () => setState(() => _index = 1)),
              const CoursesPage(),
              const ProgressPage(),
              const ArScannerPage(),
              const ProfilePage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() => _index = i);
              if (i == 2) {
                context.read<ProgressBloc>().add(ProgressRequested(user.uid));
              }
              if (i == 3) {
                context.read<ArListCubit>().load();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Course',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_in_ar_outlined),
                selectedIcon: Icon(Icons.view_in_ar),
                label: 'AR',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}