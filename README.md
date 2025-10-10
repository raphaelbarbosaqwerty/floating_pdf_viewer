# floating_pdf_viewer

A Flutter package that provides a draggable, resizable floating PDF viewer widget with zoom controls and overlay support.

> **🆕 Version 0.1.0**: Now with a cleaner API using `FloatingPdfViewerOptions` for better maintainability and type safety!

## 📱 Preview

<p align="center">
  <img src="https://raw.githubusercontent.com/raphaelbarbosaqwerty/floating_pdf_viewer/main/example/example_image.png" alt="Floating PDF Viewer Demo" width="300"/>
</p>

*Floating PDF viewer in action - draggable, resizable window with zoom controls*

> **Note**: See the example app in the `/example` folder for a complete working demo.

## Features

- ✅ Draggable floating window
- ✅ Interactive resizing
- ✅ Zoom controls (zoom in, zoom out, reset)
- ✅ PDF loading via URL
- ✅ Customizable interface (colors, sizes, position)
- ✅ Automatic overlay management
- ✅ Reload button
- ✅ Easy integration
- ✅ **New in v0.1.0**: Clean API with `FloatingPdfViewerOptions`
- ✅ **New in v0.1.0**: `copyWith()` method for easy configuration
- ✅ **New in v0.1.0**: Organized package structure
- ✅ **New in v0.1.0**: Better maintainability and type safety
- ✅ **New in v0.1.2**: Minimize to floating button
- ✅ **New in v0.1.2**: Draggable minimized button (can be moved anywhere on screen)
- ✅ **New in v0.1.2**: Improved header bar layout to prevent overflow
- ✅ **New in v0.1.7**: Disk-based PDF caching system
- ✅ **New in v0.1.7**: Automatic retry mechanism with configurable attempts
- ✅ **New in v0.1.7**: Reduced memory usage by storing PDFs on disk instead of RAM
- ✅ **New in v0.1.7**: Instant loading for previously viewed PDFs

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  floating_pdf_viewer: ^0.1.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _pdfManager.show(
              context: context,
              pdfUrl: 'https://www.example.com/your-document.pdf',
              options: const FloatingPdfViewerOptions(
                title: 'My Document',
              ),
            );
          },
          child: Text('Open PDF'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfManager.dispose();
    super.dispose();
  }
}
```

## Basic Usage

### 1. Using FloatingPdfViewerManager (Recommended)

```dart
import 'package:flutter/material.dart';
import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FloatingPdfViewerManager _pdfManager = FloatingPdfViewerManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (_pdfManager.isVisible) {
              _pdfManager.hide();
            } else {
              _pdfManager.show(
                context: context,
                pdfUrl: 'https://www.example.com/sample.pdf',
                options: const FloatingPdfViewerOptions(
                  title: 'My PDF',
                  headerColor: Colors.deepPurple,
                ),
              );
            }
          },
          child: Text(_pdfManager.isVisible ? 'Close PDF' : 'Open PDF'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pdfManager.dispose();
    super.dispose();
  }
}
```

### 2. Manual Usage with Overlay

```dart
class _MyHomePageState extends State<MyHomePage> {
  OverlayEntry? _overlayEntry;
  bool _isOverlayVisible = false;

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingPdfViewer(
        pdfUrl: 'https://www.example.com/sample.pdf',
        onClose: _hideOverlay,
        options: const FloatingPdfViewerOptions(
          title: 'PDF Document',
          headerColor: Colors.green,
          initialLeft: 100,
          initialTop: 150,
          initialWidth: 400,
          initialHeight: 600,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOverlayVisible = true;
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOverlayVisible = false;
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }
}
```

## Customization Parameters

### FloatingPdfViewer

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pdfUrl` | `String` | ✅ | URL of the PDF to display |
| `onClose` | `VoidCallback?` | ❌ | Callback executed when closing the viewer |
| `options` | `FloatingPdfViewerOptions` | ❌ | Configuration options (uses defaults if not provided) |

### FloatingPdfViewerOptions

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | `String?` | `null` | Title displayed in the header bar |
| `headerColor` | `Color?` | `null` | Color of the header bar |
| `initialLeft` | `double?` | `null` | Initial horizontal position (centered if null) |
| `initialTop` | `double?` | `null` | Initial vertical position (centered if null) |
| `initialWidth` | `double` | `360.0` | Initial width |
| `initialHeight` | `double` | `500.0` | Initial height |
| `minWidth` | `double` | `320.0` | Minimum width for resizing |
| `minHeight` | `double` | `250.0` | Minimum height for resizing |
| `maxWidth` | `double` | `600.0` | Maximum width for resizing |
| `maxHeight` | `double` | `800.0` | Maximum height for resizing |
| `maxRetries` | `int` | `3` | Maximum number of automatic retry attempts on failure |
| `retryDelay` | `Duration` | `2 seconds` | Delay between retry attempts |

### FloatingPdfViewerManager.show()

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `context` | `BuildContext` | ✅ | Context to insert the overlay |
| `pdfUrl` | `String` | ✅ | URL of the PDF to display |
| `options` | `FloatingPdfViewerOptions?` | ❌ | Configuration options (uses defaults if not provided) |
| `onClose` | `VoidCallback?` | ❌ | Optional callback called when the floating viewer is closed |

## PDF Caching System

### Overview

The package includes a powerful disk-based caching system that:
- **Reduces Memory Usage**: PDFs are stored on disk instead of RAM (important for large PDFs > 16MB)
- **Improves Performance**: Previously downloaded PDFs load instantly from cache
- **Works Offline**: Cached PDFs are available even without internet connection
- **Automatic Management**: Cache is handled automatically, no manual intervention needed

### How It Works

1. **First Load**: PDF is downloaded from URL and saved to cache
2. **Subsequent Loads**: PDF loads instantly from disk cache
3. **Cache Location**: `getTemporaryDirectory()/pdf_cache/`
4. **File Naming**: Uses SHA-256 hash of URL for unique identification

### Automatic Caching (Default Behavior)

By default, all PDFs are automatically cached. You don't need to do anything:

```dart
// PDF will be automatically cached on first load
_pdfManager.show(
  context: context,
  pdfUrl: 'https://example.com/large-document.pdf',
  options: const FloatingPdfViewerOptions(
    title: 'Cached PDF',
  ),
);
```

### Manual Cache Management

You can manually manage the cache if needed:

```dart
import 'package:floating_pdf_viewer/floating_pdf_viewer.dart';

// Check if a PDF is cached
bool isCached = await PdfDownloader.isCached('https://example.com/doc.pdf');

// Clear cache for specific URL
await PdfDownloader.clearCacheForUrl('https://example.com/doc.pdf');

// Clear all cached PDFs
await PdfDownloader.clearAllCache();

// Get cache statistics
final stats = await PdfCacheManager.getCacheStats();
print('Cached files: ${stats.fileCount}');
print('Total cache size: ${stats.totalSizeMB} MB');

// Get specific cache info
int cacheSize = await PdfCacheManager.getCacheSize(); // in bytes
int fileCount = await PdfCacheManager.getCacheFileCount();
```

### Cache Management UI Example

You can create a settings screen to let users manage the cache:

```dart
class CacheSettingsScreen extends StatefulWidget {
  @override
  _CacheSettingsScreenState createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends State<CacheSettingsScreen> {
  CacheStats? _cacheStats;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    final stats = await PdfCacheManager.getCacheStats();
    setState(() => _cacheStats = stats);
  }

  Future<void> _clearCache() async {
    await PdfDownloader.clearAllCache();
    await _loadCacheStats();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cache Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Cached PDFs'),
            subtitle: Text('${_cacheStats?.fileCount ?? 0} files'),
          ),
          ListTile(
            title: Text('Cache Size'),
            subtitle: Text('${_cacheStats?.totalSizeMB.toStringAsFixed(2) ?? 0} MB'),
          ),
          ListTile(
            title: Text('Clear Cache'),
            trailing: ElevatedButton(
              onPressed: _clearCache,
              child: Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Automatic Retry Mechanism

The package includes an automatic retry system that handles network failures gracefully:

```dart
_pdfManager.show(
  context: context,
  pdfUrl: 'https://example.com/document.pdf',
  options: const FloatingPdfViewerOptions(
    title: 'PDF with Retry',
    maxRetries: 5, // Will retry up to 5 times
    retryDelay: Duration(seconds: 3), // Wait 3 seconds between retries
  ),
);
```

### How Retry Works

1. **Automatic**: If download fails, automatically retries
2. **Configurable**: Set `maxRetries` and `retryDelay` in options
3. **Silent**: Retries happen in background without user intervention
4. **Progressive**: Shows error only after all retries are exhausted

### Retry Best Practices

```dart
// Fast retry for good connections
const FloatingPdfViewerOptions(
  maxRetries: 3,
  retryDelay: Duration(milliseconds: 500),
)

// Patient retry for slow/unstable connections
const FloatingPdfViewerOptions(
  maxRetries: 5,
  retryDelay: Duration(seconds: 3),
)

// No retry (immediate failure)
const FloatingPdfViewerOptions(
  maxRetries: 0,
)
```

## Advanced Examples

### PDF with Custom Settings

```dart
_pdfManager.show(
  context: context,
  pdfUrl: 'https://www.example.com/document.pdf',
  options: const FloatingPdfViewerOptions(
    title: 'Monthly Report',
    headerColor: Colors.indigo,
    initialLeft: 200,
    initialTop: 100,
    initialWidth: 450,
    initialHeight: 650,
    minWidth: 350,
    maxWidth: 700,
    minHeight: 400,
    maxHeight: 900,
  ),
);
```

### Multiple PDFs

```dart
class _MyPageState extends State<MyPage> {
  final FloatingPdfViewerManager _pdfManager1 = FloatingPdfViewerManager();
  final FloatingPdfViewerManager _pdfManager2 = FloatingPdfViewerManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _pdfManager1.show(
              context: context,
              pdfUrl: 'https://example.com/doc1.pdf',
              options: const FloatingPdfViewerOptions(
                title: 'Document 1',
                headerColor: Colors.blue,
              ),
            ),
            child: Text('Open PDF 1'),
          ),
          ElevatedButton(
            onPressed: () => _pdfManager2.show(
              context: context,
              pdfUrl: 'https://example.com/doc2.pdf',
              options: const FloatingPdfViewerOptions(
                title: 'Document 2',
                headerColor: Colors.red,
                initialLeft: 300,
              ),
            ),
            child: Text('Open PDF 2'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfManager1.dispose();
    _pdfManager2.dispose();
    super.dispose();
  }
}
```

### Using copyWith for Option Modification

The `FloatingPdfViewerOptions` class includes a convenient `copyWith` method for modifying existing configurations:

```dart
// Base configuration
const baseOptions = FloatingPdfViewerOptions(
  title: 'Base Document',
  headerColor: Colors.blue,
  initialWidth: 400,
  initialHeight: 500,
);

// Create modified version
final customOptions = baseOptions.copyWith(
  title: 'Modified Document',
  headerColor: Colors.red,
  initialLeft: 150,
  // All other properties remain the same
);

_pdfManager.show(
  context: context,
  pdfUrl: 'https://example.com/document.pdf',
  options: customOptions,
);
```

### Predefined Option Sets

You can create predefined option sets for consistent styling:

```dart
class PdfStyles {
  static const FloatingPdfViewerOptions compact = FloatingPdfViewerOptions(
    initialWidth: 300,
    initialHeight: 400,
    maxWidth: 500,
    maxHeight: 600,
  );

