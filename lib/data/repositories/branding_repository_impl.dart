import '../../core/errors/failure_guard.dart';
import '../../domain/entities/branding.dart';
import '../../domain/repositories/branding_repository.dart';
import '../datasources/branding_remote_datasource.dart';

class BrandingRepositoryImpl implements BrandingRepository {
  BrandingRepositoryImpl(this._remote);

  final BrandingRemoteDataSource _remote;

  @override
  Future<Branding> getBranding() => guardFirebase<Branding>(
    () async => (await _remote.get()) ?? Branding.defaults,
    timeout: const Duration(seconds: 8),
  );

  @override
  Future<void> saveBranding(Branding branding) =>
      guardFirebase<void>(() => _remote.save(branding));
}
