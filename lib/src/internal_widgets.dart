import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Floating container widget for the PDF viewer
class FloatingContainer extends StatelessWidget {
  // UI Constants
  static const double kBorderRadius = 12.0;
  static const double kElevation = 8.0;

  final ValueNotifier<double> widthNotifier;
  final ValueNotifier<double> heightNotifier;
  final String? title;
  final Color? headerColor;
  final ValueNotifier<double> zoomLevelNotifier;
  final WebViewController controller;
  final ValueNotifier<bool> isLoadingNotifier;
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
          elevation: kElevation,
          borderRadius: BorderRadius.circular(kBorderRadius),
          child: Container(
            width: widthNotifier.value,
            height: heightNotifier.value,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kBorderRadius),
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
  static const double kBorderRadius = 12.0;
  static const double kHeaderHeight = 50.0;
  static const double kHorizontalPadding = 12.0;
  static const double kSmallHorizontalPadding = 8.0;

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
        height: kHeaderHeight,
        decoration: BoxDecoration(
          color: headerColor ?? Colors.blue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kBorderRadius),
            topRight: Radius.circular(kBorderRadius),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: kHorizontalPadding),
            const Icon(Icons.picture_as_pdf, color: Colors.white),
            const SizedBox(width: kSmallHorizontalPadding),
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
  static const double kIconSize = 20.0;
  static const double kZoomTextSize = 12.0;
  static const double kZoomDisplayMultiplier = 100.0;

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
              iconSize: kIconSize,
            ),
            Text(
              '${(zoomLevel * kZoomDisplayMultiplier).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: kZoomTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: onZoomIn,
              icon: const Icon(Icons.zoom_in, color: Colors.white),
              tooltip: 'Zoom in',
              iconSize: kIconSize,
            ),
            IconButton(
              onPressed: onResetZoom,
              icon: const Icon(Icons.fit_screen, color: Colors.white),
              tooltip: 'Reset zoom',
              iconSize: kIconSize,
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
  static const double kBorderRadius = 12.0;

  final WebViewController controller;
  final ValueNotifier<bool> isLoadingNotifier;

  const WebViewContent({
    super.key,
    required this.controller,
    required this.isLoadingNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(kBorderRadius),
          bottomRight: Radius.circular(kBorderRadius),
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
class ResizeHandle extends StatelessWidget {
  // UI Constants
  static const double kBorderRadius = 12.0;
  static const double kResizeHandleSize = 20.0;
  static const double kResizeHandleIconSize = 16.0;

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
          width: kResizeHandleSize,
          height: kResizeHandleSize,
          decoration: BoxDecoration(
            color: headerColor ?? Colors.blue,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(kBorderRadius),
            ),
          ),
          child: const Icon(
            Icons.drag_handle,
            color: Colors.white,
            size: kResizeHandleIconSize,
          ),
        ),
      ),
    );
  }
}
