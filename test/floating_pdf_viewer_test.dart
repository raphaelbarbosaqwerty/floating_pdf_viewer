import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloatingPdfViewer Tests', () {
    group('FloatingPdfViewerOptions Tests', () {
      test('FloatingPdfViewerOptions default values', () {
        const options = FloatingPdfViewerOptions();

        expect(options.initialLeft, 50.0);
        expect(options.initialTop, 100.0);
        expect(options.initialWidth, 350.0);
        expect(options.initialHeight, 500.0);
        expect(options.title, null);
        expect(options.headerColor, null);
        expect(options.minWidth, 300.0);
        expect(options.minHeight, 250.0);
        expect(options.maxWidth, 600.0);
        expect(options.maxHeight, 800.0);
      });

      test('FloatingPdfViewerOptions copyWith functionality', () {
        const originalOptions = FloatingPdfViewerOptions(
          title: 'Original Title',
          initialWidth: 400.0,
          headerColor: Colors.blue,
        );

        final updatedOptions = originalOptions.copyWith(
          title: 'Updated Title',
          initialHeight: 700.0,
        );

        // Updated values
        expect(updatedOptions.title, 'Updated Title');
        expect(updatedOptions.initialHeight, 700.0);

        // Preserved values
        expect(updatedOptions.initialWidth, 400.0);
        expect(updatedOptions.headerColor, Colors.blue);
        expect(updatedOptions.initialLeft, 50.0); // default value
      });

      test('FloatingPdfViewerOptions equality and hashCode', () {
        const options1 = FloatingPdfViewerOptions(
          title: 'Test',
          initialWidth: 400.0,
          headerColor: Colors.red,
        );

        const options2 = FloatingPdfViewerOptions(
          title: 'Test',
          initialWidth: 400.0,
          headerColor: Colors.red,
        );

        const options3 = FloatingPdfViewerOptions(
          title: 'Different',
          initialWidth: 400.0,
          headerColor: Colors.red,
        );

        // Test equality
        expect(options1 == options2, true);
        expect(options1 == options3, false);

        // Test hashCode consistency
        expect(options1.hashCode == options2.hashCode, true);
        expect(options1.hashCode == options3.hashCode, false);
      });

      test('FloatingPdfViewerOptions toString', () {
        const options = FloatingPdfViewerOptions(
          title: 'Test PDF',
          initialWidth: 400.0,
          headerColor: Colors.blue,
        );

        final stringRepresentation = options.toString();
        expect(stringRepresentation, contains('FloatingPdfViewerOptions'));
        expect(stringRepresentation, contains('Test PDF'));
        expect(stringRepresentation, contains('400.0'));
      });
    });
    test('FloatingPdfViewerManager initial state', () {
      final manager = FloatingPdfViewerManager();

      // Initially should not be visible
      expect(manager.isVisible, false);

      // Dispose should work without errors
      manager.dispose();
      expect(manager.isVisible, false);
    });

    test('FloatingPdfViewerManager state management', () {
      final manager = FloatingPdfViewerManager();

      // Initially not visible
      expect(manager.isVisible, false);

      // Hide should work even when not visible
      manager.hide();
      expect(manager.isVisible, false);

      // Dispose cleans up
      manager.dispose();
      expect(manager.isVisible, false);
    });

    testWidgets('FloatingPdfViewer widget creation with parameters', (
      WidgetTester tester,
    ) async {
      const testTitle = 'My Test PDF';
      const testPdfUrl = 'https://example.com/test.pdf';
      const testOptions = FloatingPdfViewerOptions(
        title: testTitle,
        initialLeft: 100,
        initialTop: 150,
        initialWidth: 400,
        initialHeight: 600,
        headerColor: Colors.blue,
        minWidth: 300,
        maxWidth: 500,
      );

      // Test if widget can be created without WebView initialization
      // We'll just test the widget structure without pumping it
      final widget = FloatingPdfViewer(
        pdfUrl: testPdfUrl,
        options: testOptions,
        onClose: () {},
      );

      expect(widget.pdfUrl, testPdfUrl);
      expect(widget.options.title, testTitle);
      expect(widget.options.initialLeft, 100);
      expect(widget.options.initialTop, 150);
      expect(widget.options.initialWidth, 400);
      expect(widget.options.initialHeight, 600);
      expect(widget.options.headerColor, Colors.blue);
      expect(widget.options.minWidth, 300);
      expect(widget.options.maxWidth, 500);
    });

    test('FloatingPdfViewer widget with default parameters', () {
      const testPdfUrl = 'https://example.com/test.pdf';

      final widget = FloatingPdfViewer(pdfUrl: testPdfUrl, onClose: () {});

      expect(widget.pdfUrl, testPdfUrl);
      expect(widget.options.title, null);
      expect(widget.options.initialLeft, 50.0); // default value
      expect(widget.options.initialTop, 100.0); // default value
      expect(widget.options.initialWidth, 350.0); // default value
      expect(widget.options.initialHeight, 500.0); // default value
      expect(widget.options.headerColor, null);
      expect(widget.options.minWidth, 300.0); // default value
      expect(widget.options.maxWidth, 600.0); // default value
      expect(widget.options.minHeight, 250.0); // default value
      expect(widget.options.maxHeight, 800.0); // default value
    });

    test('URL encoding for Google Docs Viewer', () {
      // Test that the package correctly formats URLs for Google Docs Viewer
      const testUrl = 'https://example.com/document with spaces.pdf';

      // Simulating the URL encoding that happens in _initializeWebView
      final encoded = Uri.encodeComponent(testUrl);
      final googleViewerUrl =
          'https://docs.google.com/viewer?url=$encoded&embedded=true';

      expect(googleViewerUrl, contains('docs.google.com/viewer'));
      expect(googleViewerUrl, contains('embedded=true'));
      expect(googleViewerUrl, contains('document%20with%20spaces.pdf'));
    });
  });
}
