import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/admin_question.dart';
import '../../../domain/usecases/questions/question_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminQuestionFormPage extends StatelessWidget {
  const AdminQuestionFormPage({
    super.key,
    required this.testId,
    this.questionId,
  });

  final String testId;

  /// Null = soal baru.
  final String? questionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<AdminQuestion>(
        load: () => sl<GetQuestionFormUseCase>()(
          testId: testId,
          questionId: questionId,
        ),
        save: (question) async {
          await sl<SaveQuestionUseCase>()(question);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(questionId == null ? 'Tambah Soal' : 'Edit Soal'),
        ),
        body:
            BlocConsumer<
              AdminFormCubit<AdminQuestion>,
              AdminFormState<AdminQuestion>
            >(
              listenWhen: (prev, curr) =>
                  prev.status != curr.status || curr.error != null,
              listener: (context, state) => handleAdminFormState(
                context,
                state,
                savedMessage: 'Soal tersimpan.',
              ),
              builder: (context, state) {
                final initial = state.initial;

                if (initial == null) {
                  if (state.status == AdminFormStatus.failure) {
                    return ErrorView(
                      message: state.loadError ?? 'Gagal memuat data.',
                      onRetry: () =>
                          context.read<AdminFormCubit<AdminQuestion>>().init(),
                    );
                  }
                  return const LoadingView();
                }

                return _QuestionForm(
                  initial: initial,
                  isSaving: state.status == AdminFormStatus.saving,
                );
              },
            ),
      ),
    );
  }
}

class _QuestionForm extends StatefulWidget {
  const _QuestionForm({required this.initial, required this.isSaving});

  final AdminQuestion initial;
  final bool isSaving;

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _text;
  late final List<TextEditingController> _options;
  late final TextEditingController _explanation;
  late final TextEditingController _points;
  late bool _isActive;

  /// Null = belum dipilih.
  int? _correct;
  bool _correctMissing = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;

    _text = TextEditingController(text: q.text);
    _options = [
      for (var i = 0; i < 4; i++)
        TextEditingController(text: i < q.options.length ? q.options[i] : ''),
    ];
    _explanation = TextEditingController(text: q.explanation);
    _points = TextEditingController(text: '${q.points}');
    _isActive = q.isActive;
    _correct = q.hasKey ? q.correctIndex : null;
  }

  @override
  void dispose() {
    _text.dispose();
    for (final c in _options) {
      c.dispose();
    }
    _explanation.dispose();
    _points.dispose();
    super.dispose();
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    final correct = _correct;

    if (correct == null) {
      setState(() => _correctMissing = true);
    }
    if (!valid || correct == null) return;

    final q = widget.initial;
    context.read<AdminFormCubit<AdminQuestion>>().submit(
      AdminQuestion(
        id: q.id,
        testId: q.testId,
        courseId: q.courseId,
        text: _text.text,
        options: [for (final c in _options) c.text],
        correctIndex: correct,
        explanation: _explanation.text,
        points: int.parse(_points.text.trim()),
        order: q.order,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    controller: _text,
                    decoration: const InputDecoration(
                      labelText: 'Pertanyaan',
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 8,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pertanyaan wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pilihan jawaban',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 4; i++) ...[
                    TextFormField(
                      controller: _options[i],
                      decoration: InputDecoration(
                        labelText: 'Pilihan ${optionLetter(i)}',
                      ),
                      minLines: 1,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pilihan ${optionLetter(i)} wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Jawaban yang benar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      for (var i = 0; i < 4; i++)
                        ButtonSegment<int>(
                          value: i,
                          label: Text(optionLetter(i)),
                        ),
                    ],
                    selected: _correct == null ? <int>{} : <int>{_correct!},
                    onSelectionChanged: (selection) => setState(() {
                      _correct = selection.isEmpty ? null : selection.first;
                      _correctMissing = false;
                    }),
                  ),
                  if (_correctMissing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Pilih jawaban yang benar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _explanation,
                    decoration: const InputDecoration(
                      labelText: 'Pembahasan (opsional)',
                      helperText: 'Tampil ke siswa setelah mengirim jawaban',
                      alignLabelWithHint: true,
                    ),
                    minLines: 2,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _points,
                    decoration: const InputDecoration(
                      labelText: 'Poin',
                      helperText: 'Soal bernilai lebih besar menyumbang lebih banyak ke nilai akhir',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        validateInt(v, field: 'Poin', min: 1, max: 100),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    subtitle: const Text(
                      'Hanya soal aktif yang bisa muncul di test siswa.',
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Kunci jawaban dan pembahasan disimpan terpisah dari soal. '
                      'Siswa tidak bisa melihatnya sebelum mengirim jawaban.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 20),
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
