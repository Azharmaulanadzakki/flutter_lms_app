import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/course.dart';
import '../../../domain/usecases/admin/admin_course_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

import '../../../domain/game/missions.dart';

class AdminCourseFormPage extends StatelessWidget {
  const AdminCourseFormPage({super.key, this.courseId});

  /// Null = course baru.
  final String? courseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<Course>(
        load: () => sl<GetCourseFormUseCase>()(courseId),
        save: (course) async {
          await sl<SaveCourseUseCase>()(course);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseId == null ? 'Tambah Course' : 'Edit Course'),
        ),
        body: BlocConsumer<AdminFormCubit<Course>, AdminFormState<Course>>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status || curr.error != null,
          listener: (context, state) => handleAdminFormState(
            context,
            state,
            savedMessage: 'Course tersimpan.',
          ),
          builder: (context, state) {
            final initial = state.initial;

            if (initial == null) {
              if (state.status == AdminFormStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat data.',
                  onRetry: () => context.read<AdminFormCubit<Course>>().init(),
                );
              }
              return const LoadingView();
            }

            return _CourseForm(
              initial: initial,
              isSaving: state.status == AdminFormStatus.saving,
            );
          },
        ),
      ),
    );
  }
}

class _CourseForm extends StatefulWidget {
  const _CourseForm({required this.initial, required this.isSaving});

  final Course initial;
  final bool isSaving;

  @override
  State<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends State<_CourseForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _thumbnail;
  late final TextEditingController _duration;
  late final TextEditingController _order;
  late final TextEditingController _objectives;
  late String _level;
  late bool _hasGame;
  late bool _isPublished;
  late Set<String> _missionIds;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _title = TextEditingController(text: c.title);
    _description = TextEditingController(text: c.description);
    _thumbnail = TextEditingController(text: c.thumbnailUrl);
    _duration = TextEditingController(text: '${c.duration}');
    _order = TextEditingController(text: '${c.order}');
    _objectives = TextEditingController(text: c.objectives.join('\n'));
    _level = SaveCourseUseCase.levels.contains(c.level)
        ? c.level
        : SaveCourseUseCase.levels.first;
    _hasGame = c.hasGame;
    _missionIds = {...c.missionIds};
    _isPublished = c.isPublished;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _thumbnail.dispose();
    _duration.dispose();
    _order.dispose();
    _objectives.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<Course>>().submit(
      Course(
        id: widget.initial.id,
        title: _title.text,
        description: _description.text,
        thumbnailUrl: _thumbnail.text,
        level: _level,
        duration: int.parse(_duration.text.trim()),
        order: int.parse(_order.text.trim()),
        objectives: _objectives.text.split('\n'),
        hasGame: _hasGame,
        missionIds: _hasGame ? _missionIds.toList() : const [],
        isPublished: _isPublished,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Judul course',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [
                      for (final level in SaveCourseUseCase.levels)
                        DropdownMenuItem(value: level, child: Text(level)),
                    ],
                    onChanged: (value) =>
                        setState(() => _level = value ?? _level),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _duration,
                          decoration: const InputDecoration(
                            labelText: 'Durasi (menit)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              validateInt(v, field: 'Durasi', min: 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _order,
                          decoration: const InputDecoration(
                            labelText: 'Urutan',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              validateInt(v, field: 'Urutan', min: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _thumbnail,
                    decoration: const InputDecoration(
                      labelText: 'URL thumbnail (opsional)',
                      helperText: 'Alamat gambar yang diawali https://',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _objectives,
                    decoration: const InputDecoration(
                      labelText: 'Tujuan pembelajaran',
                      helperText: 'Satu tujuan per baris',
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Simulasi (game IoT)'),
                    subtitle: const Text(
                      'Aktifkan jika course ini punya game simulasi. Post-test baru '
                      'terbuka setelah semua misi simulasi selesai.',
                    ),
                    value: _hasGame,
                    onChanged: (v) => setState(() => _hasGame = v),
                  ),
                  if (_hasGame) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Misi untuk course ini',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Tidak ada yang dicentang berarti semua misi dipakai.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    for (final m in bundledMissions)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text('${m.order}. ${m.title}'),
                        subtitle: Text(
                          m.goal,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _missionIds.contains(m.id),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _missionIds.add(m.id);
                          } else {
                            _missionIds.remove(m.id);
                          }
                        }),
                      ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dipublikasikan'),
                    subtitle: const Text(
                      'Siswa hanya melihat course yang dipublikasikan.',
                    ),
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.isSaving ? null : _submit,
                    child: widget.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
