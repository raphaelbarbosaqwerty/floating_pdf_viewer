import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:floating_pdf_viewer/src/pdf_downloader.dart';

// Mock classes
class MockClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class MockStreamedResponse extends Mock implements http.StreamedResponse {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('PdfDownloader', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    group('downloadPdfBytes', () {
      test('should throw exception when HTTP status is not 200', () async {
        // Arrange
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(404);
        when(() => mockResponse.reasonPhrase).thenReturn('Not Found');

        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => PdfDownloader.downloadPdfBytes('https://example.com/test.pdf'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('HTTP 404'),
            ),
          ),
        );
      });

      test('should throw exception on network error', () async {
        // Arrange
        when(
          () => mockClient.get(any(), headers: any(named: 'headers')),
        ).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => PdfDownloader.downloadPdfBytes('https://example.com/test.pdf'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('downloadPdfBytesWithProgress', () {
      test('should download PDF with progress tracking', () async {
        // Arrange
        final progressValues = <double>[];

        // Act
        // Note: This test would require mocking StreamedResponse which is complex
        // For now, we'll test the basic flow
        final result = await PdfDownloader.downloadPdfBytesWithProgress(
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          (progress) {
            progressValues.add(progress);
          },
        );

        // Assert
        expect(result, isNotEmpty);
        // Progress should have been called at least once
        expect(progressValues, isNotEmpty);
      });

      test('should handle progress callback correctly', () async {
        // Arrange
        final progressValues = <double>[];
        const testUrl =
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

        // Act
        await PdfDownloader.downloadPdfBytesWithProgress(testUrl, (progress) {
          progressValues.add(progress);
        });

        // Assert
        expect(progressValues, isNotEmpty);
        // Progress values should be between 0 and 1
        for (final value in progressValues) {
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThanOrEqualTo(1));
        }
        // Last progress should be close to 1.0 (complete)
        if (progressValues.isNotEmpty) {
          expect(progressValues.last, closeTo(1.0, 0.1));
        }
      });

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
  });
}
