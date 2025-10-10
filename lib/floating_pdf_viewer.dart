/// A Flutter package that provides a draggable, resizable floating PDF viewer widget.
///
/// This library includes:
/// - [FloatingPdfViewer]: The main widget for displaying PDFs in a floating window
/// - [FloatingPdfViewerOptions]: Configuration options for customizing the viewer
/// - [FloatingPdfViewerManager]: Helper class for managing overlay instances
/// - [PdfCacheManager]: Manages PDF file caching to disk
/// - [PdfDownloader]: Utility class for downloading PDFs with cache support
library;

export 'src/floating_pdf_viewer_widget.dart';
export 'src/manager.dart';
// Public API exports
export 'src/options.dart';
export 'src/pdf_cache_manager.dart';
export 'src/pdf_downloader.dart';
