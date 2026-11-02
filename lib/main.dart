
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  // Memuat library AR lokal tanpa menghentikan aplikasi
  // jika terjadi masalah pada aset.
  try {
  } catch (e) {
    debugPrint('Gagal memuat aset AR: $e');
  }

  // Inisialisasi Firebase.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));

    initDependencies();
  } catch (e) {
    // Aplikasi tetap dibuka jika Firebase gagal.
    initError = e.toString();
    debugPrint('Inisialisasi Firebase gagal: $e');
  }

  runApp(App(initError: initError));
}
