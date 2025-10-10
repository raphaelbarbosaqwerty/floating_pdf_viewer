## 0.1.7

* **New Feature**: Disk-based PDF caching system
  * Created `PdfCacheManager` class for intelligent cache management
  * PDFs are now stored on disk (in temporary directory) instead of RAM
  * Dramatically reduces memory usage (critical for PDFs > 16MB)
  * Previously downloaded PDFs load instantly from cache
  * Cached PDFs work offline without internet connection
  * Uses SHA-256 hash of URL for unique file identification
  * Added cache statistics API (`getCacheStats()`, `getCacheSize()`, `getCacheFileCount()`)
  * Provides manual cache management methods (`clearCache()`, `removeCachedPdf()`)
  * Cache location: `getTemporaryDirectory()/pdf_cache/`
  * Added `path_provider: ^2.1.5` and `crypto: ^3.0.6` dependencies
* **New Feature**: Automatic retry mechanism
  * Added configurable retry system for failed PDF downloads
  * New `maxRetries` option in `FloatingPdfViewerOptions` (default: 3)
  * New `retryDelay` option in `FloatingPdfViewerOptions` (default: 2 seconds)
  * Automatically retries download on network failures
  * Silent background retries without user intervention
  * Shows error only after all retry attempts are exhausted
  * Perfect for unstable network conditions in dealerships
* **Enhancement**: Improved PDF download system
  * Created dedicated `PdfDownloader` class with cache support
  * Added `getPdfFileWithCache()` method that checks cache before downloading
  * Changed from memory-based (Uint8List) to file-based (File) PDF handling
  * Exported `PdfCacheManager` and `PdfDownloader` as public API
* **Performance**: Significantly improved memory usage and loading times
  * PDFs stored on disk instead of RAM (saves hundreds of MBs for large PDFs)
  * Instant loading for cached PDFs (no re-download needed)
  * Reduced memory footprint with optimized state management
* **Documentation**: Comprehensive cache system documentation
  * Added detailed cache management section in README
  * Included cache statistics examples and UI implementation
  * Documented retry mechanism configuration and best practices
  * Updated package structure to show new cache-related files

## 0.1.6

* **BREAKING CHANGE**: Migrated from WebView to native PDF rendering
  * Replaced `webview_flutter` with `pdfx` for direct PDF rendering
  * Eliminates Content Security Policy (CSP) errors from Google Docs Viewer
  * Provides better performance and more reliable PDF loading
  * Native PDF rendering works consistently across all platforms
* **BREAKING CHANGE**: Removed manual zoom controls
  * Removed zoom in, zoom out, and reset zoom buttons from header bar
  * Users now rely exclusively on native pinch-to-zoom gestures
  * Provides more intuitive and natural zoom interaction
  * Reduces UI clutter in header bar
* **Critical Fix**: Resolved PDF disappearing after minimization
  * Replaced conditional rendering with `Visibility` widget
  * Added `maintainState: true` to preserve PDF state when minimized
  * PDF viewer now correctly restores with full content after un-minimizing
  * Fixed "Incorrect use of ParentDataWidget" error during minimization
* **New Feature**: Direct PDF download with progress tracking
  * Created dedicated `PdfDownloader` class for PDF handling
  * Added `downloadPdfBytesWithProgress` method with real-time progress callbacks
  * Downloads PDF directly to memory (Uint8List) for better performance
  * Displays download progress percentage in loading indicator
  * Eliminated dependency on external PDF viewer services
* **Testing**: Added comprehensive test coverage
  * Added `mocktail ^1.0.0` as dev dependency for mocking
  * Created `pdf_downloader_test.dart` with 6 test cases:
    - Success and error scenarios for direct downloads
    - Progress tracking validation
    - Network error handling
  * Created `manager_test.dart` with 9 test cases:
    - Show/hide overlay functionality
    - Custom options handling
    - Auto-centering behavior
    - Multiple show/hide cycles
    - Dispose and cleanup validation
* **Enhancement**: Improved PDF viewer UI
  * Added custom background decoration to PDF viewer
  * Improved loading indicator appearance with circular progress
  * Removed unnecessary spacing in PDF content area
  * Added `RepaintBoundary` for better rendering performance
* **Code Quality**: Refactored PDF loading architecture
  * Removed `pdf_document_helper.dart` (no longer needed with pdfx)
  * Simplified controller initialization and state management
  * Better separation of concerns with dedicated downloader class
  * Cleaner error handling and retry logic
* **Performance**: Faster PDF loading and rendering
  * Direct PDF byte loading eliminates external service latency
  * Native rendering removes WebView overhead
  * Reduced memory footprint with optimized state management

## 0.1.5

* **Critical Fix**: Resolved blank screen issue for certain PDFs after initial load
  * Completely redesigned PDF content validation with 5-layer fallback system
  * Added iframe detection for more reliable PDF viewer identification
  * Added large container detection to catch viewer elements regardless of CSS class changes
  * Expanded viewer selectors to include accessibility attributes ([role="document"], [role="main"])
  * Reduced canvas size threshold from 100px to 50px for better small PDF detection
  * Added final fallback based on substantial page content (scrollHeight/scrollWidth)
  * Changed error handling to assume success on JavaScript errors (prevents false negatives)
