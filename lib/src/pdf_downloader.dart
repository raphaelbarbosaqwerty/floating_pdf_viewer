import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'pdf_cache_manager.dart';

/// Helper class to download PDF files from URLs
class PdfDownloader {
  /// Downloads PDF directly to bytes in memory
  static Future<Uint8List> downloadPdfBytes(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Downloads PDF with progress callback
  static Future<Uint8List> downloadPdfBytesWithProgress(
    String url,
    void Function(double progress) onProgress,
  ) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      int downloaded = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;

        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        }
      }

      final result = Uint8List.fromList(bytes);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets PDF file using cache system
  /// First checks if file is cached, if not downloads and caches it
  static Future<File> getPdfFileWithCache(
    String url,
    void Function(double progress)? onProgress,
  ) async {
    try {
      // Check if file is already cached
      final cachedFile = await PdfCacheManager.getCachedFile(url);
      if (cachedFile != null) {
        // File is cached, return it immediately
        onProgress?.call(1.0);
        return cachedFile;
      }

      // File not cached, download it
      final bytes = onProgress != null
          ? await downloadPdfBytesWithProgress(url, onProgress)
          : await downloadPdfBytes(url);

      // Save to cache
      final file = await PdfCacheManager.savePdfToCache(url, bytes);

      return file;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a PDF is cached
  static Future<bool> isCached(String url) async {
    return await PdfCacheManager.isCached(url);
  }

  /// Clears the cache for a specific URL
  static Future<void> clearCacheForUrl(String url) async {
    await PdfCacheManager.removeCachedPdf(url);
  }

  /// Clears all cached PDFs
  static Future<void> clearAllCache() async {
    await PdfCacheManager.clearCache();
  }
}
