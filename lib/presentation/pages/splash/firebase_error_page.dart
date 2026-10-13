import 'package:flutter/material.dart';

/// Ditampilkan jika Firebase gagal diinisialisasi (aplikasi tidak crash).
class FirebaseErrorPage extends StatelessWidget {
  const FirebaseErrorPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Firebase gagal terhubung',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}