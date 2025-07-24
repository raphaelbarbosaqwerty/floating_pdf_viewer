import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Simple PDF Viewer Demo', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Simple floating PDF viewer example',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_pdfManager.isVisible) {
                  _pdfManager.hide();
                } else {
                  _pdfManager.show(
                    context: context,
                    pdfUrl:
                        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                    options: const FloatingPdfViewerOptions(
                      title: 'Sample PDF',
                      headerColor: Colors.blue,
                    ),
                  );
                }
              },
              child: Text(_pdfManager.isVisible ? 'Close PDF' : 'Open PDF'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfManager.dispose();
    super.dispose();
  }
}
