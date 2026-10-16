import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'poems.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShufaApp());
}

const Color ink = Color(0xFF263238);
const Color accent = Color(0xFF8B5E3C);
const Color paper = Color(0xFFFFFCF7);

enum PracticeMode { tracing, copying, dictation }

enum GridType { square, tian, mi }

enum FontStyleChoice { kai, xingKai, xingShu, liShu, song, hei }

extension ModeInfo on PracticeMode {
  String get label => switch (this) {
        PracticeMode.tracing => '描红',
        PracticeMode.copying => '临摹',
        PracticeMode.dictation => '默写',
      };
}

extension GridInfo on GridType {
  String get label => switch (this) {
        GridType.square => '方格',
        GridType.tian => '田字格',
        GridType.mi => '米字格',
      };
}

extension FontInfo on FontStyleChoice {
  String get label => switch (this) {
        FontStyleChoice.kai => '楷体',
        FontStyleChoice.xingKai => '行楷',
        FontStyleChoice.xingShu => '行书',
        FontStyleChoice.liShu => '隶书',
        FontStyleChoice.song => '宋体',
        FontStyleChoice.hei => '黑体',
      };

  String get family => switch (this) {
        FontStyleChoice.kai => 'KaiTi',
        FontStyleChoice.xingKai => 'XingKai',
        FontStyleChoice.xingShu => 'XingShu',
        FontStyleChoice.liShu => 'LiShu',
        FontStyleChoice.song => 'SongTi',
        FontStyleChoice.hei => 'HeiTi',
      };

  String get assetPath => switch (this) {
        FontStyleChoice.kai => 'assets/fonts/KaiTi.ttf',
        FontStyleChoice.xingKai => 'assets/fonts/XingKai.ttf',
        FontStyleChoice.xingShu => 'assets/fonts/XingShu.ttf',
        FontStyleChoice.liShu => 'assets/fonts/LiShu.ttf',
        FontStyleChoice.song => 'assets/fonts/SongTi.ttf',
        FontStyleChoice.hei => 'assets/fonts/HeiTi.ttf',
      };
}

class ShufaApp extends StatelessWidget {
  const ShufaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '诗词书法练习',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          surface: paper,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
        ),
      ),
      home: const PracticeHomePage(),
    );
  }
}

class PracticeHomePage extends StatefulWidget {
  const PracticeHomePage({super.key});

  @override
  State<PracticeHomePage> createState() => _PracticeHomePageState();
}

class _PracticeHomePageState extends State<PracticeHomePage> {
  final TextEditingController searchController = TextEditingController();

  Poem? selectedPoem;
  String selectedCategory = '全部';
  PracticeMode mode = PracticeMode.tracing;
  GridType gridType = GridType.tian;
  FontStyleChoice fontStyle = FontStyleChoice.kai;

  int repeatCount = 2;
  double cellSize = 42;

  bool showTitle = true;
  bool showAuthor = true;
  bool showOriginal = true;
  bool favoritesOnly = false;
  Set<String> favorites = {};

  List<String> get categories {
    final result = poems.map((p) => p.category).toSet().toList()..sort();
    return ['全部', ...result];
  }

  List<Poem> get filteredPoems {
    final query = searchController.text.trim().toLowerCase();
    return poems.where((poem) {
      final categoryMatches =
          selectedCategory == '全部' || poem.category == selectedCategory;
      final favoriteMatches =
          !favoritesOnly || favorites.contains(poem.title);
      final text =
          '${poem.title} ${poem.author} ${poem.category} ${poem.lines.join()}'
              .toLowerCase();
      return categoryMatches &&
          favoriteMatches &&
          (query.isEmpty || text.contains(query));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    selectedPoem = poems.isEmpty ? null : poems.first;
    searchController.addListener(_onSearchChanged);
    _loadFavorites();
  }

  void _onSearchChanged() {
    final available = filteredPoems;
    setState(() {
      if (selectedPoem == null ||
          !available.any((p) => p.title == selectedPoem!.title)) {
        selectedPoem = available.isEmpty ? null : available.first;
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites = (prefs.getStringList('shufa_favorites') ?? []).toSet();
      final available = filteredPoems;
      if (selectedPoem == null && available.isNotEmpty) {
        selectedPoem = available.first;
      }
    });
  }

  Future<void> _toggleFavorite(Poem poem) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!favorites.add(poem.title)) {
        favorites.remove(poem.title);
      }
    });
    await prefs.setStringList('shufa_favorites', favorites.toList());

