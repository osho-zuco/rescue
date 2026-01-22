/// Cloudinary Upload Service
///
/// Handles direct uploads to Cloudinary using signed URLs from backend.
///
/// Flow:
/// 1. Get signature from backend (GET /upload/signature)
/// 2. Upload file directly to Cloudinary
/// 3. Return the secure URL
///
/// Usage:
/// ```dart
/// final service = getIt<CloudinaryUploadService>();
/// final urls = await service.uploadPhotos(localPaths, folder: 'boarders');
/// ```

import 'dart:io';

import 'package:dio/dio.dart';
import 'logger.dart';

/// Maximum file size allowed for upload (5 MB)
const int kMaxUploadFileSizeBytes = 5 * 1024 * 1024;

/// Folder types for organizing uploads
enum UploadFolder { boarders, pets, profiles, updates }

/// Result of a single upload
class UploadResult {
  final String secureUrl;
  final String publicId;
  final int width;
  final int height;

  const UploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    final secureUrl = json['secure_url'];
    final publicId = json['public_id'];
    
    if (secureUrl == null || publicId == null) {
      throw FormatException('Invalid Cloudinary response: missing required fields');
    }
    
    return UploadResult(
      secureUrl: secureUrl as String,
      publicId: publicId as String,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }
}

class CloudinaryUploadService {
  final Dio _dio;
  static const String _tag = 'CloudinaryUpload';

  CloudinaryUploadService({required Dio dio}) : _dio = dio;

  /// Upload multiple photos and return their URLs
  ///
  /// Returns list of secure URLs, or null if any upload fails.
  /// Shows progress via optional callback.
  ///
  /// Photos are uploaded in PARALLEL for speed.
  Future<List<String>?> uploadPhotos(
    List<String> localPaths, {
    UploadFolder folder = UploadFolder.boarders,
    void Function(int uploaded, int total)? onProgress,
  }) async {
    if (localPaths.isEmpty) return [];

    try {
      // 1. Get upload signature from backend
      final signature = await _getSignature(folder);
      if (signature == null) {
        Log.e('Failed to get upload signature', tag: _tag);
        return null;
      }

      // 2. Upload ALL photos in PARALLEL
      final cloudinaryDio =
          Dio(); // Separate Dio for Cloudinary (no auth header)
      var completed = 0;

      Log.d(
        'Starting parallel upload of ${localPaths.length} photos',
        tag: _tag,
      );
      final startTime = DateTime.now();

      final futures = localPaths.map((path) async {
        final result = await _uploadSingleFile(cloudinaryDio, path, signature);
        completed++;
        onProgress?.call(completed, localPaths.length);
        return result;
      }).toList();

      final results = await Future.wait(futures);

      final elapsed = DateTime.now().difference(startTime);
      Log.i(
        'Parallel upload completed in ${elapsed.inMilliseconds}ms',
        tag: _tag,
      );

      // Check if any failed
      if (results.any((r) => r == null)) {
        Log.e('One or more uploads failed', tag: _tag);
        return null;
      }

      final urls = results.map((r) => r!.secureUrl).toList();
      Log.i('Successfully uploaded ${urls.length} photos', tag: _tag);
      return urls;
    } catch (e) {
      Log.e('Upload failed: $e', tag: _tag);
      return null;
    }
  }

  /// Upload a SINGLE photo immediately (for upload-on-selection)
  /// Returns the secure URL or null if failed.
  Future<String?> uploadSinglePhoto(
    String localPath, {
    UploadFolder folder = UploadFolder.boarders,
  }) async {
    try {
      final signature = await _getSignature(folder);
      if (signature == null) return null;

      final cloudinaryDio = Dio();
      final result = await _uploadSingleFile(
        cloudinaryDio,
        localPath,
        signature,
      );

      if (result != null) {
        Log.i('Single photo uploaded: ${result.secureUrl}', tag: _tag);
        return result.secureUrl;
      }
      return null;
    } catch (e) {
      Log.e('Single upload failed: $e', tag: _tag);
      return null;
    }
  }

  /// Get upload signature from backend
  Future<_UploadSignature?> _getSignature(UploadFolder folder) async {
    try {
      final response = await _dio.get(
        '/upload/signature',
        queryParameters: {'folder': folder.name},
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        Log.e('Invalid signature response: missing data', tag: _tag);
        return null;
      }
      
      final signature = data['signature'] as String?;
      final timestamp = data['timestamp'] as int?;
      final cloudName = data['cloudName'] as String?;
      final apiKey = data['apiKey'] as String?;
      final folderPath = data['folder'] as String?;
      
      if (signature == null || timestamp == null || cloudName == null || 
          apiKey == null || folderPath == null) {
        Log.e('Invalid signature response: missing required fields', tag: _tag);
        return null;
      }
      
      return _UploadSignature(
        signature: signature,
        timestamp: timestamp,
        cloudName: cloudName,
        apiKey: apiKey,
        folder: folderPath,
      );
    } on DioException catch (e) {
      Log.e('Failed to get signature: ${e.message}', tag: _tag);
      return null;
    } catch (e) {
      Log.e('Unexpected error getting signature: $e', tag: _tag);
      return null;
    }
  }

  /// Upload a single file to Cloudinary
  Future<UploadResult?> _uploadSingleFile(
    Dio cloudinaryDio,
    String localPath,
    _UploadSignature signature,
  ) async {
    // Check file size before upload
    final file = File(localPath);
    final fileSize = await file.length();
    if (fileSize > kMaxUploadFileSizeBytes) {
      Log.e(
        'File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB (max: ${kMaxUploadFileSizeBytes ~/ 1024 ~/ 1024} MB)',
        tag: _tag,
      );
      return null;
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath),
      'api_key': signature.apiKey,
      'timestamp': signature.timestamp,
      'signature': signature.signature,
      'folder': signature.folder,
    });

    final response = await cloudinaryDio.post(
      'https://api.cloudinary.com/v1_1/${signature.cloudName}/image/upload',
      data: formData,
      options: Options(
        // Increase timeout for large files
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    if (response.statusCode == 200) {
      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      return UploadResult.fromJson(responseData);
    }

    return null;
  }

  /// Delete an uploaded file
  Future<bool> deletePhoto(String publicId) async {
    try {
      final response = await _dio.post(
        '/upload/delete',
        data: {'publicId': publicId},
      );
      return response.statusCode == 200;
    } catch (e) {
      Log.e('Failed to delete photo: $e', tag: _tag);
      return false;
    }
  }
}

/// Internal class for upload signature data
class _UploadSignature {
  final String signature;
  final int timestamp;
  final String cloudName;
  final String apiKey;
  final String folder;

  const _UploadSignature({
    required this.signature,
    required this.timestamp,
    required this.cloudName,
    required this.apiKey,
    required this.folder,
  });
}
