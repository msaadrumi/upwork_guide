import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const DocxViewerApp());
}

class DocxViewerApp extends StatelessWidget {
  const DocxViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const DocxViewerScreen(),
    );
  }
}

class DocxViewerScreen extends StatefulWidget {
  const DocxViewerScreen({super.key});

  @override
  State<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends State<DocxViewerScreen> {
  List<DocxParagraph>? _paragraphs;
  bool _loading = true;
  String? _error;

  static const _nsW =
      'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final bytes = await rootBundle.load('assets/upwork_app.docx');
      final archive = ZipDecoder().decodeBytes(bytes.buffer.asUint8List());

      final file = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
      );
      final xmlString = String.fromCharCodes(file.content);
      final doc = XmlDocument.parse(xmlString);

      final styleNames = <String, String>{};
      try {
        final stylesFile = archive.files.firstWhere(
          (f) => f.name == 'word/styles.xml',
        );
        final stylesDoc =
            XmlDocument.parse(String.fromCharCodes(stylesFile.content));
        for (final style
            in stylesDoc.findAllElements('style', namespace: _nsW)) {
          final id = style.getAttribute('styleId');
          final nameEl =
              style.findElements('name', namespace: _nsW).firstOrNull;
          final name = nameEl?.getAttribute('val');
          if (id != null && name != null) {
            styleNames[id] = name;
          }
        }
      } catch (_) {}

      final paragraphs = <DocxParagraph>[];
      for (final p in doc.findAllElements('p', namespace: _nsW)) {
        final ppr = p.findElements('pPr', namespace: _nsW).firstOrNull;
        final pStyleEl =
            ppr?.findElements('pStyle', namespace: _nsW).firstOrNull;
        final styleId = pStyleEl?.getAttribute('val');

        final runs = <DocxRun>[];
        for (final r in p.findElements('r', namespace: _nsW)) {
          final rpr = r.findElements('rPr', namespace: _nsW).firstOrNull;
          final boldEl =
              rpr?.findElements('b', namespace: _nsW).firstOrNull;
          final bold = boldEl != null && boldEl.getAttribute('val') != '0';
          final italicEl =
              rpr?.findElements('i', namespace: _nsW).firstOrNull;
          final italic =
              italicEl != null && italicEl.getAttribute('val') != '0';
          final texts = <String>[];
          for (final t in r.findElements('t', namespace: _nsW)) {
            if (t.innerText.isNotEmpty) texts.add(t.innerText);
          }
          if (texts.isNotEmpty) {
            runs.add(DocxRun(
              text: texts.join(),
              bold: bold,
              italic: italic,
            ));
          }
        }

        if (runs.isNotEmpty) {
          paragraphs.add(DocxParagraph(
            runs: runs,
            resolvedStyle: styleId != null ? styleNames[styleId] : null,
          ));
        }
      }

      setState(() {
        _paragraphs = paragraphs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Document'),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $_error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  itemCount: _paragraphs!.length,
                  itemBuilder: (context, index) =>
                      _buildParagraph(_paragraphs![index]),
                ),
    );
  }

  Widget _buildParagraph(DocxParagraph para) {
    if (para.runs.isEmpty) return const SizedBox(height: 6);

    final styleName = para.resolvedStyle ?? '';
    final isTitle = styleName == 'Title';
    final isHeading = styleName.startsWith('Heading');
    final headingLevel =
        isHeading ? int.tryParse(styleName.substring(7)) ?? 1 : 0;

    if (isTitle) {
      return Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Text(
          para.runs.map((r) => r.text).join(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
      );
    }

    if (isHeading) {
      final sizes = [22.0, 18.0, 16.0, 15.0, 14.0];
      return Padding(
        padding: EdgeInsets.only(
            top: headingLevel <= 1 ? 24 : 16, bottom: 8),
        child: Text(
          para.runs.map((r) => r.text).join(),
          style: TextStyle(
            fontSize:
                sizes[(headingLevel - 1).clamp(0, sizes.length - 1)],
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      );
    }

    final text = para.runs.map((r) => r.text).join();
    final isTocEntry = text.contains('…') || text.contains('\t');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: isTocEntry ? 14 : 15,
            color: Colors.grey[900],
            height: 1.6,
          ),
          children: para.runs.map((run) {
            return TextSpan(
              text: run.text,
              style: TextStyle(
                fontWeight: run.bold ? FontWeight.bold : null,
                fontStyle: run.italic ? FontStyle.italic : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DocxParagraph {
  final List<DocxRun> runs;
  final String? resolvedStyle;

  DocxParagraph({required this.runs, this.resolvedStyle});
}

class DocxRun {
  final String text;
  final bool bold;
  final bool italic;

  DocxRun({required this.text, this.bold = false, this.italic = false});
}