  static const FloatingPdfViewerOptions large = FloatingPdfViewerOptions(
    initialWidth: 500,
    initialHeight: 700,
    maxWidth: 800,
    maxHeight: 1000,
  );

  static const FloatingPdfViewerOptions darkTheme = FloatingPdfViewerOptions(
    headerColor: Colors.grey[800],
    title: 'Document',
  );
}

// Usage
_pdfManager.show(
  context: context,
  pdfUrl: 'https://example.com/small-doc.pdf',
  options: PdfStyles.compact.copyWith(title: 'Small Document'),
);
```

## Breaking Changes in v0.1.0

**⚠️ BREAKING CHANGE**: The API has been redesigned for better maintainability and cleaner code.

### Migration from v0.0.x

**Old API (v0.0.x):**

```dart
_pdfManager.show(
  context: context,
  pdfUrl: 'url',
  title: 'Document',
  headerColor: Colors.blue,
  initialLeft: 100,
  initialTop: 150,
  // ... many individual parameters
);
```

**New API (v0.1.0+):**

```dart
_pdfManager.show(
  context: context,
  pdfUrl: 'url',
  options: const FloatingPdfViewerOptions(
    title: 'Document',
    headerColor: Colors.blue,
    initialLeft: 100,
    initialTop: 150,
    // all options grouped together
  ),
);
```

### Benefits of the New API

- ✅ **Cleaner constructor**: One `options` parameter instead of 10+ individual parameters
- ✅ **Better maintainability**: Easier to add new configuration options
- ✅ **Immutable configuration**: `FloatingPdfViewerOptions` is immutable and includes `copyWith()`
- ✅ **Type safety**: Better IDE support and error detection
- ✅ **Flutter patterns**: Follows conventions used by `TextStyle`, `ButtonStyle`, etc.

## Package Structure

The package is now organized following Flutter best practices:

```
lib/
├── floating_pdf_viewer.dart            # 📦 Main export file
└── src/
    ├── options.dart                    # ⚙️  FloatingPdfViewerOptions
    ├── manager.dart                    # 🎛️  FloatingPdfViewerManager
    ├── floating_pdf_viewer_widget.dart # 🪟 Main FloatingPdfViewer widget
    ├── pdf_downloader.dart             # 📥 PDF download with cache support
    ├── pdf_cache_manager.dart          # 💾 Cache management system
    └── internal_widgets.dart           # 🔧 Internal widgets (not exported)
```

- **Clean API**: Only public classes are exported from the main file
- **Organized code**: Each class has its own focused file
- **Maintainable**: Internal widgets are separated and not exposed
- **Best practices**: Follows Flutter package structure conventions
- **Modular**: Cache and download logic separated for easy testing

## Requirements

- Flutter SDK: `>=1.17.0`
- Dart SDK: `^3.8.1`

## Dependencies

- `flutter`: Flutter SDK
- `pdfx`: `^2.9.2` for PDF rendering
- `http`: `^1.2.0` for downloading PDFs
- `path_provider`: `^2.1.5` for cache directory access
- `crypto`: `^3.0.6` for cache key generation

## Compatibility

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Limitations

- Requires internet connection for initial PDF download (cached PDFs work offline)
- PDFs must be publicly accessible via URL
- Native PDF rendering using pdfx (platform-specific limitations may apply)

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
