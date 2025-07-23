library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A floating PDF viewer widget that can be displayed as an overlay.
///
/// This widget creates a draggable, resizable floating window with a WebView
/// that displays PDF documents using Google Docs Viewer.
class FloatingPdfViewer extends StatefulWidget {
  /// Callback function called when the floating viewer is closed
  final VoidCallback? onClose;

  /// URL of the PDF to display
  final String pdfUrl;

  /// Initial position of the floating viewer (left offset)
  final double? initialLeft;

  /// Initial position of the floating viewer (top offset)
  final double? initialTop;

  /// Initial width of the floating viewer
  final double? initialWidth;

  /// Initial height of the floating viewer
  final double? initialHeight;

  /// Title displayed in the header bar
  final String? title;

  /// Color of the header bar
  final Color? headerColor;

  /// Minimum width for resizing
  final double? minWidth;

  /// Minimum height for resizing
  final double? minHeight;

  /// Maximum width for resizing
  final double? maxWidth;

  /// Maximum height for resizing
  final double? maxHeight;

  const FloatingPdfViewer({
    super.key,
    this.onClose,
    required this.pdfUrl,
    this.initialLeft,
    this.initialTop,
    this.initialWidth,
    this.initialHeight,
    this.title,
    this.headerColor,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  State<FloatingPdfViewer> createState() => _FloatingPdfViewerState();
}

class _FloatingPdfViewerState extends State<FloatingPdfViewer> {
  // UI Constants
  static const double _kBorderRadius = 12.0;
  static const double _kElevation = 8.0;
  static const double _kDefaultInitialLeft = 50.0;
  static const double _kDefaultInitialTop = 100.0;
  static const double _kDefaultZoomLevel = 1.0;

  // Default size values
  static const double _defaultWidth = 350.0;
  static const double _defaultHeight = 500.0;
  static const double _defaultMinWidth = 300.0;
  static const double _defaultMinHeight = 250.0;
  static const double _defaultMaxWidth = 600.0;
  static const double _defaultMaxHeight = 800.0;

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
    _leftNotifier = ValueNotifier(widget.initialLeft ?? _kDefaultInitialLeft);
    _topNotifier = ValueNotifier(widget.initialTop ?? _kDefaultInitialTop);
    _widthNotifier = ValueNotifier(widget.initialWidth ?? _defaultWidth);
    _heightNotifier = ValueNotifier(widget.initialHeight ?? _defaultHeight);
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
              _buildWebViewContainer(),
              // Resize handle
              _ResizeHandle(
                headerColor: widget.headerColor,
                onPanUpdate: (details) {
                  _widthNotifier.value =
                      (_widthNotifier.value + details.delta.dx).clamp(
                        widget.minWidth ?? _defaultMinWidth,
                        widget.maxWidth ?? _defaultMaxWidth,
                      );
                  _heightNotifier.value =
                      (_heightNotifier.value + details.delta.dy).clamp(
                        widget.minHeight ?? _defaultMinHeight,
                        widget.maxHeight ?? _defaultMaxHeight,
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebViewContainer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_widthNotifier, _heightNotifier]),
      builder: (context, child) {
        return Material(
          elevation: _kElevation,
          borderRadius: BorderRadius.circular(_kBorderRadius),
          child: Container(
            width: _widthNotifier.value,
            height: _heightNotifier.value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kBorderRadius),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header bar (draggable)
                _HeaderBar(
                  title: widget.title,
                  headerColor: widget.headerColor,
                  zoomLevelNotifier: _zoomLevelNotifier,
                  onPanUpdate: (details) {
                    final screenSize = MediaQuery.of(context).size;

                    // Allow widget to move outside screen but keep minimum visible area
                    // This prevents hiding all control buttons while maintaining original behavior
                    const minVisibleWidth =
                        100.0; // Enough to show close button
                    const minVisibleHeight = 50.0; // Height of header bar

                    final minLeft = -((_widthNotifier.value - minVisibleWidth));
                    final maxLeft = screenSize.width - minVisibleWidth;
                    final minTop =
                        -((_heightNotifier.value - minVisibleHeight));
                    final maxTop = screenSize.height - minVisibleHeight;

                    _leftNotifier.value =
                        (_leftNotifier.value + details.delta.dx).clamp(
                          minLeft,
                          maxLeft,
                        );
                    _topNotifier.value = (_topNotifier.value + details.delta.dy)
                        .clamp(minTop, maxTop);
                  },
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onResetZoom: _resetZoom,
                  onReload: () => _controller.reload(),
                  onClose: () => widget.onClose?.call(),
                ),
                // WebView content
                _WebViewContent(
                  controller: _controller,
                  isLoadingNotifier: _isLoadingNotifier,
                ),
              ],
            ),
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

/// Header bar widget for the floating PDF viewer
class _HeaderBar extends StatelessWidget {
  // UI Constants
  static const double _kBorderRadius = 12.0;
  static const double _kHeaderHeight = 50.0;
  static const double _kHorizontalPadding = 12.0;
  static const double _kSmallHorizontalPadding = 8.0;

  final String? title;
  final Color? headerColor;
  final ValueNotifier<double> zoomLevelNotifier;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onReload;
  final VoidCallback onClose;

  const _HeaderBar({
    required this.title,
    required this.headerColor,
    required this.zoomLevelNotifier,
    required this.onPanUpdate,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onReload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: Container(
        height: _kHeaderHeight,
        decoration: BoxDecoration(
          color: headerColor ?? Colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_kBorderRadius),
            topRight: Radius.circular(_kBorderRadius),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: _kHorizontalPadding),
            const Icon(Icons.picture_as_pdf, color: Colors.white),
            const SizedBox(width: _kSmallHorizontalPadding),
            Expanded(
              child: Text(
                title ?? 'PDF Viewer',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Zoom controls
            _ZoomControls(
              zoomLevelNotifier: zoomLevelNotifier,
              onZoomIn: onZoomIn,
              onZoomOut: onZoomOut,
              onResetZoom: onResetZoom,
            ),
            IconButton(
              onPressed: onReload,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reload',
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}

/// Zoom controls widget for the PDF viewer
class _ZoomControls extends StatelessWidget {
  // UI Constants
  static const double _kIconSize = 20.0;
  static const double _kZoomTextSize = 12.0;
  static const double _kZoomDisplayMultiplier = 100.0;

  final ValueNotifier<double> zoomLevelNotifier;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  const _ZoomControls({
    required this.zoomLevelNotifier,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: zoomLevelNotifier,
      builder: (context, zoomLevel, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onZoomOut,
              icon: const Icon(Icons.zoom_out, color: Colors.white),
              tooltip: 'Zoom out',
              iconSize: _kIconSize,
            ),
            Text(
              '${(zoomLevel * _kZoomDisplayMultiplier).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: _kZoomTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onZoomIn,
              icon: const Icon(Icons.zoom_in, color: Colors.white),
              tooltip: 'Zoom in',
              iconSize: _kIconSize,
            ),
            IconButton(
              onPressed: onResetZoom,
              icon: const Icon(Icons.fit_screen, color: Colors.white),
              tooltip: 'Reset zoom',
              iconSize: _kIconSize,
            ),
          ],
        );
      },
    );
  }
}

/// WebView content widget for the PDF viewer
class _WebViewContent extends StatelessWidget {
  // UI Constants
  static const double _kBorderRadius = 12.0;

  final WebViewController controller;
  final ValueNotifier<bool> isLoadingNotifier;

  const _WebViewContent({
    required this.controller,
    required this.isLoadingNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_kBorderRadius),
          bottomRight: Radius.circular(_kBorderRadius),
        ),
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (!isLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.white,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Resize handle widget for the floating PDF viewer
class _ResizeHandle extends StatelessWidget {
  // UI Constants
  static const double _kBorderRadius = 12.0;
  static const double _kResizeHandleSize = 20.0;
  static const double _kResizeHandleIconSize = 16.0;

  final Color? headerColor;
  final Function(DragUpdateDetails) onPanUpdate;

  const _ResizeHandle({required this.headerColor, required this.onPanUpdate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: _kResizeHandleSize,
          height: _kResizeHandleSize,
          decoration: BoxDecoration(
            color: headerColor ?? Colors.blue,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(_kBorderRadius),
            ),
          ),
          child: const Icon(
            Icons.drag_handle,
            color: Colors.white,
            size: _kResizeHandleIconSize,
          ),
        ),
      ),
    );
  }
}

/// Helper class to manage floating PDF viewer overlays
class FloatingPdfViewerManager {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;

  /// Shows a floating PDF viewer overlay
  void show({
    required BuildContext context,
    required String pdfUrl,
    String? title,
    Color? headerColor,
    double? initialLeft,
    double? initialTop,
    double? initialWidth,
    double? initialHeight,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    VoidCallback? onClose,
  }) {
    if (_overlayEntry != null) return;

    // Combined close function that calls custom callback and then hides the overlay
    void combinedOnClose() {
      onClose?.call();
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingPdfViewer(
        onClose: combinedOnClose,
        pdfUrl: pdfUrl,
        title: title,
        headerColor: headerColor,
        initialLeft: initialLeft,
        initialTop: initialTop,
        initialWidth: initialWidth,
        initialHeight: initialHeight,
        minWidth: minWidth,
        minHeight: minHeight,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  /// Hides the floating PDF viewer overlay
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  /// Returns true if the overlay is currently visible
  bool get isVisible => _isVisible;

  /// Disposes the manager and removes any active overlay
  void dispose() {
    hide();
  }
}
