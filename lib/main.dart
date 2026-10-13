import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    initDependencies();
  } catch (e) {
    // Aplikasi tidak boleh crash jika Firebase gagal diinisialisasi.
    initError = e.toString();
  }

  runApp(App(initError: initError));
}