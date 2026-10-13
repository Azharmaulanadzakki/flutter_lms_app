import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/test_attempt.dart';
import '../models/test_attempt_model.dart';

abstract class HistoryRemoteDataSource {
  Future<List<TestAttemptModel>> getGradedAttempts(String userId);
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  HistoryRemoteDataSourceImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<TestAttemptModel>> getGradedAttempts(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.testAttempts)
        .where('userId', isEqualTo: userId)
        .get();

    // Disaring di sisi aplikasi supaya tidak butuh composite index.
    return snap.docs
        .map((doc) => TestAttemptModel.fromFirestore(doc))
        .where((a) => a.status == AttemptStatus.graded)
        .toList();
  }
}