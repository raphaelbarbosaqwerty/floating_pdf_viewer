import 'package:flutter/material.dart';

/// Configuration options for the FloatingPdfViewer widget.
///
/// This class groups all the customization options for the floating PDF viewer
/// in an immutable data class, following Flutter best practices.
class FloatingPdfViewerOptions {
  /// Initial position of the floating viewer (left offset)
  final double initialLeft;

  /// Initial position of the floating viewer (top offset)
  final double initialTop;

  /// Initial width of the floating viewer
  final double initialWidth;

  /// Initial height of the floating viewer
  final double initialHeight;

  /// Title displayed in the header bar
  final String? title;

  /// Color of the header bar
  final Color? headerColor;

  /// Minimum width for resizing
  final double minWidth;

  /// Minimum height for resizing
  final double minHeight;

  /// Maximum width for resizing
  final double maxWidth;

  /// Maximum height for resizing
  final double maxHeight;

  const FloatingPdfViewerOptions({
    this.initialLeft = 50.0,
    this.initialTop = 100.0,
    this.initialWidth = 360.0,
    this.initialHeight = 500.0,
    this.title,
    this.headerColor,
    this.minWidth = 320.0,
    this.minHeight = 250.0,
    this.maxWidth = 600.0,
    this.maxHeight = 800.0,
  });

  /// Creates a copy of this [FloatingPdfViewerOptions] with the given fields replaced with new values.
  FloatingPdfViewerOptions copyWith({
    double? initialLeft,
    double? initialTop,
    double? initialWidth,
    double? initialHeight,
    String? title,
    Color? headerColor,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
  }) {
    return FloatingPdfViewerOptions(
      initialLeft: initialLeft ?? this.initialLeft,
      initialTop: initialTop ?? this.initialTop,
      initialWidth: initialWidth ?? this.initialWidth,
      initialHeight: initialHeight ?? this.initialHeight,
      title: title ?? this.title,
      headerColor: headerColor ?? this.headerColor,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FloatingPdfViewerOptions &&
        other.initialLeft == initialLeft &&
        other.initialTop == initialTop &&
        other.initialWidth == initialWidth &&
        other.initialHeight == initialHeight &&
        other.title == title &&
        other.headerColor == headerColor &&
        other.minWidth == minWidth &&
        other.minHeight == minHeight &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      initialLeft,
      initialTop,
      initialWidth,
      initialHeight,
      title,
      headerColor,
      minWidth,
      minHeight,
      maxWidth,
      maxHeight,
    );
  }

  @override
  String toString() {
    return 'FloatingPdfViewerOptions('
        'initialLeft: $initialLeft, '
        'initialTop: $initialTop, '
        'initialWidth: $initialWidth, '
        'initialHeight: $initialHeight, '
        'title: $title, '
        'headerColor: $headerColor, '
        'minWidth: $minWidth, '
        'minHeight: $minHeight, '
        'maxWidth: $maxWidth, '
        'maxHeight: $maxHeight'
        ')';
  }
}
