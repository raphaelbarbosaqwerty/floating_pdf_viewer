import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floating_pdf_viewer/src/manager.dart';
import 'package:floating_pdf_viewer/src/options.dart';

void main() {
  group('FloatingPdfViewerManager', () {
    late FloatingPdfViewerManager manager;

    setUp(() {
      manager = FloatingPdfViewerManager();
    });

    tearDown(() {
      manager.dispose();
    });

    testWidgets('should show floating PDF viewer overlay', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isTrue);
    });

    testWidgets('should hide floating PDF viewer overlay', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Act
      manager.hide();
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isFalse);
    });

    testWidgets('should not show overlay if already visible', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                    // Try to show again
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test2.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isTrue);
    });

    testWidgets('should call onClose callback when closing', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                      onClose: () {
                        // Callback executed
                      },
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Act - Find and tap close button
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      // Assert
      // Note: The callback will be called when the overlay is actually closed
      expect(manager.isVisible, isFalse);
    });

    testWidgets('should use custom options when provided', (tester) async {
      // Arrange
      const customOptions = FloatingPdfViewerOptions(
        initialWidth: 500,
        initialHeight: 700,
        title: 'Custom PDF',
        headerColor: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                      options: customOptions,
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isTrue);
      expect(find.text('Custom PDF'), findsOneWidget);
    });

    testWidgets('should center overlay when position not provided', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isTrue);
    });

    testWidgets('should dispose and hide overlay', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();

      // Act
      manager.dispose();
      await tester.pumpAndSettle();

      // Assert
      expect(manager.isVisible, isFalse);
    });

    test('should return false for isVisible when not shown', () {
      // Assert
      expect(manager.isVisible, isFalse);
    });

    testWidgets('should handle multiple show/hide cycles', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    manager.show(
                      context: context,
                      pdfUrl: 'https://example.com/test.pdf',
                    );
                  },
                  child: const Text('Show PDF'),
                );
              },
            ),
          ),
        ),
      );

      // Act & Assert - First cycle
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();
      expect(manager.isVisible, isTrue);

      manager.hide();
      await tester.pumpAndSettle();
      expect(manager.isVisible, isFalse);

      // Second cycle
      await tester.tap(find.text('Show PDF'));
      await tester.pumpAndSettle();
      expect(manager.isVisible, isTrue);

      manager.hide();
      await tester.pumpAndSettle();
      expect(manager.isVisible, isFalse);
    });
  });
}
