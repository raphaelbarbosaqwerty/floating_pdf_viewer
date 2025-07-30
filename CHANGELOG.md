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
