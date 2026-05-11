import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fieldpulse/src/app/providers/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/queue/sync_queue_dao.dart'; // we'll create this

class PhotoUploadService {
  final Dio _dio;
  final SyncQueueDao _queueDao;

  PhotoUploadService(this._dio, this._queueDao);

  Future<String> uploadPhoto({
    required int jobId,
    required String fieldId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
      'field_id': fieldId,
    });
    try {
      final response = await _dio.post('/jobs/$jobId/photos/', data: formData);
      return response.data['image_url'];
    } catch (e) {
      // Queue for later
      await _queueDao.addSyncItem(
        jobId: jobId,
        action: 'photo_upload',
        payload: {
          'field_id': fieldId,
          'local_path': filePath,
        },
      );
      rethrow; // caller will handle offline store
    }
  }

  Future<String> uploadSignature({
    required int jobId,
    required String fieldId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'signature': await MultipartFile.fromFile(filePath),
    });
    try {
      final response = await _dio.post('/jobs/$jobId/signature/', data: formData);
      return response.data['signature_url'];
    } catch (e) {
      await _queueDao.addSyncItem(
        jobId: jobId,
        action: 'signature_upload',
        payload: {
          'field_id': fieldId,
          'local_path': filePath,
        },
      );
      rethrow;
    }
  }
}

final photoUploadServiceProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  final queueDao = SyncQueueDao(); // implement or use a provider
  return PhotoUploadService(dio, queueDao);
});