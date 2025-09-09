import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/google_drive_repository.dart';
import '../../domain/entities/drive_file.dart';

class GoogleDriveContextPrewarmService {
  static final GoogleDriveContextPrewarmService _instance =
      GoogleDriveContextPrewarmService._internal();
  factory GoogleDriveContextPrewarmService() => _instance;
  GoogleDriveContextPrewarmService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;

  final StreamController<bool> _prewarmStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get prewarmStatusStream => _prewarmStatusController.stream;

  GoogleDriveRepository get _repository => _getIt<GoogleDriveRepository>();

  Future<bool> isGoogleDriveConnected() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _repository.isGoogleDriveConnected(user.uid);
  }

  Future<void> prewarmGoogleDriveContext() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      _prewarmStatusController.add(true);

      final connected = await isGoogleDriveConnected();
      if (!connected) {
        _prewarmStatusController.add(false);
        return;
      }

      final files = await _repository.getDriveFiles(user.uid);
      final context = _buildDriveContext(files);

      await _firestore
          .collection('HushUsers')
          .doc(user.uid)
          .collection('pda_context')
          .doc('google_drive')
          .set({
            'context': context,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      _prewarmStatusController.add(false);
    } catch (e) {
      debugPrint('❌ [DRIVE PREWARM] $e');
      _prewarmStatusController.add(false);
    }
  }

  Map<String, dynamic> _buildDriveContext(List<DriveFile> files) {
    final totalFiles = files.length;
    final images = files
        .where((f) => (f.mimeType ?? '').startsWith('image/'))
        .length;
    final pdfs = files.where((f) => f.mimeType == 'application/pdf').length;
    final docs = files
        .where((f) => (f.mimeType ?? '').contains('document'))
        .length;

    return {
      'summary':
          'Drive has $totalFiles files ($images images, $pdfs PDFs, $docs docs).',
      'topFiles': files
          .take(10)
          .map(
            (f) => {
              'name': f.name,
              'mimeType': f.mimeType,
              'modified': f.modifiedTime?.toIso8601String(),
            },
          )
          .toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
