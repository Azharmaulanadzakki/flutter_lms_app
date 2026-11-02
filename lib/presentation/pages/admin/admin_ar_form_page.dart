import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/ar_links.dart';
import '../../../domain/entities/ar_asset_kind.dart';
import '../../../domain/entities/ar_item.dart';
import '../../../domain/usecases/ar/ar_upload_usecase.dart';
import '../../../domain/usecases/ar/ar_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/ar_widgets.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

class AdminArFormPage extends StatelessWidget {
  const AdminArFormPage({super.key, this.itemId});

  /// Null = model AR baru.
  final String? itemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminFormCubit<ArItem>(
        load: () => sl<GetArFormUseCase>()(itemId),
        save: (item) async {
          await sl<SaveArItemUseCase>()(item);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(itemId == null ? 'Tambah Model AR' : 'Edit Model AR'),
        ),
        body: BlocConsumer<AdminFormCubit<ArItem>, AdminFormState<ArItem>>(
          listenWhen: (prev, curr) => prev.status != curr.status || curr.error != null,
          listener: (context, state) => handleAdminFormState(
            context,
            state,
            savedMessage: 'Model AR tersimpan.',
          ),
          builder: (context, state) {
            final initial = state.initial;

            if (initial == null) {
              if (state.status == AdminFormStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat data.',
                  onRetry: () => context.read<AdminFormCubit<ArItem>>().init(),
                );
              }
              return const LoadingView();
            }

            return _ArForm(
              initial: initial,
              isSaving: state.status == AdminFormStatus.saving,
            );
          },
        ),
      ),
    );
  }
}

class _ArForm extends StatefulWidget {
  const _ArForm({required this.initial, required this.isSaving});

  final ArItem initial;
  final bool isSaving;

  @override
  State<_ArForm> createState() => _ArFormState();
}

