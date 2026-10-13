import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/course_item.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/courses/courses_bloc.dart';
import '../../widgets/course_card.dart';
import '../../widgets/course_status_badge.dart';
import '../../widgets/state_views.dart';

/// Tab Course: daftar course dengan filter status.
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  /// null = semua.
  CourseStatus? _filter;

  void _load() {
    final uid = context.read<AuthBloc>().state.user?.uid;
    if (uid == null) return;
    context.read<CoursesBloc>().add(CoursesRequested(uid));
  }

  Future<void> _refresh() async {
    final bloc = context.read<CoursesBloc>();
    _load();
    await bloc.stream.firstWhere((s) => s.status != CoursesStatus.loading);
  }

  void _open(CourseItem item) {
    context.push('/course/${item.course.id}').then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: BlocBuilder<CoursesBloc, CoursesState>(
        builder: (context, state) {
          final items = state.items;

          if (items == null) {
            if (state.status == CoursesStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat daftar course.',
                onRetry: _load,
              );
            }
            return const LoadingView();
          }

          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.school_outlined,
              message: 'Belum ada course yang tersedia.',
              onAction: _load,
            );
          }

          final filtered = _filter == null
              ? items
              : items.where((i) => i.status == _filter).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Course',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final s in CourseStatus.values) ...[
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: courseStatusLabel(s),
                          selected: _filter == s,
                          onTap: () => setState(() => _filter = s),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('Tidak ada course di kategori ini.')),
                  )
                else
                  for (final item in filtered) ...[
                    CourseCard(item: item, onTap: () => _open(item)),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}