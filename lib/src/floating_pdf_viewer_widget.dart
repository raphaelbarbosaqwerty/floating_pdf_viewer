import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'internal_widgets.dart';
import 'options.dart';

/// A floating PDF viewer widget that can be displayed as an overlay.
///
/// This widget creates a draggable, resizable floating window with a WebView
/// that displays PDF documents using Google Docs Viewer.
class FloatingPdfViewer extends StatefulWidget {
  /// Callback function called when the floating viewer is closed
  final VoidCallback? onClose;

  /// URL of the PDF to display
  final String pdfUrl;

  /// Configuration options for the floating PDF viewer
  final FloatingPdfViewerOptions options;

  const FloatingPdfViewer({
    super.key,
    this.onClose,
    required this.pdfUrl,
    this.options = const FloatingPdfViewerOptions(),
  });

  @override
  State<FloatingPdfViewer> createState() => _FloatingPdfViewerState();
}

class _FloatingPdfViewerState extends State<FloatingPdfViewer> {
  // UI Constants
  static const double _defaultZoomLevel = 1.0;

  // Zoom limits
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.25;

  late WebViewController _controller;
  bool _isControllerInitialized = false;

  late final ValueNotifier<double> _leftNotifier;
  late final ValueNotifier<double> _topNotifier;
  late final ValueNotifier<double> _widthNotifier;
  late final ValueNotifier<double> _heightNotifier;
  late final ValueNotifier<double> _zoomLevelNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<bool> _hasErrorNotifier;

