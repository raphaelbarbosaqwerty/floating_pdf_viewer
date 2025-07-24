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
  static const double _kDefaultZoomLevel = 1.0;

  // Zoom limits
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.25;

  late final WebViewController _controller;

  // ValueNotifiers for reactive UI updates
  late final ValueNotifier<double> _leftNotifier;
  late final ValueNotifier<double> _topNotifier;
  late final ValueNotifier<double> _widthNotifier;
  late final ValueNotifier<double> _heightNotifier;
  late final ValueNotifier<double> _zoomLevelNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;

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
    _zoomLevelNotifier = ValueNotifier(_kDefaultZoomLevel);
    _isLoadingNotifier = ValueNotifier(true);
  }

  void _initializeWebView() {
    final googleViewerUrl =
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _isLoadingNotifier.value = true;
          },
          onPageFinished: (String url) {
            _isLoadingNotifier.value = false;
          },
        ),
      )
      ..loadRequest(Uri.parse(googleViewerUrl));
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
    _zoomLevelNotifier.value = _kDefaultZoomLevel;
    try {
      await _controller.runJavaScript('''
        document.documentElement.style.transform = "";
        document.documentElement.style.transformOrigin = "";
        document.documentElement.style.width = "";
        document.documentElement.style.height = "";
      ''');
    } catch (e) {
      debugPrint('Reset zoom failed: $e');
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
    } catch (e) {
      debugPrint('JavaScript zoom failed: $e');
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
                onReload: () => _controller.reload(),
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
    super.dispose();
  }
}
