import '../entities/branding.dart';

abstract class BrandingRepository {
  /// Branding dari Firestore. Mengembalikan nilai bawaan jika dokumen belum ada,
  /// dan melempar Failure jika gagal membaca.
  Future<Branding> getBranding();

  Future<void> saveBranding(Branding branding);
}
