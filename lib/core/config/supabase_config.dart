/// Kunci "anon" Supabase memang publik. Keamanan dijaga policy bucket:
/// hanya boleh menambah file, tidak boleh menghapus atau menimpa.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://mzzsukbolvigtohxjava.supabase.co';
  static const String anonKey =
      'sb_publishable_AC7C2ZYMb42tv8zrwB7Kwg_krmLFLpg';
  static const String bucket = 'ar-assets';

  static bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('GANTI') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('GANTI');

  static String get baseUrl =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static Uri uploadUri(String objectPath) =>
      Uri.parse('$baseUrl/storage/v1/object/$bucket/$objectPath');

  static String publicUrl(String objectPath) =>
      '$baseUrl/storage/v1/object/public/$bucket/$objectPath';
}
