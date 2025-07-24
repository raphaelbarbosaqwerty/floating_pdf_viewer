import 'package:flutter/material.dart';

import 'floating_pdf_viewer_widget.dart';
import 'options.dart';

/// Helper class to manage floating PDF viewer overlays
class FloatingPdfViewerManager {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;

  /// Shows a floating PDF viewer overlay
  ///
  /// [context] - The build context for inserting the overlay
  /// [pdfUrl] - The URL of the PDF to display
  /// [options] - Configuration options for the floating viewer. If null, default options are used
  /// [onClose] - Optional callback called when the floating viewer is closed
  void show({
    required BuildContext context,
    required String pdfUrl,
    FloatingPdfViewerOptions? options,
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
        options: options ?? const FloatingPdfViewerOptions(),
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
