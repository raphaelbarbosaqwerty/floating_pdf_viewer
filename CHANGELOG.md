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
