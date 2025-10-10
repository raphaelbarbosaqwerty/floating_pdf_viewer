import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'internal_widgets.dart';
import 'options.dart';
import 'pdf_downloader.dart';

/// A floating PDF viewer widget that can be displayed as an overlay.
///
/// This widget creates a draggable, resizable floating window with a PDF viewer
/// that displays PDF documents using pdfx library.
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
  // Window boundary constraints
  static const double _minVisibleWidth = 100.0;
  static const double _minVisibleHeight = 50.0;

  // PDF controller
  PdfControllerPinch? _pdfController;
  Uint8List? _pdfBytes;

  late final ValueNotifier<double> _leftNotifier;
  late final ValueNotifier<double> _topNotifier;
  late final ValueNotifier<double> _widthNotifier;
  late final ValueNotifier<double> _heightNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<bool> _hasErrorNotifier;
  late final ValueNotifier<bool> _isMinimizedNotifier;

  double _downloadProgress = 0.0;
  String? _errorMessage;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifiers();
    _loadPdf();
  }

  void _initializeNotifiers() {
    _leftNotifier = ValueNotifier(widget.options.initialLeft ?? 0.0);
    _topNotifier = ValueNotifier(widget.options.initialTop ?? 0.0);
    _widthNotifier = ValueNotifier(widget.options.initialWidth);
    _heightNotifier = ValueNotifier(widget.options.initialHeight);
    _isLoadingNotifier = ValueNotifier(true);
    _hasErrorNotifier = ValueNotifier(false);
    _isMinimizedNotifier = ValueNotifier(false);
  }

  Future<void> _loadPdf() async {
    if (!mounted) return;

    _isLoadingNotifier.value = true;
    _hasErrorNotifier.value = false;
    _downloadProgress = 0.0;
    _errorMessage = null;

    try {
      // Download PDF with progress
      _pdfBytes = await PdfDownloader.downloadPdfBytesWithProgress(
        widget.pdfUrl,
        (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );

      // Create PDF controller
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(_pdfBytes!),
      );

      if (mounted) {
        _isLoadingNotifier.value = false;
        _retryCount = 0; // Reset retry count on success
      }
    } catch (e) {
      if (!mounted) return;

      // Retry logic
      if (_retryCount < widget.options.maxRetries) {
        _retryCount++;

        await Future.delayed(widget.options.retryDelay);

        if (mounted) {
          await _loadPdf();
        }
      } else {
        // All retries exhausted, show error
        if (mounted) {
          _isLoadingNotifier.value = false;
          _hasErrorNotifier.value = true;
          _errorMessage = e.toString();
        }
      }
    }
  }

  Future<void> _reloadPdf() async {
    _pdfController?.dispose();
    _pdfController = null;
    _pdfBytes = null;
    _retryCount = 0; // Reset retry count on manual reload
    await _loadPdf();
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isMinimizedNotifier,
      builder: (context, isMinimized, child) {
        return Stack(
          children: [
            // Keep the PDF viewer alive even when minimized
            AnimatedBuilder(
              animation: Listenable.merge([_leftNotifier, _topNotifier]),
              builder: (context, child) {
                return Positioned(
                  left: _leftNotifier.value,
                  top: _topNotifier.value,
                  child: Visibility(
                    visible: !isMinimized,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: false,
                    child: Stack(
                      children: [
                        FloatingPdfContainer(
                          widthNotifier: _widthNotifier,
                          heightNotifier: _heightNotifier,
                          title: widget.options.title,
                          headerColor: widget.options.headerColor,
                          pdfController: _pdfController,
                          isLoadingNotifier: _isLoadingNotifier,
                          hasErrorNotifier: _hasErrorNotifier,
                          downloadProgress: _downloadProgress,
                          errorMessage: _errorMessage,
                          onPanUpdate: (details) => _handlePanUpdate(
                            details,
                            MediaQuery.sizeOf(context),
                          ),
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
                  ),
                );
              },
            ),
            // Show minimized button when minimized
            if (isMinimized)
              MinimizedFloatingButton(
                headerColor: widget.options.headerColor,
                onRestore: _toggleMinimize,
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _pdfBytes = null;
    _leftNotifier.dispose();
    _topNotifier.dispose();
    _widthNotifier.dispose();
    _heightNotifier.dispose();
    _isLoadingNotifier.dispose();
    _hasErrorNotifier.dispose();
    _isMinimizedNotifier.dispose();
    super.dispose();
  }
}
