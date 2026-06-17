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

  // Search state
  final DocxSearchController _searchController = DocxSearchController();
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchTextController.clear();
        _searchFocusNode.unfocus();
      } else {
        // Focus the search field after animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _onSearchSubmitted(String value) {
    if (value.isNotEmpty) {
      _searchController.search(value);
    }
  }

  void _onSearchChanged(String value) {
    // Optional: debounce live search
    if (value.isNotEmpty) {
      _searchController.search(value);
    } else {
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Don't resize when keyboard appears - let the Stack handle it
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        // Allow content to extend to edges but respect system UI
        bottom: false,
        child: Column(
          children: [
            // Search bar
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _showSearch
                  ? _buildSearchBar()
                  : const SizedBox.shrink(),
            ),
            // Document viewer
            Expanded(
              child: _buildDocumentView(),
            ),
          ],
        ),
      ),
      floatingActionButton: !_showSearch
          ? FloatingActionButton.small(
              onPressed: _toggleSearch,
              tooltip: 'Search',
              child: const Icon(Icons.search),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          bottom: true,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchTextController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search document...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: _searchController.previousMatch,
                tooltip: 'Previous',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                onPressed: _searchController.nextMatch,
                tooltip: 'Next',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              // Match counter
              ListenableBuilder(
                listenable: _searchController,
                builder: (context, _) {
                  if (_searchController.matchCount > 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${_searchController.currentMatchIndex + 1}/${_searchController.matchCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _toggleSearch,
                tooltip: 'Close search',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading document',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Use continuous mode with responsive width instead of fixed paged mode
    return DocxView(
      bytes: _bytes!,
      config: const DocxViewConfig(
        enableSearch: true,
        enableZoom: true,
        pageMode: DocxPageMode.continuous,
        // No fixed pageWidth - lets content fill available width
        padding: EdgeInsets.all(16),
      ),
      searchController: _searchController,
    );
  }
}
