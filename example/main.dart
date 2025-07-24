import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Floating PDF Viewer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Example 1: Using FloatingPdfViewerManager (recommended)
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  // Example 2: Using multiple managers
  final FloatingPdfViewerManager _pdfManager2 = FloatingPdfViewerManager();

  // Example 3: Manual control with overlay
  OverlayEntry? _overlayEntry;
  bool _isManualOverlayVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Floating PDF Viewer Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'floating_pdf_viewer Package Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Example 1: Basic manager
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Example 1: FloatingPdfViewerManager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_pdfManager.isVisible) {
                          _pdfManager.hide();
                        } else {
                          _pdfManager.show(
                            context: context,
                            pdfUrl:
                                '***REMOVED***',
                            options: const FloatingPdfViewerOptions(
                              title: 'Sample Document',
                              headerColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        _pdfManager.isVisible
                            ? Icons.close
                            : Icons.picture_as_pdf,
                      ),
                      label: Text(
                        _pdfManager.isVisible ? 'Close PDF' : 'Open PDF',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example 2: Manager with custom settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Example 2: Custom PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_pdfManager2.isVisible) {
                          _pdfManager2.hide();
                        } else {
                          _pdfManager2.show(
                            context: context,
                            pdfUrl:
                                '***REMOVED***',
                            options: const FloatingPdfViewerOptions(
                              title: 'Custom PDF',
                              headerColor: Colors.green,
                              initialLeft: 200,
                              initialTop: 150,
                              initialWidth: 400,
                              initialHeight: 600,
                              minWidth: 350,
                              maxWidth: 500,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        _pdfManager2.isVisible ? Icons.close : Icons.settings,
                      ),
                      label: Text(
                        _pdfManager2.isVisible ? 'Close Custom' : 'Custom PDF',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example 3: Manual control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Example 3: Manual Overlay Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isManualOverlayVisible
                          ? _hideManualOverlay
                          : _showManualOverlay,
                      icon: Icon(
                        _isManualOverlayVisible ? Icons.close : Icons.code,
                      ),
                      label: Text(
                        _isManualOverlayVisible
                            ? 'Close Manual'
                            : 'Manual Overlay',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example 4: Demonstrating copyWith
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Example 4: Using copyWith',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Base options
                        const baseOptions = FloatingPdfViewerOptions(
                          title: 'Base PDF',
                          headerColor: Colors.purple,
                          initialWidth: 300,
                          initialHeight: 400,
                        );

                        // Modified options using copyWith
                        final customOptions = baseOptions.copyWith(
                          title: 'Modified PDF',
                          initialLeft: 250,
                          initialTop: 200,
                        );

                        _pdfManager.show(
                          context: context,
                          pdfUrl:
                              '***REMOVED***',
                          options: customOptions,
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('CopyWith Example'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Use cases:\n'
              '• Document viewing\n'
              '• Contracts and forms\n'
              '• Manuals and guides\n'
              '• Reports\n\n'
              'New features:\n'
              '• Cleaner API with options class\n'
              '• Easy configuration with copyWith\n'
              '• Better maintainability',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Methods for manual overlay control
  void _showManualOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingPdfViewer(
        pdfUrl:
            '***REMOVED***',
        onClose: _hideManualOverlay,
        options: const FloatingPdfViewerOptions(
          title: 'Manual Overlay',
          headerColor: Colors.orange,
          initialLeft: 100,
          initialTop: 100,
          initialWidth: 350,
          initialHeight: 500,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isManualOverlayVisible = true;
    });
  }

  void _hideManualOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isManualOverlayVisible = false;
    });
  }

  @override
  void dispose() {
    // Important: always dispose managers
    _pdfManager.dispose();
    _pdfManager2.dispose();
    _hideManualOverlay();
    super.dispose();
  }
}
