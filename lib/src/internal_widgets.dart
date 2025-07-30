import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Floating container widget for the PDF viewer
class FloatingContainer extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;
  static const double _elevation = 8.0;

  final ValueNotifier<double> widthNotifier;
  final ValueNotifier<double> heightNotifier;
  final String? title;
  final Color? headerColor;
  final ValueNotifier<double> zoomLevelNotifier;
  final WebViewController controller;
  final ValueNotifier<bool> isLoadingNotifier;
  final ValueNotifier<bool> hasErrorNotifier;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onReload;
  final VoidCallback onClose;

  const FloatingContainer({
    super.key,
    required this.widthNotifier,
    required this.heightNotifier,
    required this.title,
    required this.headerColor,
    required this.zoomLevelNotifier,
    required this.controller,
    required this.isLoadingNotifier,
    required this.hasErrorNotifier,
    required this.onPanUpdate,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onReload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widthNotifier, heightNotifier]),
      builder: (context, child) {
        return Material(
          elevation: _elevation,
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Container(
            width: widthNotifier.value,
            height: heightNotifier.value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_borderRadius),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header bar (draggable)
                HeaderBar(
                  title: title,
                  headerColor: headerColor,
                  zoomLevelNotifier: zoomLevelNotifier,
                  onPanUpdate: onPanUpdate,
                  onZoomIn: onZoomIn,
                  onZoomOut: onZoomOut,
                  onResetZoom: onResetZoom,
                  onReload: onReload,
                  onClose: onClose,
                ),
                // WebView content
                WebViewContent(
                  controller: controller,
                  isLoadingNotifier: isLoadingNotifier,
                  hasErrorNotifier: hasErrorNotifier,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Header bar widget for the floating PDF viewer
class HeaderBar extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;
  static const double _headerHeight = 50.0;
  static const double _horizontalPadding = 12.0;
  static const double _smallHorizontalPadding = 8.0;

  final String? title;
  final Color? headerColor;
  final ValueNotifier<double> zoomLevelNotifier;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onReload;
  final VoidCallback onClose;

  const HeaderBar({
    super.key,
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
        height: _headerHeight,
        decoration: BoxDecoration(
          color: headerColor ?? Colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_borderRadius),
            topRight: Radius.circular(_borderRadius),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: _horizontalPadding),
            const Icon(Icons.picture_as_pdf, color: Colors.white),
            const SizedBox(width: _smallHorizontalPadding),
            Expanded(
              child: Text(
                title ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Zoom controls
            ZoomControls(
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
class ZoomControls extends StatelessWidget {
  // UI Constants
  static const double _iconSize = 20.0;
  static const double _zoomTextSize = 12.0;
  static const double _zoomDisplayMultiplier = 100.0;

  final ValueNotifier<double> zoomLevelNotifier;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  const ZoomControls({
    super.key,
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
              iconSize: _iconSize,
            ),
            Text(
              '${(zoomLevel * _zoomDisplayMultiplier).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: _zoomTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onZoomIn,
              icon: const Icon(Icons.zoom_in, color: Colors.white),
              tooltip: 'Zoom in',
              iconSize: _iconSize,
            ),
            IconButton(
              onPressed: onResetZoom,
              icon: const Icon(Icons.fit_screen, color: Colors.white),
              tooltip: 'Reset zoom',
              iconSize: _iconSize,
            ),
          ],
        );
      },
    );
  }
}

/// WebView content widget for the PDF viewer
class WebViewContent extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;

  final WebViewController controller;
  final ValueNotifier<bool> isLoadingNotifier;
  final ValueNotifier<bool> hasErrorNotifier;

  const WebViewContent({
    super.key,
    required this.controller,
    required this.isLoadingNotifier,
    required this.hasErrorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        ),
        child: Stack(
          children: [
            WebViewWidget(controller: controller),
            // Loading indicator
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (!isLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading PDF...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Error indicator
            ValueListenableBuilder<bool>(
              valueListenable: hasErrorNotifier,
              builder: (context, hasError, child) {
                if (!hasError) return const SizedBox.shrink();
                return Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Click the refresh button to try again',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
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
class ResizeHandle extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;
  static const double _resizeHandleSize = 20.0;
  static const double _resizeHandleIconSize = 16.0;

  final Color? headerColor;
  final Function(DragUpdateDetails) onPanUpdate;

  const ResizeHandle({
    super.key,
    required this.headerColor,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: _resizeHandleSize,
          height: _resizeHandleSize,
          decoration: BoxDecoration(
            color: headerColor ?? Colors.blue,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(_borderRadius),
            ),
          ),
          child: const Icon(
            Icons.drag_handle,
            color: Colors.white,
            size: _resizeHandleIconSize,
          ),
        ),
      ),
    );
  }
}
