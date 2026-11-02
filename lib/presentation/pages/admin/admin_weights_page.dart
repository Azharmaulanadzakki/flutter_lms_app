import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/progress_weights.dart';
import '../../../domain/usecases/admin/admin_overview_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminWeightsPage extends StatelessWidget {
  const AdminWeightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<ProgressWeights>(
        load: () => sl<GetProgressWeightsUseCase>()(),
        save: (weights) async {
          await sl<SaveProgressWeightsUseCase>()(weights);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Bobot Progress')),
        body: BlocConsumer<AdminFormCubit<ProgressWeights>,
            AdminFormState<ProgressWeights>>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status || curr.error != null,
          listener: (context, state) => handleAdminFormState(
            context,
            state,
            savedMessage: 'Bobot tersimpan. Berlaku untuk semua tampilan progress.',
          ),
          builder: (context, state) {
            final initial = state.initial;

            if (initial == null) {
              if (state.status == AdminFormStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat bobot.',
                  onRetry: () =>
                      context.read<AdminFormCubit<ProgressWeights>>().init(),
                );
              }
              return const LoadingView();
            }

            return _WeightsForm(
              initial: initial,
              isSaving: state.status == AdminFormStatus.saving,
            );
          },
        ),
      ),
    );
  }
}

class _WeightsForm extends StatefulWidget {
  const _WeightsForm({required this.initial, required this.isSaving});

  final ProgressWeights initial;
  final bool isSaving;

  @override
  State<_WeightsForm> createState() => _WeightsFormState();
}

class _WeightsFormState extends State<_WeightsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pre;
  late final TextEditingController _materials;
  late final TextEditingController _game;
  late final TextEditingController _post;

  @override
  void initState() {
    super.initState();
    final w = widget.initial;
    _pre = TextEditingController(text: scoreText(w.preTest));
    _materials = TextEditingController(text: scoreText(w.materials));
    _game = TextEditingController(text: scoreText(w.game));
    _post = TextEditingController(text: scoreText(w.postTest));
  }

  @override
  void dispose() {
    _pre.dispose();
    _materials.dispose();
    _game.dispose();
    _post.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _validate(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null) return 'Harus berupa angka';
    if (number < 0) return 'Tidak boleh negatif';
    return null;
  }

  String _preview({required bool withGame}) {
    final pre = _parse(_pre) ?? 0;
    final materials = _parse(_materials) ?? 0;
    final game = _parse(_game) ?? 0;
    final post = _parse(_post) ?? 0;

    final total = pre + materials + (withGame ? game : 0) + post;
    if (total <= 0) return '-';

    String pct(double v) => '${(v / total * 100).round()}%';

    return 'Pre-test ${pct(pre)} · Materi ${pct(materials)}'
        '${withGame ? ' · Game ${pct(game)}' : ''} · Post-test ${pct(post)}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<ProgressWeights>>().submit(
          ProgressWeights(
            preTest: _parse(_pre)!,
            materials: _parse(_materials)!,
            game: _parse(_game)!,
            postTest: _parse(_post)!,
          ),
        );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      validator: _validate,
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
            Text(
              'Bobot menentukan seberapa besar tiap aktivitas menyumbang persentase '
              'progress course. Angkanya tidak harus berjumlah 100, hasilnya otomatis '
              'dinormalkan. Course tanpa simulasi 3D tidak memakai bobot game.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_pre, 'Pre-test'),
                  const SizedBox(height: 16),
                  _field(_materials, 'Materi'),
                  const SizedBox(height: 16),
                  _field(_game, 'Simulasi 3D (game)'),
                  const SizedBox(height: 16),
                  _field(_post, 'Post-test'),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pratinjau',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Course dengan game', style: theme.textTheme.labelLarge),
                        Text(_preview(withGame: true)),
                        const SizedBox(height: 8),
                        Text('Course tanpa game', style: theme.textTheme.labelLarge),
                        Text(_preview(withGame: false)),
                      ],
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
                        : const Text('Simpan Bobot'),
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