import 'package:flutter/material.dart';
import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';

/// Simple example of how to verify if cache is working
class SimpleCacheExample extends StatefulWidget {
  const SimpleCacheExample({super.key});

  @override
  State<SimpleCacheExample> createState() => _SimpleCacheExampleState();
}

class _SimpleCacheExampleState extends State<SimpleCacheExample> {
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  final String pdfUrl =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  /// METHOD 1: Open PDF and check cache status
  Future<void> openPdfWithCacheCheck() async {
    // Check if cached
    final isCached = await PdfDownloader.isCached(pdfUrl);

    // Measure loading time
    final stopwatch = Stopwatch()..start();

    _pdfManager.show(
      context: context,
      pdfUrl: pdfUrl,
      options: FloatingPdfViewerOptions(
        title: isCached ? 'PDF (Cached)' : 'PDF (Download)',
      ),
    );

    stopwatch.stop();
  }

  /// METHOD 2: Show cache statistics
  Future<void> showCacheStats() async {
    final stats = await PdfCacheManager.getCacheStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Cache Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Files: ${stats.fileCount}'),
            Text('Size: ${stats.totalSizeMB.toStringAsFixed(2)} MB'),
            Text('Bytes: ${stats.totalSizeBytes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// METHOD 3: Comparative test - First vs Second time
  Future<void> comparativeTest() async {
    // Clear cache first
    await PdfDownloader.clearCacheForUrl(pdfUrl);

    // FIRST TIME (download)
    var stopwatch = Stopwatch()..start();
    await PdfDownloader.getPdfFileWithCache(pdfUrl, null);
    stopwatch.stop();
    final firstTime = stopwatch.elapsedMilliseconds;

    // SECOND TIME (cache)
    stopwatch = Stopwatch()..start();
    await PdfDownloader.getPdfFileWithCache(pdfUrl, null);
    stopwatch.stop();
    final secondTime = stopwatch.elapsedMilliseconds;

    // Show result in UI
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🧪 Test Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1st time (download): ${firstTime}ms'),
              Text('2nd time (cache): ${secondTime}ms'),
              const Divider(),
              Text(
                secondTime < 100 ? '✅ CACHE WORKING!' : '⚠️ Possible issue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: secondTime < 100 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cache Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: openPdfWithCacheCheck,
              child: const Text('Open PDF'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: showCacheStats,
              child: const Text('View Statistics'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: comparativeTest,
              child: const Text('Run Comparative Test'),
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
