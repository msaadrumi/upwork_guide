import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const DocxViewerApp());
}

class DocxViewerApp extends StatelessWidget {
  const DocxViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'upwork guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2d8c3c)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2d8c3c),
          brightness: Brightness.dark,
        ),
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
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final data = await rootBundle.load('assets/upwork_app.docx');
      setState(() {
        _bytes = data.buffer.asUint8List();
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
              : DocxViewWithSearch(
                  bytes: _bytes!,
                  config: const DocxViewConfig(enableSearch: true),
                ),
    );
  }
}
