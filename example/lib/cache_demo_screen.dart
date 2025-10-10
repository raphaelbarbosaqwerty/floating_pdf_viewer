import 'package:flutter/material.dart';
import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';

/// Cache system demonstration screen
class CacheDemoScreen extends StatefulWidget {
  const CacheDemoScreen({super.key});

  @override
  State<CacheDemoScreen> createState() => _CacheDemoScreenState();
}

class _CacheDemoScreenState extends State<CacheDemoScreen> {
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  CacheStats? _cacheStats;
  bool _isLoadingStats = false;

  // Test URL (small W3C PDF)
  final String _testPdfUrl =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  /// Loads cache statistics
  Future<void> _loadCacheStats() async {
    setState(() => _isLoadingStats = true);

    final stats = await PdfCacheManager.getCacheStats();

    if (mounted) {
      setState(() {
        _cacheStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  /// Checks if a specific PDF is cached
  Future<void> _checkIfCached() async {
    final isCached = await PdfDownloader.isCached(_testPdfUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCached
                ? '✅ PDF is CACHED! Loading will be instant.'
                : '❌ PDF is NOT cached. It will be downloaded.',
          ),
          backgroundColor: isCached ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Opens PDF and shows loading time
  Future<void> _openPdfWithTiming() async {
    final stopwatch = Stopwatch()..start();

    // Shows loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Loading PDF...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    _pdfManager.show(
      context: context,
      pdfUrl: _testPdfUrl,
      options: FloatingPdfViewerOptions(
        title: 'Demo Cache - ${stopwatch.elapsedMilliseconds}ms',
        headerColor: Colors.deepPurple,
      ),
      onClose: () async {
        stopwatch.stop();
        await _loadCacheStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⏱️ Loading time: ${stopwatch.elapsedMilliseconds}ms',
              ),
              backgroundColor: stopwatch.elapsedMilliseconds < 500
                  ? Colors.green
                  : Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );

    // Wait a bit for PDF to load
    await Future.delayed(const Duration(milliseconds: 100));
    stopwatch.stop();

    // Reload stats after opening
    await _loadCacheStats();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stopwatch.elapsedMilliseconds < 100
                ? '🚀 Loaded from CACHE in ${stopwatch.elapsedMilliseconds}ms!'
                : '📥 Downloaded in ${stopwatch.elapsedMilliseconds}ms (now cached)',
          ),
          backgroundColor: stopwatch.elapsedMilliseconds < 100
              ? Colors.green
              : Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Clears cache for a specific PDF
  Future<void> _clearPdfCache() async {
    await PdfDownloader.clearCacheForUrl(_testPdfUrl);
    await _loadCacheStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ PDF cache removed!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Clears all cache
  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Do you want to clear ALL PDF cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PdfDownloader.clearAllCache();
      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ All cache has been cleared!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCacheStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cache Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Cache Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadCacheStats,
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_isLoadingStats)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      _buildStatRow(
                        '📁 Cached files:',
                        '${_cacheStats?.fileCount ?? 0}',
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '💾 Total size:',
                        '${_cacheStats?.totalSizeMB.toStringAsFixed(2) ?? '0.00'} MB',
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        '📊 Bytes:',
                        '${_cacheStats?.totalSizeBytes ?? 0}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to test the cache:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '1.',
                      'Open the PDF for the FIRST time (it will be downloaded)',
                    ),
                    _buildInstructionStep(
                      '2.',
                      'Close the PDF and watch the statistics update',
                    ),
                    _buildInstructionStep(
                      '3.',
                      'Open the PDF for the SECOND time (instant loading!)',
                    ),
                    _buildInstructionStep(
                      '4.',
                      'Compare loading times in notifications',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Main actions
            const Text(
              'Actions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _checkIfCached,
              icon: const Icon(Icons.search),
              label: const Text('Check if PDF is cached'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _openPdfWithTiming,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Open PDF (with timing)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Cache management actions
            const Text(
              'Manage Cache:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _clearPdfCache,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear this PDF\'s cache'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _clearAllCache,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear ALL cache'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '💡 First open ~500ms+, second ~50ms!',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfManager.dispose();
    super.dispose();
  }
}
