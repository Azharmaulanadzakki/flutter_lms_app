import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/branding.dart';
import '../../../domain/usecases/branding/branding_usecases.dart';

class BrandingState extends Equatable {
  const BrandingState({this.branding = Branding.defaults});

  final Branding branding;

  @override
  List<Object?> get props => [branding];
}

/// Menyimpan nama dan logo aplikasi untuk seluruh aplikasi.
class BrandingCubit extends Cubit<BrandingState> {
  BrandingCubit(this._getBranding) : super(const BrandingState());

  final GetBrandingUseCase _getBranding;

  Future<void> load() async {
    final branding = await _getBranding();
    if (isClosed) return;
    emit(BrandingState(branding: branding));
  }

  /// Dipanggil setelah admin menyimpan, supaya tampilan langsung berubah.
  void apply(Branding branding) {
    if (isClosed) return;
    emit(BrandingState(branding: branding));
  }
}

extension BrandingContext on BuildContext {
  /// Nama aplikasi terkini. Hanya dipakai di dalam build().
  String get appName => select((BrandingCubit c) => c.state.branding.appName);
}