  // Loading timeout and retry
  static const Duration _loadingTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  int _retryCount = 0;
  bool _hasValidatedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifiers();
    _initializeWebView();
  }

  void _initializeNotifiers() {
    _leftNotifier = ValueNotifier(widget.options.initialLeft);
    _topNotifier = ValueNotifier(widget.options.initialTop);
    _widthNotifier = ValueNotifier(widget.options.initialWidth);
    _heightNotifier = ValueNotifier(widget.options.initialHeight);
    _zoomLevelNotifier = ValueNotifier(_defaultZoomLevel);
    _isLoadingNotifier = ValueNotifier(true);
    _hasErrorNotifier = ValueNotifier(false);
  }

  void _initializeWebView() {
    _loadPdfWithRetry();
  }

  /// Loads PDF with automatic retry mechanism and error handling
  Future<void> _loadPdfWithRetry() async {
    final googleViewerUrl =
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';

    // Only initialize controller once, reuse for retries
    if (_isControllerInitialized) {
      // Controller exists, just reload the URL

      try {
        await _controller.loadRequest(Uri.parse(googleViewerUrl));
      } catch (e) {
        _handleLoadingError();
      }
    } else {
      // Controller not initialized, create new one

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..enableZoom(true)
        ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        ) // Better compatibility
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              _isLoadingNotifier.value = true;
              _hasErrorNotifier.value = false;
              _startLoadingTimeout();
            },
            onPageFinished: (String url) {
              _isLoadingNotifier.value = false;
              _hasErrorNotifier.value = false;

              // Only validate content if we haven't successfully validated before
              if (!_hasValidatedSuccessfully) {
                _validatePageContent(); // Check if content actually loaded
              } else {
                // Already validated successfully, just reset retry count
                _retryCount = 0;
              }
            },
            onWebResourceError: (WebResourceError error) {
              _handleLoadingError();
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        );

      try {
        await _controller.loadRequest(Uri.parse(googleViewerUrl));
        _isControllerInitialized =
            true; // Mark as initialized after successful setup
      } catch (e) {
        _handleLoadingError();
      }
    }
  }

  /// Starts a timeout to detect failed loads
  void _startLoadingTimeout() {
    Future.delayed(_loadingTimeout, () {
      if (mounted && _isLoadingNotifier.value) {
        _handleLoadingError();
      }
    });
  }

  /// Validates if the page content actually loaded correctly
  Future<void> _validatePageContent() async {
    try {
      // Wait a bit for content to render
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      // Simple validation - try to get page title or URL
      final currentUrl = await _controller.currentUrl();

      if (currentUrl != null && currentUrl.contains('docs.google.com')) {
        _hasValidatedSuccessfully = true;
        _retryCount = 0;
      } else {
        _handleLoadingError();
      }
    } catch (e) {
      // If validation fails, assume success to avoid infinite retries
      _hasValidatedSuccessfully = true;
      _retryCount = 0;
    }
  }

  /// Handles loading errors with automatic retry
  void _handleLoadingError() {
    if (!mounted) return;

    _isLoadingNotifier.value = false;
    _hasErrorNotifier.value = true;

    if (_retryCount < _maxRetries) {
      _retryCount++;

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadPdfWithRetry();
        }
      });
    } else {
      // Keep error state - user can manually retry via reload button
    }
  }

  /// Manual reload method (improved)
  Future<void> _reloadPdf() async {
    _retryCount = 0; // Reset retry count for manual reload
    _hasValidatedSuccessfully = false; // Reset validation flag
    _isLoadingNotifier.value = true;
    _hasErrorNotifier.value = false;

    await _loadPdfWithRetry();
  }

  void _zoomIn() {
    if (_zoomLevelNotifier.value < _maxZoom) {
      _zoomLevelNotifier.value = (_zoomLevelNotifier.value + _zoomStep).clamp(
        _minZoom,
        _maxZoom,
      );
      _applyZoom();
    }
  }

  void _zoomOut() {
    if (_zoomLevelNotifier.value > _minZoom) {
      _zoomLevelNotifier.value = (_zoomLevelNotifier.value - _zoomStep).clamp(
        _minZoom,
        _maxZoom,
      );
      _applyZoom();
    }
  }

  void _resetZoom() async {
    _zoomLevelNotifier.value = _defaultZoomLevel;
    try {
      await _controller.runJavaScript('''
        document.documentElement.style.transform = "";
        document.documentElement.style.transformOrigin = "";
        document.documentElement.style.width = "";
        document.documentElement.style.height = "";
      ''');
    } catch (_) {
      // Ignore zoom reset errors
    }
  }

  void _applyZoom() async {
    try {
      await _controller.runJavaScript('''
        document.documentElement.style.transform = "scale(${_zoomLevelNotifier.value})";
        document.documentElement.style.transformOrigin = "top left";
        document.documentElement.style.width = "${100 / _zoomLevelNotifier.value}%";
        document.documentElement.style.height = "${100 / _zoomLevelNotifier.value}%";
      ''');
    } catch (_) {
      // Ignore zoom application errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_leftNotifier, _topNotifier]),
      builder: (context, child) {
        return Positioned(
          left: _leftNotifier.value,
          top: _topNotifier.value,
          child: Stack(
            children: [
              FloatingContainer(
                widthNotifier: _widthNotifier,
                heightNotifier: _heightNotifier,
                title: widget.options.title,
                headerColor: widget.options.headerColor,
                zoomLevelNotifier: _zoomLevelNotifier,
                controller: _controller,
                isLoadingNotifier: _isLoadingNotifier,
                hasErrorNotifier: _hasErrorNotifier,
                onPanUpdate: (details) {
                  final screenSize = MediaQuery.of(context).size;

                  // Allow widget to move outside screen but keep minimum visible area
                  // This prevents hiding all control buttons while maintaining original behavior
                  const minVisibleWidth = 100.0; // Enough to show close button
                  const minVisibleHeight = 50.0; // Height of header bar

                  final minLeft = -((_widthNotifier.value - minVisibleWidth));
                  final maxLeft = screenSize.width - minVisibleWidth;
                  final minTop = -((_heightNotifier.value - minVisibleHeight));
                  final maxTop = screenSize.height - minVisibleHeight;

                  _leftNotifier.value = (_leftNotifier.value + details.delta.dx)
                      .clamp(minLeft, maxLeft);
                  _topNotifier.value = (_topNotifier.value + details.delta.dy)
                      .clamp(minTop, maxTop);
                },
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onResetZoom: _resetZoom,
                onReload: _reloadPdf,
                onClose: () => widget.onClose?.call(),
              ),
              // Resize handle
              ResizeHandle(
                headerColor: widget.options.headerColor,
                onPanUpdate: (details) {
                  _widthNotifier.value =
                      (_widthNotifier.value + details.delta.dx).clamp(
                        widget.options.minWidth,
                        widget.options.maxWidth,
                      );
                  _heightNotifier.value =
                      (_heightNotifier.value + details.delta.dy).clamp(
                        widget.options.minHeight,
                        widget.options.maxHeight,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _leftNotifier.dispose();
    _topNotifier.dispose();
    _widthNotifier.dispose();
    _heightNotifier.dispose();
    _zoomLevelNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    super.dispose();
  }
}
