import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/entities/course_material.dart';
import '../../../../../injection_container.dart';
import '../../../../blocs/auth/auth_bloc.dart';
import '../../../../blocs/material_viewer/material_viewer_bloc.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/state_views.dart';
import '../../course_detail/widgets/material_tile.dart';
import 'pdf_material_view.dart';
import 'text_material_view.dart';
import 'video_material_view.dart';

class MaterialViewerPage extends StatelessWidget {
  const MaterialViewerPage({
    super.key,
    required this.courseId,
    required this.materialId,
  });

  final String courseId;
  final String materialId;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<MaterialViewerBloc>()
        ..add(MaterialViewerStarted(
          userId: uid,
          courseId: courseId,
          materialId: materialId,
        )),
      child: _MaterialViewerView(
        userId: uid,
        courseId: courseId,
        materialId: materialId,
      ),
    );
  }
}

class _MaterialViewerView extends StatelessWidget {
  const _MaterialViewerView({
    required this.userId,
    required this.courseId,
    required this.materialId,
  });

  final String userId;
  final String courseId;
  final String materialId;

  Widget _content(CourseMaterial material) {
    // Key membuat widget dibuat ulang saat pindah materi,
    // sehingga pemutar video lama ikut ditutup.
    final key = ValueKey(material.id);
    return switch (material.type) {
      MaterialKind.text =>
        TextMaterialView(key: key, content: material.content),
      MaterialKind.video => VideoMaterialView(key: key, url: material.mediaUrl),
      MaterialKind.pdf => PdfMaterialView(key: key, url: material.mediaUrl),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<MaterialViewerBloc, MaterialViewerState>(
      listenWhen: (prev, curr) => curr.error != null || curr.info != null,
      listener: (context, state) {
        if (state.error != null) {
          showAppSnackBar(context, state.error!, isError: true);
        } else if (state.info != null) {
          showAppSnackBar(context, state.info!);
        }
      },
      child: BlocBuilder<MaterialViewerBloc, MaterialViewerState>(
        builder: (context, state) {
          final bloc = context.read<MaterialViewerBloc>();
          final detail = state.detail;

          if (state.status == MaterialViewerStatus.failure) {
            return Scaffold(
              appBar: AppBar(title: const Text('Materi')),
              body: ErrorView(
                message: state.loadError ?? 'Gagal memuat materi.',
                onRetry: () => bloc.add(MaterialViewerStarted(
                  userId: userId,
                  courseId: courseId,
                  materialId: materialId,
                )),
              ),
            );
          }

          if (state.status == MaterialViewerStatus.loading || detail == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Materi')),
              body: const LoadingView(),
            );
          }

          final materials = detail.materials;
          final material = materials[state.index];
          final isFirst = state.index == 0;
          final isLast = state.index == materials.length - 1;
          final isDone =
              state.progress?.completedMaterialIds.contains(material.id) ??
                  false;

          final String primaryLabel;
          if (isDone) {
            primaryLabel = isLast ? 'Kembali ke Course' : 'Berikutnya';
          } else {
            primaryLabel = isLast ? 'Tandai Selesai' : 'Tandai Selesai & Lanjut';
          }

          void onPrimary() {
            if (isDone) {
              if (isLast) {
                context.pop();
              } else {
                bloc.add(const MaterialViewerNext());
              }
            } else {
              bloc.add(const MaterialViewerCompleteRequested());
            }
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                detail.item.course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            body: Column(
              children: [
                LinearProgressIndicator(
                  value: (state.index + 1) / materials.length,
                  minHeight: 4,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            materialTypeIcon(material.type),
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Materi ${state.index + 1} dari ${materials.length}'
                            ' · ${materialTypeLabel(material.type)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (isDone) ...[
                            const Spacer(),
                            Icon(Icons.check_circle,
                                size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Selesai',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        material.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _content(material)),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (isFirst || state.isSaving)
                            ? null
                            : () => bloc.add(const MaterialViewerPrevious()),
                        child: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: state.isSaving ? null : onPrimary,
                        child: state.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(primaryLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}