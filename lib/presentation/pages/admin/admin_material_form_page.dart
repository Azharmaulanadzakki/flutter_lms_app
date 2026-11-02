import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/media_links.dart';
import '../../../domain/entities/course_material.dart';
import '../../../domain/usecases/admin/admin_material_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminMaterialFormPage extends StatelessWidget {
  const AdminMaterialFormPage({
    super.key,
    required this.courseId,
    this.materialId,
  });

  final String courseId;

  /// Null = materi baru.
  final String? materialId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<CourseMaterial>(
        load: () => sl<GetMaterialFormUseCase>()(
          courseId: courseId,
          materialId: materialId,
        ),
        save: (material) async {
          await sl<SaveMaterialUseCase>()(material);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(materialId == null ? 'Tambah Materi' : 'Edit Materi'),
        ),
        body:
            BlocConsumer<
              AdminFormCubit<CourseMaterial>,
              AdminFormState<CourseMaterial>
            >(
              listenWhen: (prev, curr) =>
                  prev.status != curr.status || curr.error != null,
              listener: (context, state) => handleAdminFormState(
                context,
                state,
                savedMessage: 'Materi tersimpan.',
              ),
              builder: (context, state) {
                final initial = state.initial;

                if (initial == null) {
                  if (state.status == AdminFormStatus.failure) {
                    return ErrorView(
                      message: state.loadError ?? 'Gagal memuat data.',
                      onRetry: () =>
                          context.read<AdminFormCubit<CourseMaterial>>().init(),
                    );
                  }
                  return const LoadingView();
                }

                return _MaterialForm(
                  initial: initial,
                  isSaving: state.status == AdminFormStatus.saving,
                );
              },
            ),
      ),
    );
  }
}

class _MaterialForm extends StatefulWidget {
  const _MaterialForm({required this.initial, required this.isSaving});

  final CourseMaterial initial;
  final bool isSaving;

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _url;
  late final TextEditingController _order;
  late MaterialKind _type;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _title = TextEditingController(text: m.title);
    _content = TextEditingController(text: m.content);
    _url = TextEditingController(text: m.mediaUrl);
    _order = TextEditingController(text: '${m.order}');
    _type = m.type;
    _isPublished = m.isPublished;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _url.dispose();
    _order.dispose();
    super.dispose();
  }

  static String _typeLabel(MaterialKind type) {
    switch (type) {
      case MaterialKind.text:
        return 'Teks (bacaan)';
      case MaterialKind.video:
        return 'Video YouTube';
      case MaterialKind.pdf:
        return 'PDF';
    }
  }

  String? _validateUrl(String? value) {
    final url = (value ?? '').trim();
    if (url.isEmpty) return null;
    if (_type == MaterialKind.video && extractYoutubeId(url) == null) {
      return 'Link YouTube tidak dikenali';
    }
    if (_type == MaterialKind.pdf && !isValidHttpUrl(url)) {
      return 'Link harus diawali https://';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<CourseMaterial>>().submit(
      CourseMaterial(
        id: widget.initial.id,
        courseId: widget.initial.courseId,
        title: _title.text,
        content: _content.text,
        type: _type,
        mediaUrl: _url.text,
        order: int.parse(_order.text.trim()),
        isPublished: _isPublished,
      ),
    );
  }

  Widget _urlHint(BuildContext context) {
    final theme = Theme.of(context);
    final url = _url.text.trim();

    if (_type == MaterialKind.video) {
      if (url.isEmpty) {
        return Text(
          'Unggah video ke YouTube sebagai Unlisted dan aktifkan "Allow embedding".',
          style: theme.textTheme.bodySmall,
        );
      }
      final id = extractYoutubeId(url);
      return Text(
        id == null
            ? 'Link YouTube tidak dikenali.'
            : 'Video terdeteksi (ID: $id).',
        style: theme.textTheme.bodySmall?.copyWith(
          color: id == null ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
    }

    return Text(
      'Link Google Drive (bagikan: Anyone with the link) atau alamat file .pdf.',
      style: theme.textTheme.bodySmall,
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
                      labelText: 'Judul materi',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MaterialKind>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Tipe materi'),
                    items: [
                      for (final type in MaterialKind.values)
                        DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(type)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _type = value ?? _type),
                  ),
                  const SizedBox(height: 16),
                  if (_type == MaterialKind.text)
                    TextFormField(
                      controller: _content,
                      decoration: const InputDecoration(
                        labelText: 'Isi materi',
                        alignLabelWithHint: true,
                      ),
                      minLines: 8,
                      maxLines: 20,
                    )
                  else ...[
                    TextFormField(
                      controller: _url,
                      decoration: InputDecoration(
                        labelText: _type == MaterialKind.video
                            ? 'Link YouTube'
                            : 'Link PDF',
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                      validator: _validateUrl,
                    ),
                    const SizedBox(height: 8),
                    _urlHint(context),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _order,
                    decoration: const InputDecoration(labelText: 'Urutan'),
                    keyboardType: TextInputType.number,
                    validator: (v) => validateInt(v, field: 'Urutan', min: 1),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dipublikasikan'),
                    subtitle: const Text(
                      'Materi draft tidak tampil untuk siswa.',
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
