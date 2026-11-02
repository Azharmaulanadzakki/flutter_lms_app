import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/admin/admin_form_cubit.dart';
import '../../widgets/app_snackbar.dart';

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: Colors.red.shade700)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Listener bersama untuk semua form admin: tutup halaman setelah tersimpan,
/// atau tampilkan pesan error.
void handleAdminFormState(
  BuildContext context,
  AdminFormState<dynamic> state, {
  required String savedMessage,
}) {
  if (state.status == AdminFormStatus.saved) {
    showAppSnackBar(context, savedMessage);
    context.pop();
  } else if (state.error != null) {
    showAppSnackBar(context, state.error!, isError: true);
  }
}

/// Validator angka bulat dengan batas minimal (dan maksimal, opsional).
String? validateInt(
  String? value, {
  required String field,
  int min = 0,
  int? max,
}) {
  final number = int.tryParse((value ?? '').trim());
  if (number == null) return '$field harus berupa angka bulat';
  if (number < min) return '$field minimal $min';
  if (max != null && number > max) return '$field maksimal $max';
  return null;
}

/// Label kecil berwarna, misalnya "Dipublikasikan" atau "Draft".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