* **Performance**: Significantly improved PDF loading times
  * Reduced initial validation delay from 6 seconds to 2 seconds (70% faster)
  * Optimized validation timeout from 15s to 12s with better success detection
  * Increased validation interval from 3s to 5s to reduce unnecessary checks
  * Improved retry delays: now uses 1s, 2s progression instead of 2s, 4s, 6s
* **Performance**: Optimized widget rebuild cycle
  * Extracted inline callbacks from build() method to dedicated handler methods
  * Moved magic numbers to named constants (_minVisibleWidth, _minVisibleHeight)
  * Eliminated function recreation on every rebuild for better memory efficiency
  * Created dedicated _handlePanUpdate and _handleResizePanUpdate methods
* **Enhancement**: More tolerant continuous validation
  * Increased max consecutive failures from 2 to 3 before triggering reload
  * Better handling of temporary validation failures during PDF rendering
  * Reduced false positives that caused unnecessary reloads
* **Code Quality**: Improved code organization and maintainability
  * Better separation of concerns with dedicated validation methods
  * Clearer constant naming and grouping
  * Enhanced documentation for complex validation logic

## 0.1.4

* **Critical Fix**: Resolved blank screen issue when returning from background
  * Added WidgetsBindingObserver to detect app lifecycle changes
  * WebViewController is now properly reinitialized when app returns from background
  * Fixed race conditions that caused blank screens when clicking PDF buttons too quickly
  * Added protection against multiple simultaneous WebView initializations
  * Improved state management for better reliability across app lifecycle

## 0.1.3

* **Enhancement**: Draggable minimized floating button
  * Minimized PDF floating button can now be dragged to any position on screen
  * Added smooth drag interaction with proper screen boundary constraints
  * Maintains button position during drag gestures with safe area padding
  * Converted MinimizedFloatingButton from StatelessWidget to StatefulWidget for drag state management

## 0.1.2

* **New Feature**: Minimize PDF viewer to floating button
  * Added minimize button to header bar with remove circle outline icon
  * When minimized, PDF viewer transforms into a compact floating button
  * Floating button positioned on the right side of screen for easy access
  * Click floating button to restore full PDF viewer instantly
  * Maintains PDF state and position when minimizing/restoring
* **Fix**: Resolved header bar overflow in compact layouts
  * Optimized icon sizes from 20px to 18px for better space utilization
  * Reduced zoom controls padding and text size for improved layout
  * Increased minimum width from 300px to 320px to prevent UI clipping
  * Enhanced overall header bar responsiveness for smaller screen sizes
* **Enhancement**: Improved UI density and visual balance in header controls
* **Testing**: Updated tests to reflect new minimum width requirement

## 0.1.1

* **Fix**: Resolved retry mechanism causing `LateInitializationError` when PDF fails to load
  * Fixed WebViewController reinitialization issue during automatic retries
  * Improved error handling with proper controller state management
  * Prevented infinite retry loops with validation flag system
* **Fix**: Enhanced PDF loading validation to reduce false positives
  * Simplified content validation logic to prevent unnecessary retries
  * Added proper success state tracking to avoid re-validation
* **Enhancement**: Removed debug print statements for cleaner production output
* **Enhancement**: Improved error handling with proper catch block comments
* **Performance**: Optimized controller reuse during retry attempts
* **Stability**: Better handling of WebView state during error recovery

## 0.1.0

* **BREAKING CHANGE**: Introduced `FloatingPdfViewerOptions` class for cleaner API
  * Replaced multiple individual parameters with a single `options` parameter
  * All configuration options now grouped in an immutable data class
  * Added `copyWith()` method for easy option modifications
  * Added proper `toString()`, `==`, and `hashCode` implementations
* **Enhancement**: Improved API design following Flutter best practices
* **Enhancement**: Better maintainability and extensibility for future options
* **Enhancement**: Reduced constructor verbosity from 10+ parameters to single options object
* **Documentation**: Updated all examples to demonstrate new `FloatingPdfViewerOptions` usage
* **Documentation**: Added copyWith usage example in main demo
* **Testing**: Added comprehensive tests for `FloatingPdfViewerOptions` class
* **Migration**: Previous API still supported through default options constructor

## 0.0.2

* **Bug Fix**: Fixed ArgumentError when resizing floating window to dimensions larger than screen
* **Enhancement**: Improved drag behavior to allow window movement outside screen while keeping minimum visible area
* **Enhancement**: Ensures close button and header remain accessible even when window is partially off-screen
* **Improvement**: Made onClose callback optional throughout the codebase
* **Docs**: Added preview image to README for better visual documentation

## 0.0.1

* Initial release of floating_pdf_viewer package
* Features:
  * Draggable floating PDF viewer window
  * Interactive resizing capabilities
  * Zoom controls (zoom in, zoom out, reset)
  * PDF loading via URL using Google Docs Viewer
  * Customizable interface (colors, sizes, position)
  * FloatingPdfViewerManager for easy overlay management
  * Support for multiple simultaneous PDF viewers
  * Cross-platform compatibility (Android, iOS, Web, Desktop)
* Examples:
  * Complete demo application
  * Simple usage example
  * Multiple PDF viewers example
  * Manual overlay control example
