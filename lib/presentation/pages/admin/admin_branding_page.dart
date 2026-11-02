import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_links.dart';
import '../../../domain/entities/branding.dart';
import '../../../domain/usecases/branding/branding_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../blocs/branding/branding_cubit.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminBrandingPage extends StatelessWidget {
  const AdminBrandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brandingCubit = context.read<BrandingCubit>();

    return BlocProvider(
      create: (_) => AdminFormCubit<Branding>(
        load: () => sl<GetBrandingFormUseCase>()(),
        save: (value) async {
          final saved = await sl<SaveBrandingUseCase>()(value);
          // Tampilan seluruh aplikasi langsung berubah.
          brandingCubit.apply(saved);
        },
      )..init(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Aplikasi')),
        body: BlocConsumer<AdminFormCubit<Branding>, AdminFormState<Branding>>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status || curr.error != null,
          listener: (context, state) => handleAdminFormState(
            context,
            state,
            savedMessage: 'Pengaturan aplikasi tersimpan.',
          ),
          builder: (context, state) {
            final initial = state.initial;

            if (initial == null) {
              if (state.status == AdminFormStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat pengaturan.',
                  onRetry: () =>
                      context.read<AdminFormCubit<Branding>>().init(),
                );
              }
              return const LoadingView();
            }

            return _BrandingForm(
              initial: initial,
              isSaving: state.status == AdminFormStatus.saving,
            );
          },
        ),
      ),
    );
  }
}

class _BrandingForm extends StatefulWidget {
  const _BrandingForm({required this.initial, required this.isSaving});

  final Branding initial;
  final bool isSaving;

  @override
  State<_BrandingForm> createState() => _BrandingFormState();
}

class _BrandingFormState extends State<_BrandingForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _logo;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.appName);
    _logo = TextEditingController(text: widget.initial.logoUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    XFile? picked;
    try {
      picked = await openFile();
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Tidak bisa membuka pemilih file.',
          isError: true,
        );
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
        showAppSnackBar(
          context,
          'File tidak bisa dibaca. Coba file lain.',
          isError: true,
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final url = await sl<UploadBrandingLogoUseCase>()(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() => _logo.text = url);
      showAppSnackBar(context, 'Logo diunggah. Tekan Simpan untuk menerapkan.');
    } on Failure catch (f) {
      if (mounted) showAppSnackBar(context, f.message, isError: true);
    } catch (_) {
      if (mounted)
        showAppSnackBar(context, 'Unggah gagal. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _resetToDefault() {
    setState(() {
      _name.text = AppStrings.appName;
      _logo.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<Branding>>().submit(
      Branding(appName: _name.text, logoUrl: _logo.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.isSaving || _uploading;
    final previewName = _name.text.trim().isEmpty
        ? AppStrings.appName
        : _name.text.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Pratinjau', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  BrandLogo(url: _logo.text, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      previewName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nama dan logo tampil di Splash, Landing, Login, dan judul jendela. '
              'Nama dan ikon di layar utama HP tidak ikut berubah (lihat panduan).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Nama aplikasi',
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama aplikasi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _logo,
                    decoration: const InputDecoration(
                      labelText: 'Link logo (opsional)',
                      helperText: 'Terisi otomatis setelah unggah. Kosong berarti logo bawaan.',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final url = (v ?? '').trim();
                      if (url.isEmpty || isValidHttpUrl(url)) return null;
                      return 'Link harus diawali https://';
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy ? null : _pickAndUpload,
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _uploading ? 'Mengunggah...' : 'Unggah logo',
                        ),
                      ),
                      if (_logo.text.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: busy ? null : () => setState(_logo.clear),
                          icon: const Icon(Icons.hide_image_outlined),
                          label: const Text('Hapus logo'),
                        ),
                      TextButton.icon(
                        onPressed: busy ? null : _resetToDefault,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Kembalikan ke bawaan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Format PNG, JPG, atau WebP, maksimal 2 MB. Disarankan PNG persegi '
                    'dengan latar transparan.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
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
