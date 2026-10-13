class Validators {
  Validators._();

  static String? requiredField(String? value, {String field = 'Kolom'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, field: 'Email');
    if (required != null) return required;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return valid ? null : 'Format email tidak valid';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
    if (value != original) return 'Password tidak sama';
    return null;
  }
}