import 'package:flutter/material.dart';

Future<bool> confirmSubmitDialog(
  BuildContext context, {
  required int unanswered,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kirim jawaban?'),
      content: Text(
        unanswered > 0
            ? 'Masih ada $unanswered soal yang belum dijawab. '
                'Jawaban tidak bisa diubah setelah dikirim.'
            : 'Jawaban tidak bisa diubah setelah dikirim.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Periksa lagi'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> confirmLeaveDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keluar dari test?'),
      content: const Text(
        'Jawaban yang belum dikirim tidak tersimpan. '
        'Kamu bisa melanjutkan nanti, tetapi waktu tetap berjalan jika test ini memakai timer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Lanjut mengerjakan'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  return ok ?? false;
}