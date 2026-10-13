import '../../core/errors/failure_guard.dart';
import '../../domain/entities/progress_weights.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._remote);

  final SettingsRemoteDataSource _remote;

  @override
  Future<ProgressWeights> getProgressWeights() async {
    try { 
      final data = await guardFirebase(
        _remote.getProgressWeightsData,
        timeout: const Duration(seconds: 5),
      );
      return ProgressWeights.tryParse(data) ?? ProgressWeights.defaults;
    } catch (_) {
      // Gagal membaca bobot tidak boleh menggagalkan fitur lain.
      return ProgressWeights.defaults;
    }
  }
}