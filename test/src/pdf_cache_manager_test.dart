import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:floating_pdf_viewer/src/pdf_cache_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testPath;

  MockPathProviderPlatform(this.testPath);

  @override
  Future<String?> getTemporaryPath() async {
    return testPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  late MockPathProviderPlatform mockPathProvider;

  setUpAll(() {
    // Create one test directory for all tests
    testDir = Directory.systemTemp.createTempSync('pdf_cache_test');
  });

  setUp(() {
    mockPathProvider = MockPathProviderPlatform(testDir.path);
    PathProviderPlatform.instance = mockPathProvider;
  });

  tearDown(() async {
    // Clean up test cache directory after each test
    try {
      await PdfCacheManager.clearCache();
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  tearDownAll(() {
    // Remove the test directory after all tests
    try {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('PdfCacheManager', () {
    const testUrl1 = 'https://example.com/test1.pdf';
    const testUrl2 = 'https://example.com/test2.pdf';
    final testPdfBytes1 = List<int>.generate(1000, (i) => i % 256);
    final testPdfBytes2 = List<int>.generate(2000, (i) => (i * 2) % 256);

    group('savePdfToCache', () {
      test('should save PDF bytes to cache', () async {
        // Act
        final file =
            await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Assert
        expect(await file.exists(), isTrue);
        expect(await file.length(), equals(testPdfBytes1.length));
        expect(await file.readAsBytes(), equals(testPdfBytes1));
      });

      test('should generate unique cache keys for different URLs', () async {
        // Act
        final file1 =
            await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        final file2 =
            await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);

        // Assert
        expect(file1.path, isNot(equals(file2.path)));
        expect(await file1.exists(), isTrue);
        expect(await file2.exists(), isTrue);
      });

      test('should overwrite existing cache file for same URL', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Act - save different content with same URL
        final file =
            await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes2);

        // Assert
        expect(await file.exists(), isTrue);
        expect(await file.length(), equals(testPdfBytes2.length));
        expect(await file.readAsBytes(), equals(testPdfBytes2));
      });
    });

    group('isCached', () {
      test('should return true when PDF is cached', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Act
        final isCached = await PdfCacheManager.isCached(testUrl1);

        // Assert
        expect(isCached, isTrue);
      });

      test('should return false when PDF is not cached', () async {
        // Act
        final isCached = await PdfCacheManager.isCached(testUrl1);

        // Assert
        expect(isCached, isFalse);
      });

      test('should return false after cache is cleared', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        expect(await PdfCacheManager.isCached(testUrl1), isTrue);

        // Act
        await PdfCacheManager.clearCache();

        // Assert
        expect(await PdfCacheManager.isCached(testUrl1), isFalse);
      });
    });

    group('getCachedFile', () {
      test('should return cached file when it exists', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Act
        final file = await PdfCacheManager.getCachedFile(testUrl1);

        // Assert
        expect(file, isNotNull);
        expect(await file!.exists(), isTrue);
        expect(await file.readAsBytes(), equals(testPdfBytes1));
      });

      test('should return null when file is not cached', () async {
        // Act
        final file = await PdfCacheManager.getCachedFile(testUrl1);

        // Assert
        expect(file, isNull);
      });

      test('should return correct file for multiple cached PDFs', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);

        // Act
        final file1 = await PdfCacheManager.getCachedFile(testUrl1);
        final file2 = await PdfCacheManager.getCachedFile(testUrl2);

        // Assert
        expect(file1, isNotNull);
        expect(file2, isNotNull);
        expect(await file1!.readAsBytes(), equals(testPdfBytes1));
        expect(await file2!.readAsBytes(), equals(testPdfBytes2));
      });
    });

    group('removeCachedPdf', () {
      test('should remove specific cached PDF', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);
        expect(await PdfCacheManager.isCached(testUrl1), isTrue);
        expect(await PdfCacheManager.isCached(testUrl2), isTrue);

        // Act
        await PdfCacheManager.removeCachedPdf(testUrl1);

        // Assert
        expect(await PdfCacheManager.isCached(testUrl1), isFalse);
        expect(await PdfCacheManager.isCached(testUrl2), isTrue);
      });

      test('should handle removing non-existent cache gracefully', () async {
        // Act & Assert - should not throw
        await PdfCacheManager.removeCachedPdf(
            'https://example.com/nonexistent.pdf');
      });
    });

    group('clearCache', () {
      test('should remove all cached PDFs', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);
        expect(await PdfCacheManager.isCached(testUrl1), isTrue);
        expect(await PdfCacheManager.isCached(testUrl2), isTrue);

        // Act
        await PdfCacheManager.clearCache();

        // Assert
        expect(await PdfCacheManager.isCached(testUrl1), isFalse);
        expect(await PdfCacheManager.isCached(testUrl2), isFalse);
      });

      test('should handle clearing empty cache gracefully', () async {
        // Act & Assert - should not throw
        await PdfCacheManager.clearCache();
        await PdfCacheManager.clearCache(); // Call twice
      });
    });

    group('getCacheSize', () {
      test('should return 0 for empty cache', () async {
        // Act
        final size = await PdfCacheManager.getCacheSize();

        // Assert
        expect(size, equals(0));
      });

      test('should return correct size for cached PDFs', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);

        // Act
        final size = await PdfCacheManager.getCacheSize();

        // Assert
        final expectedSize = testPdfBytes1.length + testPdfBytes2.length;
        expect(size, equals(expectedSize));
      });

      test('should update size after clearing cache', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        expect(await PdfCacheManager.getCacheSize(), greaterThan(0));

        // Act
        await PdfCacheManager.clearCache();

        // Assert
        expect(await PdfCacheManager.getCacheSize(), equals(0));
      });
    });

    group('getCacheFileCount', () {
      test('should return 0 for empty cache', () async {
        // Act
        final count = await PdfCacheManager.getCacheFileCount();

        // Assert
        expect(count, equals(0));
      });

      test('should return correct count for cached PDFs', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);

        // Act
        final count = await PdfCacheManager.getCacheFileCount();

        // Assert
        expect(count, equals(2));
      });

      test('should update count after removing PDF', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);
        expect(await PdfCacheManager.getCacheFileCount(), equals(2));

        // Act
        await PdfCacheManager.removeCachedPdf(testUrl1);

        // Assert
        expect(await PdfCacheManager.getCacheFileCount(), equals(1));
      });
    });

    group('getCacheStats', () {
      test('should return empty stats for empty cache', () async {
        // Act
        final stats = await PdfCacheManager.getCacheStats();

        // Assert
        expect(stats.fileCount, equals(0));
        expect(stats.totalSizeBytes, equals(0));
        expect(stats.totalSizeMB, equals(0.0));
      });

      test('should return correct stats for cached PDFs', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.savePdfToCache(testUrl2, testPdfBytes2);

        // Act
        final stats = await PdfCacheManager.getCacheStats();

        // Assert
        expect(stats.fileCount, equals(2));
        expect(stats.totalSizeBytes,
            equals(testPdfBytes1.length + testPdfBytes2.length));
        expect(
            stats.totalSizeMB,
            closeTo(
                (testPdfBytes1.length + testPdfBytes2.length) / (1024 * 1024),
                0.01));
      });

      test('should have working toString method', () async {
        // Arrange
        await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Act
        final stats = await PdfCacheManager.getCacheStats();
        final str = stats.toString();

        // Assert
        expect(str, contains('CacheStats'));
        expect(str, contains('files: 1'));
        expect(str, contains('MB'));
      });
    });

    group('cache key generation', () {
      test('should generate consistent keys for same URL', () async {
        // Arrange & Act
        final file1 =
            await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);
        await PdfCacheManager.removeCachedPdf(testUrl1);
        final file2 =
            await PdfCacheManager.savePdfToCache(testUrl1, testPdfBytes1);

        // Assert
        expect(file1.path, equals(file2.path));
      });

      test('should handle URLs with query parameters', () async {
        // Arrange
        const urlWithParams = 'https://example.com/test.pdf?param=value&id=123';

        // Act
        final file =
            await PdfCacheManager.savePdfToCache(urlWithParams, testPdfBytes1);

        // Assert
        expect(await file.exists(), isTrue);
        expect(await PdfCacheManager.isCached(urlWithParams), isTrue);
      });

      test('should handle URLs with special characters', () async {
        // Arrange
        const specialUrl = 'https://example.com/test file (1).pdf';

        // Act
        final file =
            await PdfCacheManager.savePdfToCache(specialUrl, testPdfBytes1);

        // Assert
        expect(await file.exists(), isTrue);
        expect(await PdfCacheManager.isCached(specialUrl), isTrue);
      });
    });
  });
}
