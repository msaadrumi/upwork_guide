# Guide: Using `docx_file_viewer` in Flutter

Native, pure-Flutter-widget DOCX rendering — no WebView, no PDF conversion.

## 1. Install

Add to `pubspec.yaml`:

```yaml
dependencies:
  docx_file_viewer: ^1.0.1
  file_picker: ^8.0.0   # optional, only if you want users to pick files
```

```bash
flutter pub get
```

Supports iOS, Android, Web, macOS, Windows, and Linux.

## 2. Basic usage

```dart
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'dart:io';

// From a File
DocxView.file(myFile)

// From raw bytes (e.g. downloaded or generated)
DocxView.bytes(docxBytes)

// From a path string
DocxView.path('/path/to/document.docx')
```

Minimal screen:

```dart
import 'package:flutter/material.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'dart:io';

class DocxScreen extends StatelessWidget {
  final File file;
  const DocxScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document')),
      body: DocxView.file(file),
    );
  }
}
```

## 3. Letting the user pick a file (with `file_picker`)

```dart
import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<void> pickAndOpen(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['docx'],
  );
  if (result == null) return;

  final file = File(result.files.first.path!);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DocxScreen(file: file)),
  );
}
```

## 4. Configuration options

Pass a `DocxViewConfig` to control zoom, search, layout, and appearance:

```dart
DocxView(
  file: myFile,
  config: DocxViewConfig(
    enableSearch: true,
    enableZoom: true,
    enableSelection: true,
    minScale: 0.5,
    maxScale: 4.0,
    pageMode: DocxPageMode.paged,   // or DocxPageMode.continuous
    pageWidth: 794,                  // A4 width in px
    pageHeight: 1123,                // A4 height in px
    padding: const EdgeInsets.all(16),
    backgroundColor: Colors.white,
    showPageBreaks: true,
    theme: DocxViewTheme.light(),
  ),
)
```

| Option | Type | Default | Purpose |
|---|---|---|---|
| `enableSearch` | bool | true | Text search + highlighting |
| `enableZoom` | bool | true | Pinch-to-zoom |
| `enableSelection` | bool | true | Select/copy text |
| `pageMode` | enum | paged | `paged` (print layout) or `continuous` (scroll) |
| `theme` | `DocxViewTheme?` | light | Visual styling |
| `customFontFallbacks` | List\<String\> | Roboto/Arial/Helvetica | Font fallback chain |

## 5. Built-in search bar UI

For a ready-made search experience, use `DocxViewWithSearch` instead of `DocxView`:

```dart
Scaffold(
  body: DocxViewWithSearch(
    file: myDocxFile,
    config: DocxViewConfig(
      enableSearch: true,
      searchHighlightColor: Colors.yellow,
      currentSearchHighlightColor: Colors.orange,
    ),
  ),
)
```

## 6. Programmatic search control

For custom search UI, drive it yourself with `DocxSearchController`:

```dart
final searchController = DocxSearchController();

DocxView(
  file: myFile,
  searchController: searchController,
)

// Trigger actions
searchController.search('keyword');
searchController.nextMatch();
searchController.previousMatch();
searchController.clear();

// React to results
searchController.addListener(() {
  print('Found ${searchController.matchCount} matches');
  print('Current: ${searchController.currentMatchIndex + 1}');
});
```

## 7. Dark theme

```dart
DocxView(
  bytes: docxBytes,
  config: DocxViewConfig(
    theme: DocxViewTheme.dark(),
    backgroundColor: const Color(0xFF1E1E1E),
  ),
)
```

Custom theme:

```dart
DocxViewTheme(
  backgroundColor: Colors.white,
  defaultTextStyle: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
  headingStyles: {
    1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  },
  tableBorderColor: const Color(0xFFDDDDDD),
  linkStyle: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
)
```

## 8. Load/error callbacks

```dart
DocxView(
  file: myFile,
  onLoaded: () {
    print('Document loaded successfully');
  },
  onError: (error) {
    print('Failed to load document: $error');
  },
)
```

## 9. Creating a docx on the fly and viewing it immediately

The package pairs with `docx_creator` for generating documents in-app:

```dart
import 'package:docx_creator/docx_creator.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'dart:typed_data';

final doc = docx()
  .h1('My Document')
  .p('This is a paragraph with some text.')
  .table([
    ['Header 1', 'Header 2'],
    ['Cell 1', 'Cell 2'],
  ])
  .build();

final bytes = await DocxExporter().exportToBytes(doc);

DocxView.bytes(Uint8List.fromList(bytes));
```

## 10. What's supported

Full coverage of: bold/italic/underline/strikethrough, super/subscript, text and highlight colors, font families and sizes, headings H1–H6, alignment, line spacing, indentation, paragraph borders/shading, drop caps, bullet/numbered/nested lists, tables (merging, borders, shading, conditional formatting), inline and floating images, basic shapes, headers/footers, footnotes/endnotes, page and section breaks, hyperlinks, embedded font deobfuscation, and checkboxes. Bookmarks have partial support only.

## 11. Known limitations

- Complex/unsupported elements show as debug placeholders if `showDebugInfo: true` is set.
- Bookmark support is partial.
- As a relatively new and small package, expect occasional edge-case rendering bugs with very complex documents — test against your real-world docx files early.

## 12. Useful links

- Package: https://pub.dev/packages/docx_file_viewer
- Source: https://github.com/alihassan143/htmltopdfwidgets
- Issues: https://github.com/alihassan143/htmltopdfwidgets/issues
