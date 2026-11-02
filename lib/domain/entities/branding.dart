import 'package:equatable/equatable.dart';

import '../../core/constants/app_strings.dart';

/// Identitas aplikasi: nama dan logo. Dikelola admin.
class Branding extends Equatable {
  const Branding({required this.appName, this.logoUrl = ''});

  final String appName;

  /// Link gambar logo. Kosong berarti memakai logo bawaan.
  final String logoUrl;

  static const defaults = Branding(appName: AppStrings.appName);

  bool get hasLogo => logoUrl.trim().isNotEmpty;

  @override
  List<Object?> get props => [appName, logoUrl];
}
