import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Manages PDF file caching to disk
class PdfCacheManager {
  static const String _cacheDirectory = 'pdf_cache';

  /// Gets the cache directory path
  static Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheDirectory');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Generates a unique cache key from URL
  static String _generateCacheKey(String url) {
    // Create a hash of the URL for the filename
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets the cache file path for a given URL
  static Future<File> _getCacheFile(String url) async {
    final cacheDir = await _getCacheDirectory();
    final cacheKey = _generateCacheKey(url);
    return File('${cacheDir.path}/$cacheKey.pdf');
  }

  /// Checks if a PDF is cached for the given URL
  static Future<bool> isCached(String url) async {
    try {
      final file = await _getCacheFile(url);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets the cached PDF file if it exists
  static Future<File?> getCachedFile(String url) async {
    try {
      final file = await _getCacheFile(url);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Saves PDF bytes to cache
  static Future<File> savePdfToCache(String url, List<int> bytes) async {
    final file = await _getCacheFile(url);
    return await file.writeAsBytes(bytes);
  }

  /// Removes a specific cached PDF
  static Future<void> removeCachedPdf(String url) async {
    try {
      final file = await _getCacheFile(url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail if file doesn't exist or can't be deleted
    }
  }

  /// Clears all cached PDFs
  static Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      // Silently fail if directory doesn't exist or can't be deleted
    }
  }

  /// Gets the total size of cached PDFs in bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Gets the number of cached PDF files
  static Future<int> getCacheFileCount() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int count = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Gets cache statistics
  static Future<CacheStats> getCacheStats() async {
    final size = await getCacheSize();
    final count = await getCacheFileCount();
    return CacheStats(fileCount: count, totalSizeBytes: size);
  }
}

/// Cache statistics data class
class CacheStats {
  final int fileCount;
  final int totalSizeBytes;

  CacheStats({
    required this.fileCount,
    required this.totalSizeBytes,
  });

  /// Get size in MB
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'CacheStats(files: $fileCount, size: ${totalSizeMB.toStringAsFixed(2)} MB)';
  }
}
