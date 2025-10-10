import 'package:flutter_test/flutter_test.dart';
import 'package:floating_pdf_viewer/src/pdf_downloader.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

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

  setUpAll(() {
    // Create one test directory for all tests
    testDir = Directory.systemTemp.createTempSync('pdf_cache_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(testDir.path);
  });

  tearDown(() async {
    // Clean up cache after each test
    try {
      await PdfDownloader.clearAllCache();
    } catch (e) {
      // Ignore cleanup errors
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

  group('PdfDownloader', () {
    group('downloadPdfBytes', () {
      test('should throw exception when HTTP status is not 200', () async {
        // Arrange - Using invalid URL to trigger error
        const invalidUrl = 'https://example.com/test.pdf';

        // Act & Assert
        expect(
          () => PdfDownloader.downloadPdfBytes(invalidUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange - Using invalid URL to trigger network error
        const invalidUrl = 'https://invalid-domain-12345.com/test.pdf';

        // Act & Assert
        expect(
          () => PdfDownloader.downloadPdfBytes(invalidUrl),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('downloadPdfBytesWithProgress', () {
      test('should throw exception when HTTP status is not 200', () async {
        // Arrange
        const invalidUrl = 'https://example.com/non-existent-file.pdf';

        // Act & Assert
        expect(
          () => PdfDownloader.downloadPdfBytesWithProgress(
            invalidUrl,
            (progress) {},
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPdfFileWithCache', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        const invalidUrl = 'https://example.com/nonexistent.pdf';

        // Act & Assert
        expect(
          () => PdfDownloader.getPdfFileWithCache(invalidUrl, null),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('isCached', () {
      test('should return false for non-cached URL', () async {
        // Arrange
        const testUrl = 'https://example.com/test.pdf';

        // Act
        final isCached = await PdfDownloader.isCached(testUrl);

        // Assert
        expect(isCached, isFalse);
      });
    });

    group('clearCacheForUrl', () {
      test('should handle clearing non-existent cache gracefully', () async {
        // Act & Assert - should not throw
        await PdfDownloader.clearCacheForUrl(
            'https://example.com/nonexistent.pdf');
      });
    });

    group('clearAllCache', () {
      test('should handle clearing empty cache gracefully', () async {
        // Act & Assert - should not throw
        await PdfDownloader.clearAllCache();
        await PdfDownloader.clearAllCache(); // Call twice
      });
    });
  });
}
