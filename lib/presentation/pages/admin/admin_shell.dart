import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart';
import '../../blocs/admin/admin_courses_cubit.dart';
import '../../blocs/admin/class_overview_cubit.dart';
import '../../blocs/admin/users_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'admin_courses_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_progress_page.dart';
import 'admin_students_page.dart';
import 'admin_users_page.dart';
import '../../blocs/admin/question_cubits.dart';
import 'admin_questions_page.dart';

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Kerangka panel admin: 5 tab, ditambah tab Pengguna untuk super admin.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _select(BuildContext context, int index, {required bool isSuper}) {
    setState(() => _index = index);

    // Data dimuat ulang setiap tab dibuka supaya selalu terbaru.
    if (index == 0 || index == 3 || index == 4) {
      context.read<ClassOverviewCubit>().load();
    }
    if (index == 1) {
      context.read<AdminCoursesCubit>().load();
    }
    if (index == 2) {
      context.read<QuestionOverviewCubit>().load();
    }
    if (index == 5 && isSuper) {
      context.read<UsersCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuper = context.select(
      (AuthBloc b) => b.state.user?.isSuperAdmin ?? false,
    );

    final items = <_NavItem>[
      const _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      const _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Course'),
      const _NavItem(Icons.quiz_outlined, Icons.quiz, 'Soal'),
      const _NavItem(Icons.groups_outlined, Icons.groups, 'Siswa'),
      const _NavItem(Icons.insights_outlined, Icons.insights, 'Progress'),
      if (isSuper)
        const _NavItem(
          Icons.manage_accounts_outlined,
          Icons.manage_accounts,
          'Pengguna',
        ),
    ];

    final index = _index >= items.length ? 0 : _index;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ClassOverviewCubit>()..load()),
        BlocProvider(create: (_) => sl<AdminCoursesCubit>()..load()),
        BlocProvider(create: (_) => sl<QuestionOverviewCubit>()..load()),
        if (isSuper) BlocProvider(create: (_) => sl<UsersCubit>()..load()),
      ],
      // Builder: supaya context di bawah ini sudah bisa menemukan provider.
      child: Builder(
        builder: (context) {
          final content = IndexedStack(
            index: index,
            children: [
              AdminDashboardPage(
                onOpenTab: (i) => _select(context, i, isSuper: isSuper),
              ),
              const AdminCoursesPage(),
              const AdminQuestionsPage(),
              const AdminStudentsPage(),
              const AdminProgressPage(),
              if (isSuper) const AdminUsersPage(),
            ],
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              if (wide) {
                return Scaffold(
                  body: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: index,
                        labelType: NavigationRailLabelType.all,
                        onDestinationSelected: (i) =>
                            _select(context, i, isSuper: isSuper),
                        destinations: [
                          for (final item in items)
                            NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Scaffold(
                body: content,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index,
                  labelBehavior: items.length > 5
                      ? NavigationDestinationLabelBehavior.onlyShowSelected
                      : NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (i) =>
                      _select(context, i, isSuper: isSuper),
                  destinations: [
                    for (final item in items)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
