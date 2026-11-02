import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/quiz_test.dart';
import '../../../domain/usecases/admin/admin_test_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminTestFormPage extends StatelessWidget {
  const AdminTestFormPage({
    super.key,
    required this.courseId,
    required this.type,
  });

  final String courseId;
  final TestType type;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<QuizTest>(
        load: () => sl<GetTestFormUseCase>()(courseId: courseId, type: type),
        save: (test) async {
          await sl<SaveTestUseCase>()(test);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(title: Text('Pengaturan ${type.label}')),
        body: BlocConsumer<AdminFormCubit<QuizTest>, AdminFormState<QuizTest>>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status || curr.error != null,
          listener: (context, state) => handleAdminFormState(
            context,
            state,
            savedMessage: '${type.label} tersimpan.',
          ),
          builder: (context, state) {
            final initial = state.initial;

            if (initial == null) {
              if (state.status == AdminFormStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat data.',
                  onRetry: () =>
                      context.read<AdminFormCubit<QuizTest>>().init(),
                );
              }
              return const LoadingView();
            }

            return _TestForm(
              initial: initial,
              isSaving: state.status == AdminFormStatus.saving,
            );
          },
        ),
      ),
    );
  }
}

class _TestForm extends StatefulWidget {
  const _TestForm({required this.initial, required this.isSaving});

  final QuizTest initial;
  final bool isSaving;

  @override
  State<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<_TestForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _questionCount;
  late final TextEditingController _duration;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _title = TextEditingController(text: t.title);
    _questionCount = TextEditingController(text: '${t.questionCount}');
    _duration = TextEditingController(text: '${t.durationMinutes}');
    _isActive = t.isActive;
  }

  @override
  void dispose() {
    _title.dispose();
    _questionCount.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final t = widget.initial;
    context.read<AdminFormCubit<QuizTest>>().submit(
          QuizTest(
            id: t.id,
            courseId: t.courseId,
            type: t.type,
            title: _title.text,
            questionCount: int.parse(_questionCount.text.trim()),
            durationMinutes: int.parse(_duration.text.trim()),
            isActive: _isActive,
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
                    decoration: const InputDecoration(labelText: 'Judul test'),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _questionCount,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah soal yang ditampilkan',
                      helperText:
                          '0 = semua soal. Soal diambil acak dari bank soal.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        validateInt(v, field: 'Jumlah soal', min: 0),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _duration,
                    decoration: const InputDecoration(
                      labelText: 'Durasi (menit)',
                      helperText: '0 = tanpa batas waktu.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        validateInt(v, field: 'Durasi', min: 0, max: 300),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    subtitle: const Text(
                      'Test hanya bisa diaktifkan jika sudah punya soal.',
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
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