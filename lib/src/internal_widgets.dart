import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Header bar widget for the floating PDF viewer
class HeaderBar extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;
  static const double _headerHeight = 50.0;
  static const double _iconPadding = 8.0;

  final String? title;
  final Color? headerColor;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onReload;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const HeaderBar({
    super.key,
    required this.title,
    required this.headerColor,
    required this.onPanUpdate,
    required this.onReload,
    required this.onMinimize,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _iconPadding),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
            if ((title ?? "").isNotEmpty)
              Expanded(
                child: Text(
                  title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Spacer(),
            IconButton(
              onPressed: onReload,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Reload',
              iconSize: 18,
            ),
            IconButton(
              onPressed: onMinimize,
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white,
              ),
              tooltip: 'Minimize',
              iconSize: 18,
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimized floating button widget
class MinimizedFloatingButton extends StatefulWidget {
  final Color? headerColor;
  final VoidCallback onRestore;

  const MinimizedFloatingButton({
    super.key,
    required this.headerColor,
    required this.onRestore,
  });

  @override
  State<MinimizedFloatingButton> createState() =>
      _MinimizedFloatingButtonState();
}

class _MinimizedFloatingButtonState extends State<MinimizedFloatingButton> {
  late ValueNotifier<Offset> _positionNotifier;
  bool _isPositionInitialized = false;

  static const double _buttonSize = 56.0;
  static const double _defaultRightMargin = 20.0;
  static const double _safeAreaPadding = 20.0;

  @override
  void initState() {
    super.initState();
    // Initialize with temporary position, will be updated in didChangeDependencies
    _positionNotifier = ValueNotifier(Offset.zero);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializePosition();
  }

  void _initializePosition() {
    if (_isPositionInitialized) return;

    final screenSize = MediaQuery.sizeOf(context);
    final screenCenter = screenSize.height / 2;

    // Position on the right side of screen, vertically centered
    final initialPosition = Offset(
      screenSize.width - _buttonSize - _defaultRightMargin,
      screenCenter - (_buttonSize / 2),
    );

    _positionNotifier.value = initialPosition;
    _isPositionInitialized = true;
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    super.dispose();
  }

  void _updatePosition(DragUpdateDetails details) {
    final screenSize = MediaQuery.sizeOf(context);
    final currentPosition = _positionNotifier.value;

    // Calculate new position
    final newX = currentPosition.dx + details.delta.dx;
    final newY = currentPosition.dy + details.delta.dy;

    // Constrain to screen bounds with safe area padding
    final constrainedX = newX.clamp(
      _safeAreaPadding,
      screenSize.width - _buttonSize - _safeAreaPadding,
    );
    final constrainedY = newY.clamp(
      _safeAreaPadding,
      screenSize.height - _buttonSize - _safeAreaPadding,
    );

    _positionNotifier.value = Offset(constrainedX, constrainedY);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: _updatePosition,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(_buttonSize / 2),
              child: Container(
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  color: widget.headerColor ?? Colors.blue,
                  borderRadius: BorderRadius.circular(_buttonSize / 2),
                ),
                child: IconButton(
                  onPressed: widget.onRestore,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Restore PDF Viewer',
                ),
              ),
            ),
          ),
        );
      },
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

/// Floating PDF container widget using pdfx
class FloatingPdfContainer extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;
  static const double _elevation = 8.0;

  final ValueNotifier<double> widthNotifier;
  final ValueNotifier<double> heightNotifier;
  final String? title;
  final Color? headerColor;
  final PdfControllerPinch? pdfController;
  final ValueNotifier<bool> isLoadingNotifier;
  final ValueNotifier<bool> hasErrorNotifier;
  final double downloadProgress;
  final String? errorMessage;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onReload;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const FloatingPdfContainer({
    super.key,
    required this.widthNotifier,
    required this.heightNotifier,
    required this.title,
    required this.headerColor,
    required this.pdfController,
    required this.isLoadingNotifier,
    required this.hasErrorNotifier,
    required this.downloadProgress,
    required this.errorMessage,
    required this.onPanUpdate,
    required this.onReload,
    required this.onMinimize,
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
                  onPanUpdate: onPanUpdate,
                  onReload: onReload,
                  onMinimize: onMinimize,
                  onClose: onClose,
                ),
                // PDF content
                PdfContent(
                  pdfController: pdfController,
                  isLoadingNotifier: isLoadingNotifier,
                  hasErrorNotifier: hasErrorNotifier,
                  downloadProgress: downloadProgress,
                  errorMessage: errorMessage,
                  onReload: onReload,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// PDF content widget using pdfx
class PdfContent extends StatelessWidget {
  // UI Constants
  static const double _borderRadius = 12.0;

  final PdfControllerPinch? pdfController;
  final ValueNotifier<bool> isLoadingNotifier;
  final ValueNotifier<bool> hasErrorNotifier;
  final double downloadProgress;
  final String? errorMessage;
  final VoidCallback onReload;

  const PdfContent({
    super.key,
    required this.pdfController,
    required this.isLoadingNotifier,
    required this.hasErrorNotifier,
    required this.downloadProgress,
    required this.errorMessage,
    required this.onReload,
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
          fit: StackFit.expand,
          children: [
            if (pdfController != null)
              RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xff2f343e)),
                  child: PdfViewPinch(
                    controller: pdfController!,
                    padding: 0,
                    backgroundDecoration: BoxDecoration(color: Colors.red),
                  ),
                ),
              ),
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (!isLoading) return const SizedBox.shrink();
                return Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: downloadProgress > 0 ? downloadProgress : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          downloadProgress > 0
                              ? 'Downloading ${(downloadProgress * 100).toStringAsFixed(0)}%'
                              : 'Loading PDF...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            errorMessage ?? 'Unknown error',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: onReload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
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