    if (!mounted) return;
    final available = filteredPoems;
    if (selectedPoem != null &&
        !available.any((p) => p.title == selectedPoem!.title)) {
      setState(() {
        selectedPoem = available.isEmpty ? null : available.first;
      });
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = filteredPoems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '诗词书法练习',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: favoritesOnly ? '显示全部诗词' : '只看收藏',
            onPressed: () {
              setState(() {
                favoritesOnly = !favoritesOnly;
                final list = filteredPoems;
                if (selectedPoem == null ||
                    !list.any((p) => p.title == selectedPoem!.title)) {
                  selectedPoem = list.isEmpty ? null : list.first;
                }
              });
            },
            icon: Icon(
              favoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: favoritesOnly ? Colors.red : ink,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _intro(),
                  const SizedBox(height: 14),
                  _poemSelector(available),
                  const SizedBox(height: 14),
                  _settings(),
                  const SizedBox(height: 14),
                  _preview(),
                  const SizedBox(height: 12),
                  const Text(
                    '提示：预览用于查看大致排版，打印效果以导出的 PDF 为准。',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE9E0D5)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: selectedPoem == null ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('生成并打印练习纸 PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF1E4D3), Color(0xFFFFF9F0)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '一诗一练，静心习字',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '自由选择诗词、字体和格子，制作可打印的练字纸。',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _poemSelector(List<Poem> available) {
    return _panel(
      title: '01  选择诗词',
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: '搜索诗名、作者或诗句',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: searchController.clear,
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: categories.contains(selectedCategory)
                ? selectedCategory
                : '全部',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '诗词分类',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedCategory = value;
                final list = filteredPoems;
                if (selectedPoem == null ||
                    !list.any((p) => p.title == selectedPoem!.title)) {
                  selectedPoem = list.isEmpty ? null : list.first;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('没有找到符合条件的诗词'),
            )
          else
            DropdownButtonFormField<String>(
              value: available.any((p) => p.title == selectedPoem?.title)
                  ? selectedPoem!.title
                  : available.first.title,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '选择作品',
                border: OutlineInputBorder(),
              ),
              items: available
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.title,
                      child: Text(
                        '${p.title} · ${p.author}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedPoem =
                      available.firstWhere((p) => p.title == value);
                });
              },
            ),
          if (selectedPoem != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedPoem!.category,
                    style: const TextStyle(color: accent, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _toggleFavorite(selectedPoem!),
                  icon: Icon(
                    favorites.contains(selectedPoem!.title)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  label: Text(
                    favorites.contains(selectedPoem!.title) ? '已收藏' : '收藏',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _settings() {
    return _panel(
      title: '02  练习设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('练习方式', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PracticeMode.values.map((item) {
              return ChoiceChip(
                label: Text(item.label),
                selected: mode == item,
                onSelected: (_) => setState(() => mode = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('格子样式', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GridType.values.map((item) {
              return ChoiceChip(
                label: Text(item.label),
                selected: gridType == item,
                onSelected: (_) => setState(() => gridType = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('字体选择', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FontStyleChoice.values.map((item) {
              return ChoiceChip(
                label: Text(item.label),
                selected: fontStyle == item,
                onSelected: (_) => setState(() => fontStyle = item),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F2EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '当前字体：${fontStyle.label}',
              style: TextStyle(
                fontFamily: fontStyle.family,
                fontSize: 22,
                color: ink,
              ),
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(child: Text('每字重复次数')),
              IconButton(
                onPressed: repeatCount > 1
                    ? () => setState(() => repeatCount--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$repeatCount 次'),
              IconButton(
                onPressed: repeatCount < 6
                    ? () => setState(() => repeatCount++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Text('格子大小')),
              Text('${cellSize.round()}'),
            ],
          ),
          Slider(
            value: cellSize,
            min: 28,
            max: 56,
            divisions: 7,
            onChanged: (v) => setState(() => cellSize = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('显示诗词标题'),
            value: showTitle,
            onChanged: (v) => setState(() => showTitle = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('显示作者'),
            value: showAuthor,
            onChanged: (v) => setState(() => showAuthor = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('显示原诗文字'),
            subtitle: const Text('关闭后生成纯格子练习纸'),
            value: showOriginal,
            onChanged: (v) => setState(() => showOriginal = v),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final poem = selectedPoem;
    return _panel(
      title: '03  练习页预览',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        color: Colors.white,
        child: poem == null
            ? const Text('请先选择诗词')
            : Column(
                children: [
                  if (showTitle)
                    Text(
                      poem.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: fontStyle.family,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (showAuthor)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 12),
                      child: Text(
                        poem.author,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  if (showOriginal)
                    ...poem.lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontStyle.family,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _previewGrid(poem),
                ],
              ),
      ),
    );
  }

  Widget _previewGrid(Poem poem) {
    final chars = poem.lines.join().runes
        .map(String.fromCharCode)
        .where((c) => c.trim().isNotEmpty)
        .take(12)
        .toList();

    final items = <String>[];
    for (final char in chars) {
      for (int i = 0; i < repeatCount; i++) {
        items.add(char);
      }
    }

    final side = math.min(cellSize, 48.0);
    return Wrap(
      alignment: WrapAlignment.center,
      children: items.map((char) {
        return SizedBox(
          width: side,
          height: side,
          child: CustomPaint(
            painter: PracticeGridPainter(gridType),
            child: Center(
              child: mode == PracticeMode.dictation
                  ? null
                  : Text(
                      char,
                      style: TextStyle(
                        fontFamily: fontStyle.family,
                        fontSize: side * 0.68,
                        color: mode == PracticeMode.tracing
                            ? const Color(0x668B5E3C)
                            : ink,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9E0D5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final poem = selectedPoem;
    if (poem == null) return;

    try {
      // 从项目 assets 读取真实字体文件，PDF 不再使用在线字体。
      final fontData = await rootBundle.load(fontStyle.assetPath);
      final selectedFont = pw.Font.ttf(fontData);

      final pdf = pw.Document();
      final characters = poem.lines
          .join()
          .runes
          .map(String.fromCharCode)
          .where((c) => c.trim().isNotEmpty)
          .toList();

      final cells = <String>[];
      for (final char in characters) {
        for (int i = 0; i < repeatCount; i++) {
          cells.add(char);
        }
      }

      const columns = 10;
      final rows = <List<String>>[];
      for (int i = 0; i < cells.length; i += columns) {
        final end = math.min(i + columns, cells.length);
        rows.add(cells.sublist(i, end));
      }

      const margin = 30.0;
      final availableWidth = PdfPageFormat.a4.width - margin * 2;
      final actualCell = math.min(
        (cellSize * 0.75).clamp(24.0, 42.0).toDouble(),
        availableWidth / columns,
      );

      final gridWidgets = <pw.Widget>[];
      for (final row in rows) {
        gridWidgets.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: row.map((char) {
              return pw.SizedBox(
                width: actualCell,
                height: actualCell,
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey600,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (gridType != GridType.square)
                      pw.Positioned(
                        left: actualCell / 2,
                        top: 0,
                        bottom: 0,
                        child: pw.Container(
                          width: 0.35,
                          color: PdfColors.grey400,
                        ),
                      ),
                    if (gridType != GridType.square)
                      pw.Positioned(
                        top: actualCell / 2,
                        left: 0,
                        right: 0,
                        child: pw.Container(
                          height: 0.35,
                          color: PdfColors.grey400,
                        ),
                      ),
                    if (gridType == GridType.mi)
                      pw.CustomPaint(
                        size: PdfPoint(actualCell, actualCell),
                        painter: (canvas, size) {
                          canvas
                            ..setStrokeColor(PdfColors.grey400)
                            ..setLineWidth(0.35)
                            ..moveTo(0, 0)
                            ..lineTo(size.x, size.y)
                            ..moveTo(size.x, 0)
                            ..lineTo(0, size.y)
                            ..strokePath();
                        },
                      ),
                    if (mode != PracticeMode.dictation)
                      pw.Center(
                        child: pw.Text(
                          char,
                          style: pw.TextStyle(
                            font: selectedFont,
                            fontSize: actualCell * 0.68,
                            color: mode == PracticeMode.tracing
                                ? PdfColors.grey400
                                : PdfColors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
        gridWidgets.add(pw.SizedBox(height: 3));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(
            margin,
            margin,
            margin,
            margin,
          ),
          theme: pw.ThemeData.withFont(base: selectedFont),
          build: (context) => [
            if (showTitle)
              pw.Center(
                child: pw.Text(
                  poem.title,
                  style: pw.TextStyle(font: selectedFont, fontSize: 20),
                ),
              ),
            if (showAuthor) ...[
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  poem.author,
                  style: pw.TextStyle(
                    font: selectedFont,
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
            if (showTitle || showAuthor) pw.SizedBox(height: 16),
            if (showOriginal)
              ...poem.lines.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Center(
                    child: pw.Text(
                      line,
                      style: pw.TextStyle(
                        font: selectedFont,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            if (showOriginal) pw.SizedBox(height: 14),
            ...gridWidgets,
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: '${poem.title}_书法练习.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成 PDF 失败：$e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}

class PracticeGridPainter extends CustomPainter {
  final GridType type;

  PracticeGridPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFFB9B3AB)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final guide = Paint()
      ..color = const Color(0xFFCEC7BD)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      border,
    );

    if (type != GridType.square) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guide,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guide,
      );
    }

    if (type == GridType.mi) {
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width, size.height),
        guide,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        guide,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PracticeGridPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