class _ArFormState extends State<_ArForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _markerUrl;
  late final TextEditingController _modelUrl;
  late final TextEditingController _markerImageUrl;
  late final TextEditingController _credit;
  late final TextEditingController _scale;
  late final TextEditingController _offsetY;
  late final TextEditingController _rotX;
  late final TextEditingController _rotY;
  late final TextEditingController _rotZ;
  late final TextEditingController _order;
  late bool _animate;
  late bool _isPublished;

  /// Jenis berkas yang sedang diunggah, atau null.
  ArAssetKind? _uploading;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  static double? _parse(String? text) =>
      double.tryParse((text ?? '').trim().replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i.title);
    _description = TextEditingController(text: i.description);
    _markerUrl = TextEditingController(text: i.markerUrl);
    _modelUrl = TextEditingController(text: i.modelUrl);
    _markerImageUrl = TextEditingController(text: i.markerImageUrl);
    _credit = TextEditingController(text: i.credit);
    _scale = TextEditingController(text: _fmt(i.scale));
    _offsetY = TextEditingController(text: _fmt(i.offsetY));
    _rotX = TextEditingController(text: _fmt(i.rotationX));
    _rotY = TextEditingController(text: _fmt(i.rotationY));
    _rotZ = TextEditingController(text: _fmt(i.rotationZ));
    _order = TextEditingController(text: '${i.order}');
    _animate = i.animate;
    _isPublished = i.isPublished;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _markerUrl,
      _modelUrl,
      _markerImageUrl,
      _credit,
      _scale,
      _offsetY,
      _rotX,
      _rotY,
      _rotZ,
      _order,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

    Future<void> _pickAndUpload(
    ArAssetKind kind,
    TextEditingController target,
  ) async {
    XFile? picked;
    try {
      // Tanpa filter tipe: semua file bisa dipilih. Ekstensi diperiksa sesudahnya.
      picked = await openFile();
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Tidak bisa membuka pemilih file.', isError: true);
      }
      return;
    }

    final file = picked;
    if (file == null) return;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'File tidak bisa dibaca. Coba file lain.', isError: true);
      }
      return;
    }

    setState(() => _uploading = kind);
    try {
      final url = await sl<UploadArAssetUseCase>()(
        bytes: bytes,
        fileName: file.name,
        kind: kind,
      );
      if (!mounted) return;
      setState(() => target.text = url);
      showAppSnackBar(context, 'Berhasil diunggah: ${file.name}');
    } on Failure catch (f) {
      if (mounted) showAppSnackBar(context, f.message, isError: true);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Unggah gagal. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<ArItem>>().submit(
          ArItem(
            id: widget.initial.id,
            title: _title.text,
            description: _description.text,
            markerUrl: _markerUrl.text,
            modelUrl: _modelUrl.text,
            markerImageUrl: _markerImageUrl.text,
            credit: _credit.text,
            scale: _parse(_scale.text)!,
            offsetY: _parse(_offsetY.text)!,
            rotationX: _parse(_rotX.text)!,
            rotationY: _parse(_rotY.text)!,
            rotationZ: _parse(_rotZ.text)!,
            animate: _animate,
            order: int.parse(_order.text.trim()),
            isPublished: _isPublished,
          ),
        );
  }

  Widget _numField(
    TextEditingController controller,
    String label, {
    String? helper,
    bool positive = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, helperText: helper),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      validator: (v) {
        final n = _parse(v);
        if (n == null) return 'Harus berupa angka';
        if (positive && n <= 0) return 'Harus lebih dari 0';
        return null;
      },
    );
  }

  Widget _assetField({
    required TextEditingController controller,
    required String label,
    required String helper,
    required ArAssetKind kind,
    required String? Function(String?) validator,
  }) {
    final uploading = _uploading == kind;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, helperText: helper),
          keyboardType: TextInputType.url,
          validator: validator,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _uploading != null ? null : () => _pickAndUpload(kind, controller),
            icon: uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(uploading ? 'Mengunggah...' : 'Unggah ${kind.label} dari perangkat'),
          ),
        ),
        if (kind == ArAssetKind.image && controller.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: MarkerThumb(url: normalizeAssetUrl(controller.text), size: 96),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.isSaving || _uploading != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const ExpansionTile(
                title: Text('Panduan singkat'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Model: unduh dari Sketchfab dalam format "glTF Binary (.glb)", lalu tekan '
                    '"Unggah model 3D". Sebaiknya di bawah 15 MB (maksimal 30 MB).',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. Cukup model saja sudah bisa dipakai untuk "Lihat 3D" dan "AR tanpa marker".',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. Marker (opsional, untuk AR marker): pilih gambar kaya detail. Buka '
                    'hiukim.github.io/mind-ar-js-doc/tools/compile, unggah gambar, tekan Start, '
                    'unduh .mind. Unggah file .mind dan gambar aslinya di sini.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '4. Simpan sebagai draft, tekan Coba AR di daftar, lalu publikasikan jika sudah pas.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  _assetField(
                    controller: _modelUrl,
                    label: 'Link model 3D (.glb)',
                    helper: 'Terisi otomatis setelah diunggah, atau tempel link langsung',
                    kind: ArAssetKind.model,
                    validator: (v) => validateAssetUrl(
                      v ?? '',
                      label: 'Link model',
                      extension: '.glb',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _assetField(
                    controller: _markerImageUrl,
                    label: 'Gambar marker (opsional)',
                    helper: 'Gambar yang dilihat siswa dan di-scan kamera',
                    kind: ArAssetKind.image,
                    validator: (v) {
                      final url = (v ?? '').trim();
                      if (url.isEmpty) {
                        return _markerUrl.text.trim().isEmpty
                            ? null
                            : 'Wajib diisi jika memakai marker (.mind)';
                      }
                      return validateOptionalUrl(url, label: 'Link gambar marker');
                    },
                  ),
                  const SizedBox(height: 24),
                  _assetField(
                    controller: _markerUrl,
                    label: 'File marker (.mind, opsional)',
                    helper: 'Hanya untuk mode AR marker',
                    kind: ArAssetKind.marker,
                    validator: (v) {
                      final url = (v ?? '').trim();
                      if (url.isEmpty) return null;
                      return validateAssetUrl(url, label: 'Link marker', extension: '.mind');
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _credit,
                    decoration: const InputDecoration(
                      labelText: 'Kredit model (opsional)',
                      helperText: 'Contoh: "Nama Model" oleh Nama Pembuat (CC BY 4.0)',
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Penyesuaian AR marker',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hanya berpengaruh di mode AR marker. Ukuran model sudah disesuaikan '
                    'otomatis dengan lebar marker. Jika model tampak rebah, ubah Rotasi X '
                    '(coba 90 atau -90).',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _numField(_scale, 'Skala', helper: '1 = selebar marker', positive: true),
                  const SizedBox(height: 16),
                  _numField(_offsetY, 'Geser naik/turun', helper: '0 = menempel di marker'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _numField(_rotX, 'Rotasi X')),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_rotY, 'Rotasi Y')),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_rotZ, 'Rotasi Z')),
                    ],
                  ),
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
                    title: const Text('Putar animasi model'),
                    subtitle: const Text('Hanya berpengaruh jika model punya animasi bawaan.'),
                    value: _animate,
                    onChanged: (v) => setState(() => _animate = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dipublikasikan'),
                    subtitle: const Text(
                      'Siswa hanya melihat model yang dipublikasikan. Simpan sebagai draft dulu untuk mencoba.',
                    ),
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : _submit,
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