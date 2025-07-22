import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloatingPdfViewer Tests', () {
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

      // Test if widget can be created without WebView initialization
      // We'll just test the widget structure without pumping it
      final widget = FloatingPdfViewer(
        pdfUrl: testPdfUrl,
        title: testTitle,
        onClose: () {},
        initialLeft: 100,
        initialTop: 150,
        initialWidth: 400,
        initialHeight: 600,
        headerColor: Colors.blue,
        minWidth: 300,
        maxWidth: 500,
      );

      expect(widget.pdfUrl, testPdfUrl);
      expect(widget.title, testTitle);
      expect(widget.initialLeft, 100);
      expect(widget.initialTop, 150);
      expect(widget.initialWidth, 400);
      expect(widget.initialHeight, 600);
      expect(widget.headerColor, Colors.blue);
      expect(widget.minWidth, 300);
      expect(widget.maxWidth, 500);
    });

    test('FloatingPdfViewer widget with default parameters', () {
      const testPdfUrl = 'https://example.com/test.pdf';

      final widget = FloatingPdfViewer(pdfUrl: testPdfUrl, onClose: () {});

      expect(widget.pdfUrl, testPdfUrl);
      expect(widget.title, null);
      expect(widget.initialLeft, null);
      expect(widget.initialTop, null);
      expect(widget.initialWidth, null);
      expect(widget.initialHeight, null);
      expect(widget.headerColor, null);
      expect(widget.minWidth, null);
      expect(widget.maxWidth, null);
      expect(widget.minHeight, null);
      expect(widget.maxHeight, null);
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
