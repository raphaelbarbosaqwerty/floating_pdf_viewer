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
  bool _isInitializing = false;

  late final ValueNotifier<double> _leftNotifier;
  late final ValueNotifier<double> _topNotifier;
  late final ValueNotifier<double> _widthNotifier;
  late final ValueNotifier<double> _heightNotifier;
  late final ValueNotifier<double> _zoomLevelNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<bool> _hasErrorNotifier;
  late final ValueNotifier<bool> _isMinimizedNotifier;

  // Loading timeout and retry
  static const Duration _loadingTimeout = Duration(seconds: 15);
  static const Duration _validationDelay = Duration(seconds: 6);
  static const Duration _validationInterval = Duration(seconds: 8);
  static const int _maxRetries = 3;
  static const int _maxValidationAttempts = 3;
  int _retryCount = 0;
  int _validationAttempts = 0;
  bool _hasValidatedSuccessfully = false;
  Timer? _continuousValidationTimer;
  Timer? _loadingTimeoutTimer;

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
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.pdfUrl)}&embedded=true';

      if (_isControllerInitialized) {
        try {
          await _controller.loadRequest(Uri.parse(googleViewerUrl));
        } catch (e) {
          _handleLoadingError();
        }
      } else {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..enableZoom(true)
          ..setUserAgent(
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                _isLoadingNotifier.value = true;
                _hasErrorNotifier.value = false;
                _startLoadingTimeout();
              },
              onPageFinished: (String url) {
                _hasErrorNotifier.value = false;

                if (!_hasValidatedSuccessfully) {
                  _validatePageContent();
                } else {
                  _retryCount = 0;
                  _validationAttempts = 0;
                  _consecutiveFailures = 0;
                  _loadingTimeoutTimer?.cancel();
                  _isLoadingNotifier.value = false;
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
          _isControllerInitialized = true;
        } catch (e) {
          _handleLoadingError();
        }
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Starts a timeout to detect failed loads
  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_loadingTimeout, () {
      if (mounted && _isLoadingNotifier.value && !_hasValidatedSuccessfully) {
        _handleLoadingError();
      }
    });
  }

  /// Cancels loading timeout when validation starts
  void _cancelLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
  }

  /// Validates if the page content actually loaded correctly
  Future<void> _validatePageContent() async {
    try {
      // Cancel timeout since validation is starting
      _cancelLoadingTimeout();

      await Future.delayed(_validationDelay);

      if (!mounted) return;

      final currentUrl = await _controller.currentUrl();

      if (currentUrl == null || !currentUrl.contains('docs.google.com')) {
        _handleLoadingError();
        return;
      }

      // Try validation multiple times before giving up
      await _validateWithRetries();
    } catch (e) {
      _handleLoadingError();
    }
  }

  /// Validates content with multiple attempts for resilience
  Future<void> _validateWithRetries() async {
    for (int attempt = 1; attempt <= _maxValidationAttempts; attempt++) {
      if (!mounted) return;

      bool hasContent = await _checkIfPdfContentIsVisible();

      if (hasContent) {
        _hasValidatedSuccessfully = true;
        _retryCount = 0;
        _validationAttempts = 0;
        _consecutiveFailures = 0;
        _loadingTimeoutTimer?.cancel();

        if (mounted) {
          _isLoadingNotifier.value = false;
          _hasErrorNotifier.value = false;
        }

        _startContinuousValidation();
        return;
      }

      // If not the last attempt, wait before retrying
      if (attempt < _maxValidationAttempts) {
        await Future.delayed(
          Duration(seconds: 2 * attempt),
        ); // Progressive delay
      }
    }

    // All validation attempts failed
    _validationAttempts++;
    _handleLoadingError();
  }

  /// Starts continuous validation to detect content that disappears after initial load
  void _startContinuousValidation() {
    _continuousValidationTimer?.cancel();

    _continuousValidationTimer = Timer.periodic(_validationInterval, (
      timer,
    ) async {
      if (!mounted ||
          _isMinimizedNotifier.value ||
          !_hasValidatedSuccessfully) {
        timer.cancel();
        return;
      }

      await _performContinuousValidation(timer);
    });
  }

  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 2;

  /// Performs continuous validation with debounce to prevent false positives
  Future<void> _performContinuousValidation(Timer timer) async {
    try {
      bool hasContent = await _checkIfPdfContentIsVisible();

      if (hasContent) {
        // Reset failure counter on success
        _consecutiveFailures = 0;
      } else if (!_isLoadingNotifier.value && !_hasErrorNotifier.value) {
        _consecutiveFailures++;

        // Only trigger silent failure after multiple consecutive failures
        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          timer.cancel();
          _handleSilentFailure();
        }
      }
    } catch (e) {
      // Don't count JavaScript errors as failures
      // PDF might be in transition state
    }
  }

  /// Handles silent failures where content appears loaded but is actually blank
  void _handleSilentFailure() {
    if (!mounted) return;

    _hasValidatedSuccessfully = false;
    _consecutiveFailures = 0;
    _reloadPdf();
  }

  /// Checks if PDF content is actually visible in the WebView
  Future<bool> _checkIfPdfContentIsVisible() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          function isElementVisible(element) {
            if (!element) return false;
            const rect = element.getBoundingClientRect();
            const style = window.getComputedStyle(element);
            return rect.width > 0 &&
                   rect.height > 0 &&
                   style.visibility !== 'hidden' &&
                   style.opacity !== '0' &&
                   style.display !== 'none' &&
                   rect.top < window.innerHeight &&
                   rect.bottom > 0;
          }

          // Check for Google Docs viewer elements
          const viewerSelectors = [
            '[data-viewer-container]',
            '.ndfHFb-c4YZDc',
            '#viewer-container',
            '.ndfHFb-c4YZDc-to915-LgbsSe',
            '.kix-canvas-tile-content'
          ];

          for (let selector of viewerSelectors) {
            const element = document.querySelector(selector);
            if (element && element.offsetHeight > 50 && isElementVisible(element)) {
              return true;
            }
          }

          // Check for embedded PDF elements
          const embeds = document.querySelectorAll('embed[type="application/pdf"], object[type="application/pdf"]');
          for (let embed of embeds) {
            if (isElementVisible(embed)) {
              return true;
            }
          }

          // Check for canvas elements
          const canvases = document.querySelectorAll('canvas');
          for (let canvas of canvases) {
            if (canvas.offsetHeight > 100 && canvas.offsetWidth > 100 && isElementVisible(canvas)) {
              return true;
            }
          }

          return false;
        })();
      ''');

      return result.toString() == 'true';
    } catch (e) {
      return false;
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
      final delaySeconds = 2 + (_retryCount * 2);

      Future.delayed(Duration(seconds: delaySeconds), () {
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
    _consecutiveFailures = 0;
    _hasValidatedSuccessfully = false;
    _isLoadingNotifier.value = true;
    _hasErrorNotifier.value = false;

    await _loadPdfWithRetry();
  }

  /// Toggle minimize/restore state
  void _toggleMinimize() {
    _isMinimizedNotifier.value = !_isMinimizedNotifier.value;
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
                    onPanUpdate: (details) {
                      final screenSize = MediaQuery.sizeOf(context);

                      const minVisibleWidth = 100.0;
                      const minVisibleHeight = 50.0;

                      final minLeft =
                          -((_widthNotifier.value - minVisibleWidth));
                      final maxLeft = screenSize.width - minVisibleWidth;
                      final minTop =
                          -((_heightNotifier.value - minVisibleHeight));
                      final maxTop = screenSize.height - minVisibleHeight;

                      _leftNotifier.value =
                          (_leftNotifier.value + details.delta.dx).clamp(
                            minLeft,
                            maxLeft,
                          );
                      _topNotifier.value =
                          (_topNotifier.value + details.delta.dy).clamp(
                            minTop,
                            maxTop,
                          );
                    },
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onResetZoom: _resetZoom,
                    onReload: _reloadPdf,
                    onMinimize: _toggleMinimize,
                    onClose: () => widget.onClose?.call(),
                  ),
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
