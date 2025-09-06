import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class LocalFileCacheService {
  static const String _cacheDirectoryName = 'vault_file_cache';
  static const int _maxCacheSizeMB = 100; // 100MB cache limit

  Directory? _cacheDirectory;

  /// Initialize the cache directory
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/$_cacheDirectoryName');

    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  /// Generate a cache key for a file
  String _generateCacheKey(String userId, String fileName) {
    final input = '$userId:$fileName';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store base64 file data in local cache
  Future<bool> cacheFileData({
    required String userId,
    required String fileName,
    required String base64Data,
    required String mimeType,
  }) async {
    try {
      await _ensureInitialized();

      final cacheKey = _generateCacheKey(userId, fileName);
      final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.cache');

      // Create cache entry with metadata
      final cacheEntry = {
        'userId': userId,
        'fileName': fileName,
        'mimeType': mimeType,
        'base64Data': base64Data,
        'cachedAt': DateTime.now().toIso8601String(),
        'fileSize': base64Data.length,
      };

      await cacheFile.writeAsString(jsonEncode(cacheEntry));

      // Clean up cache if it exceeds size limit
      await _cleanupCacheIfNeeded();

      print('✅ Cached file data for $fileName (${base64Data.length} bytes)');
      return true;
    } catch (e) {
      print('❌ Error caching file data for $fileName: $e');
      return false;
    }
  }

  /// Retrieve base64 file data from local cache
  Future<String?> getCachedFileData({
    required String userId,
    required String fileName,
  }) async {
    try {
      await _ensureInitialized();

      final cacheKey = _generateCacheKey(userId, fileName);
      final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.cache');

      if (!await cacheFile.exists()) {
        print('📁 No cached data found for $fileName');
        return null;
      }

      final cacheContent = await cacheFile.readAsString();
      final cacheEntry = jsonDecode(cacheContent) as Map<String, dynamic>;

      print(
        '✅ Retrieved cached data for $fileName (${cacheEntry['fileSize']} bytes)',
      );
      return cacheEntry['base64Data'] as String?;
    } catch (e) {
      print('❌ Error retrieving cached file data for $fileName: $e');
      return null;
    }
  }

  /// Remove cached file data
  Future<bool> removeCachedFileData({
    required String userId,
    required String fileName,
  }) async {
    try {
      await _ensureInitialized();

      final cacheKey = _generateCacheKey(userId, fileName);
      final cacheFile = File('${_cacheDirectory!.path}/$cacheKey.cache');

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('🗑️ Removed cached data for $fileName');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error removing cached file data for $fileName: $e');
      return false;
    }
  }

  /// Get all cached files for a user
  Future<List<Map<String, dynamic>>> getCachedFilesForUser(
    String userId,
  ) async {
    try {
      await _ensureInitialized();

      final cacheFiles = await _cacheDirectory!.list().toList();
      final userFiles = <Map<String, dynamic>>[];

      for (final file in cacheFiles) {
        if (file is File && file.path.endsWith('.cache')) {
          try {
            final content = await file.readAsString();
            final cacheEntry = jsonDecode(content) as Map<String, dynamic>;

            if (cacheEntry['userId'] == userId) {
              userFiles.add({
                'fileName': cacheEntry['fileName'],
                'mimeType': cacheEntry['mimeType'],
                'cachedAt': cacheEntry['cachedAt'],
                'fileSize': cacheEntry['fileSize'],
              });
            }
          } catch (e) {
            print('⚠️ Error reading cache file ${file.path}: $e');
          }
        }
      }

      print('📁 Found ${userFiles.length} cached files for user $userId');
      return userFiles;
    } catch (e) {
      print('❌ Error getting cached files for user: $e');
      return [];
    }
  }

  /// Clear all cached data for a user
  Future<void> clearUserCache(String userId) async {
    try {
      await _ensureInitialized();

      final cacheFiles = await _cacheDirectory!.list().toList();
      int deletedCount = 0;

      for (final file in cacheFiles) {
        if (file is File && file.path.endsWith('.cache')) {
          try {
            final content = await file.readAsString();
            final cacheEntry = jsonDecode(content) as Map<String, dynamic>;

            if (cacheEntry['userId'] == userId) {
              await file.delete();
              deletedCount++;
            }
          } catch (e) {
            print('⚠️ Error processing cache file ${file.path}: $e');
          }
        }
      }

      print('🗑️ Cleared $deletedCount cached files for user $userId');
    } catch (e) {
      print('❌ Error clearing user cache: $e');
    }
  }

  /// Get current cache size in bytes
  Future<int> getCacheSize() async {
    try {
      await _ensureInitialized();

      final cacheFiles = await _cacheDirectory!.list().toList();
      int totalSize = 0;

      for (final file in cacheFiles) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      print('❌ Error calculating cache size: $e');
      return 0;
    }
  }

  /// Clean up cache if it exceeds the size limit
  Future<void> _cleanupCacheIfNeeded() async {
    try {
      final currentSize = await getCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      if (currentSize <= maxSizeBytes) {
        return;
      }

      print(
        '🧹 Cache size (${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB) exceeds limit (${_maxCacheSizeMB}MB), cleaning up...',
      );

      // Get all cache files with their modification times
      final cacheFiles = await _cacheDirectory!.list().toList();
      final fileStats = <Map<String, dynamic>>[];

      for (final file in cacheFiles) {
        if (file is File && file.path.endsWith('.cache')) {
          final stat = await file.stat();
          fileStats.add({
            'file': file,
            'modifiedAt': stat.modified,
            'size': stat.size,
          });
        }
      }

      // Sort by modification time (oldest first)
      fileStats.sort((a, b) => a['modifiedAt'].compareTo(b['modifiedAt']));

      // Delete oldest files until we're under the limit
      int deletedSize = 0;
      for (final fileStat in fileStats) {
        if (currentSize - deletedSize <= maxSizeBytes) {
          break;
        }

        final file = fileStat['file'] as File;
        await file.delete();
        deletedSize += fileStat['size'] as int;
        print('🗑️ Deleted old cache file: ${file.path}');
      }

      print(
        '✅ Cache cleanup completed, freed ${(deletedSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    } catch (e) {
      print('❌ Error during cache cleanup: $e');
    }
  }

  /// Ensure cache directory is initialized
  Future<void> _ensureInitialized() async {
    if (_cacheDirectory == null) {
      await initialize();
    }
  }
}
