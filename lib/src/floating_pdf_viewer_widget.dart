import 'dart:async';

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
  final bool hasToRetry;
  final bool hasToValidateContent;

  /// Configuration options for the floating PDF viewer
  final FloatingPdfViewerOptions options;

  const FloatingPdfViewer({
    super.key,
    this.onClose,
    required this.pdfUrl,
    this.options = const FloatingPdfViewerOptions(),
    this.hasToRetry = true,
    this.hasToValidateContent = true,
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

  // Window boundary constraints
  static const double _minVisibleWidth = 100.0;
  static const double _minVisibleHeight = 50.0;

  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);
  bool _isControllerInitialized = false;
  bool _isInitializing = false;

  late final ValueNotifier<double> _leftNotifier;
  late final ValueNotifier<double> _topNotifier;
  late final ValueNotifier<double> _widthNotifier;
  late final ValueNotifier<double> _heightNotifier;
  late final ValueNotifier<double> _zoomLevelNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<bool> _hasErrorNotifier;
  late final ValueNotifier<bool> _isMinimizedNotifier;

  static const int _maxRetries = 3;
  static const int _maxValidationAttempts = 2;
  int _retryCount = 0;
  int _validationAttempts = 0;
  Timer? _continuousValidationTimer;
  Timer? _loadingTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeNotifiers();
    _initializeWebView();
  }

  void _initializeNotifiers() {
    _leftNotifier = ValueNotifier(widget.options.initialLeft ?? 0.0);
    _topNotifier = ValueNotifier(widget.options.initialTop ?? 0.0);
    _widthNotifier = ValueNotifier(widget.options.initialWidth);
    _heightNotifier = ValueNotifier(widget.options.initialHeight);
    _zoomLevelNotifier = ValueNotifier(_defaultZoomLevel);
    _isLoadingNotifier = ValueNotifier(false);
    _hasErrorNotifier = ValueNotifier(false);
    _isMinimizedNotifier = ValueNotifier(false);
  }

  void _initializeWebView() {
    _loadPdfWithRetry();
  }

  /// Loads PDF with automatic retry mechanism and error handling
  Future<void> _loadPdfWithRetry() async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final googleViewerUrl =
          'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';

      if (_isControllerInitialized) {
        try {
          await _controller.loadRequest(Uri.parse(googleViewerUrl));
        } catch (e) {
          _handleLoadingError();
        }
      } else {
        _controller
          ..enableZoom(true)
          ..setUserAgent(
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
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
          _isControllerInitialized = true;
        } catch (e) {
          try {
            await _controller.loadRequest(Uri.parse(widget.pdfUrl));
            _isControllerInitialized = true;
          } catch (_) {}
          _handleLoadingError();
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Handles loading errors with automatic retry
  void _handleLoadingError() {
    if (!mounted) return;

    _loadingTimeoutTimer?.cancel();
    _isLoadingNotifier.value = false;
    _hasErrorNotifier.value = true;

    // Only retry if we haven't exceeded both retry and validation limits
    if (_retryCount < _maxRetries &&
        _validationAttempts < _maxValidationAttempts) {
      _retryCount++;

      // Progressive delay: longer waits for subsequent retries
      final delayMilliseconds = 1000 + (_retryCount * 1000);

      Future.delayed(Duration(milliseconds: delayMilliseconds), () {
        if (mounted) {
          _loadPdfWithRetry();
        }
      });
    }
  }

  /// Manual reload method (improved)
  Future<void> _reloadPdf() async {
    if (_isInitializing) return;

    _continuousValidationTimer?.cancel();
    _loadingTimeoutTimer?.cancel();

    _retryCount = 0;
    _validationAttempts = 0;
    _isLoadingNotifier.value = true;
    _hasErrorNotifier.value = false;

    await _loadPdfWithRetry();
  }

  /// Toggle minimize/restore state
  void _toggleMinimize() {
    _isMinimizedNotifier.value = !_isMinimizedNotifier.value;
  }

  /// Handles pan update for dragging the floating window
  void _handlePanUpdate(DragUpdateDetails details, Size screenSize) {
    final minLeft = -(_widthNotifier.value - _minVisibleWidth);
    final maxLeft = screenSize.width - _minVisibleWidth;
    final minTop = -(_heightNotifier.value - _minVisibleHeight);
    final maxTop = screenSize.height - _minVisibleHeight;

    _leftNotifier.value = (_leftNotifier.value + details.delta.dx).clamp(
      minLeft,
      maxLeft,
    );
    _topNotifier.value = (_topNotifier.value + details.delta.dy).clamp(
      minTop,
      maxTop,
    );
  }

  /// Handles pan update for resizing the floating window
  void _handleResizePanUpdate(DragUpdateDetails details) {
    _widthNotifier.value = (_widthNotifier.value + details.delta.dx).clamp(
      widget.options.minWidth,
      widget.options.maxWidth,
    );
    _heightNotifier.value = (_heightNotifier.value + details.delta.dy).clamp(
      widget.options.minHeight,
      widget.options.maxHeight,
    );
  }

  void _zoomIn() {
    _zoomLevelNotifier.value = (_zoomLevelNotifier.value + _zoomStep).clamp(
      _minZoom,
      _maxZoom,
    );
    _applyZoom();
  }

  void _zoomOut() {
    _zoomLevelNotifier.value = (_zoomLevelNotifier.value - _zoomStep).clamp(
      _minZoom,
      _maxZoom,
    );
    _applyZoom();
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
      // Ignore errors
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
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isMinimizedNotifier,
      builder: (context, isMinimized, child) {
        if (isMinimized) {
          return MinimizedFloatingButton(
            headerColor: widget.options.headerColor,
            onRestore: _toggleMinimize,
          );
        }
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
                    onPanUpdate: (details) =>
                        _handlePanUpdate(details, MediaQuery.sizeOf(context)),
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onResetZoom: _resetZoom,
                    onReload: _reloadPdf,
                    onMinimize: _toggleMinimize,
                    onClose: () => widget.onClose?.call(),
                  ),
                  ResizeHandle(
                    headerColor: widget.options.headerColor,
                    onPanUpdate: _handleResizePanUpdate,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _continuousValidationTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    _leftNotifier.dispose();
    _topNotifier.dispose();
    _widthNotifier.dispose();
    _heightNotifier.dispose();
    _zoomLevelNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    _isMinimizedNotifier.dispose();
    super.dispose();
  }
}
