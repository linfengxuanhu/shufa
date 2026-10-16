
import 'dart:math' as math;

import 'package:flutter/material.dart';
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

enum PracticeMode {
  tracing,
  copying,
  dictation,
}

enum GridType {
  square,
  tian,
  mi,
}

enum FontStyleChoice {
  kai,
  song,
  hei,
}

extension PracticeModeText on PracticeMode {
  String get label {
    switch (this) {
      case PracticeMode.tracing:
        return '描红';
      case PracticeMode.copying:
        return '临摹';
      case PracticeMode.dictation:
        return '默写';
    }
  }
}

extension GridTypeText on GridType {
  String get label {
    switch (this) {
      case GridType.square:
        return '方格';
      case GridType.tian:
        return '田字格';
      case GridType.mi:
        return '米字格';
    }
  }
}

extension FontStyleText on FontStyleChoice {
  String get label {
    switch (this) {
      case FontStyleChoice.kai:
        return '楷体';
      case FontStyleChoice.song:
        return '宋体';
      case FontStyleChoice.hei:
        return '黑体';
    }
  }

  String get family {
    switch (this) {
      case FontStyleChoice.kai:
        return 'KaiTi';
      case FontStyleChoice.song:
        return 'SimSun';
      case FontStyleChoice.hei:
        return 'SimHei';
    }
  }
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
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE9E0D5)),
          ),
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

  Set<String> favorites = {};
  bool favoritesOnly = false;
  bool loadingFavorites = true;

  List<String> get categories {
    final values = poems.map((p) => p.category).toSet().toList()..sort();
    return ['全部', ...values];
  }

  List<Poem> get filteredPoems {
    final query = searchController.text.trim().toLowerCase();

    return poems.where((poem) {
      final matchesCategory = selectedCategory == '全部' ||
          poem.category == selectedCategory;

      final matchesFavorite =
          !favoritesOnly || favorites.contains(poem.title);

      final searchable =
          '${poem.title} ${poem.author} ${poem.category} ${poem.lines.join()}'
              .toLowerCase();

      final matchesSearch = query.isEmpty || searchable.contains(query);

      return matchesCategory && matchesFavorite && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    selectedPoem = poems.isEmpty ? null : poems.first;
    searchController.addListener(_handleSearch);
    _loadFavorites();
  }

  void _handleSearch() {
    setState(() {
      final available = filteredPoems;
      if (selectedPoem != null &&
          !available.any((p) => p.title == selectedPoem!.title)) {
        selectedPoem = available.isEmpty ? null : available.first;
      } else if (selectedPoem == null && available.isNotEmpty) {
        selectedPoem = available.first;
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      favorites = (prefs.getStringList('shufa_favorites') ?? []).toSet();
      loadingFavorites = false;

      final available = filteredPoems;
      if (selectedPoem == null && available.isNotEmpty) {
        selectedPoem = available.first;
      }
    });
  }

  Future<void> _toggleFavorite(Poem poem) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favorites.contains(poem.title)) {
        favorites.remove(poem.title);
      } else {
        favorites.add(poem.title);
      }
    });

    await prefs.setStringList('shufa_favorites', favorites.toList());

    if (!mounted) return;

    if (favoritesOnly && !favorites.contains(poem.title)) {
      final available = filteredPoems;
      setState(() {
        selectedPoem = available.isEmpty ? null : available.first;
      });
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_handleSearch);
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
                final available = filteredPoems;
                if (selectedPoem != null &&
                    !available.any((p) => p.title == selectedPoem!.title)) {
                  selectedPoem =
                      available.isEmpty ? null : available.first;
                }
              });
            },
            icon: Icon(
              favoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: favoritesOnly ? Colors.redAccent : ink,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  _buildIntro(),
                  const SizedBox(height: 16),
                  _buildPoemSelector(available),
                  const SizedBox(height: 16),
                  _buildSettings(),
                  const SizedBox(height: 16),
                  _buildPreview(),
                  const SizedBox(height: 12),
                  _buildTips(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF1E4D3), Color(0xFFFFF9F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            '选择喜欢的诗词，自定义字体、格子和练习方式，生成可打印的练字纸。',
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: Color(0xFF6D6258),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoemSelector(List<Poem> available) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              number: '01',
              title: '选择诗词',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜索诗名、作者或诗句',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '诗词分类',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedCategory = value;
                  final available = filteredPoems;
                  if (selectedPoem == null ||
                      !available.any(
                        (p) => p.title == selectedPoem!.title,
                      )) {
                    selectedPoem =
                        available.isEmpty ? null : available.first;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            if (loadingFavorites)
              const LinearProgressIndicator()
            else if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text('没有找到符合条件的诗词'),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: available.any(
                  (p) => p.title == selectedPoem?.title,
                )
                    ? selectedPoem!.title
                    : available.first.title,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '选择作品',
                  border: OutlineInputBorder(),
                ),
                items: available
                    .map(
                      (poem) => DropdownMenuItem(
                        value: poem.title,
                        child: Text(
                          '${poem.title} · ${poem.author}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPoem = available.firstWhere(
                      (p) => p.title == value,
                    );
                  });
                },
              ),
            if (selectedPoem != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedPoem!.category,
                      style: const TextStyle(
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _toggleFavorite(selectedPoem!),
                    icon: Icon(
                      favorites.contains(selectedPoem!.title)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                    ),
                    label: Text(
                      favorites.contains(selectedPoem!.title)
                          ? '已收藏'
                          : '收藏诗词',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(number: '02', title: '练习设置'),
            const SizedBox(height: 14),
            const Text(
              '练习方式',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
            const SizedBox(height: 16),
            const Text(
              '格子样式',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
            const SizedBox(height: 16),
            const Text(
              '字体风格',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: FontStyleChoice.values.map((item) {
                return ChoiceChip(
                  label: Text(item.label),
                  selected: fontStyle == item,
                  onSelected: (_) => setState(() => fontStyle = item),
                );
              }).toList(),
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Expanded(child: Text('每个字重复次数')),
                IconButton(
                  onPressed: repeatCount > 1
                      ? () => setState(() => repeatCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$repeatCount 次',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: repeatCount < 6
                      ? () => setState(() => repeatCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('格子大小')),
                Text('${cellSize.round()} pt'),
              ],
            ),
            Slider(
              value: cellSize,
              min: 28,
              max: 56,
              divisions: 7,
              label: '${cellSize.round()}',
              onChanged: (value) {
                setState(() => cellSize = value);
              },
            ),
            const Divider(height: 24),
            _SwitchLine(
              title: '显示诗词标题',
              value: showTitle,
              onChanged: (value) => setState(() => showTitle = value),
            ),
            _SwitchLine(
              title: '显示作者',
              value: showAuthor,
              onChanged: (value) => setState(() => showAuthor = value),
            ),
            _SwitchLine(
              title: '显示原诗文字',
              subtitle: '关闭后可制作纯格子练习纸',
              value: showOriginal,
              onChanged: (value) => setState(() => showOriginal = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final poem = selectedPoem;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(number: '03', title: '练习页预览'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE6E1DA)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: poem == null
                  ? const Center(child: Text('请先选择诗词'))
                  : Column(
                      children: [
                        if (showTitle)
                          Text(
                            poem.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontStyle.family,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        if (showAuthor) ...[
                          const SizedBox(height: 5),
                          Text(
                            poem.author,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        if (showTitle || showAuthor)
                          const SizedBox(height: 18),
                        if (showOriginal)
                          ...poem.lines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                line,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: fontStyle.family,
                                  fontSize: 14,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildPreviewGrid(poem),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              '预览用于查看版式。实际打印请以导出的 PDF 为准。',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewGrid(Poem poem) {
    final characters = poem.lines.join().runes
        .map(String.fromCharCode)
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final displayed = <String>[];
    for (final char in characters.take(12)) {
      for (int i = 0; i < repeatCount; i++) {
        displayed.add(char);
      }
    }

    final width = math.min(cellSize, 48.0);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 0,
      runSpacing: 0,
      children: displayed.map((char) {
        final showChar = mode != PracticeMode.dictation;
        final tracing = mode == PracticeMode.tracing;

        return SizedBox(
          width: width,
          height: width,
          child: CustomPaint(
            painter: PracticeGridPainter(gridType),
            child: Center(
              child: showChar
                  ? Text(
                      char,
                      style: TextStyle(
                        fontFamily: fontStyle.family,
                        fontSize: width * 0.7,
                        color: tracing
                            ? const Color(0x558B5E3C)
                            : ink,
                      ),
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EADF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: accent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '小提示：描红适合初学，临摹适合熟悉字形，默写适合检查记忆。导出 PDF 后可以在 A4 纸上打印。',
              style: TextStyle(fontSize: 12, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: paper,
        border: Border(
          top: BorderSide(color: Color(0xFFE9E0D5)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: selectedPoem == null ? null : _exportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text(
            '生成并打印练习纸 PDF',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final poem = selectedPoem;
    if (poem == null) return;

    try {
      final pdf = pw.Document();

      final pw.Font regular;
      final pw.Font bold;

      if (fontStyle == FontStyleChoice.song) {
        regular = await PdfGoogleFonts.notoSerifSCRegular();
      } else {
        regular = await PdfGoogleFonts.notoSansSCRegular();
      }
      bold = await PdfGoogleFonts.notoSansSCBold();

      final characters = poem.lines
          .join()
          .runes
          .map(String.fromCharCode)
          .where((s) => s.trim().isNotEmpty)
          .toList();

      final cells = <String>[];
      for (final char in characters) {
        for (int i = 0; i < repeatCount; i++) {
          cells.add(char);
        }
      }

      const int columns = 10;
      final double pdfCellSize =
          (cellSize * 0.75).clamp(24.0, 42.0).toDouble();

      final rows = <List<String>>[];
      for (int i = 0; i < cells.length; i += columns) {
        final end = math.min(i + columns, cells.length);
        rows.add(cells.sublist(i, end));
      }

      final usableWidth = PdfPageFormat.a4.width - 64;
      final actualCellSize =
          math.min(pdfCellSize, usableWidth / columns);

      final gridRows = <pw.Widget>[];

      for (final row in rows) {
        gridRows.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: row.map((char) {
              return pw.SizedBox(
                width: actualCellSize,
                height: actualCellSize,
                child: pw.Stack(
                  children: [
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey600,
                          width: 0.5,
                        ),
                      ),
                    ),
                    if (gridType != GridType.square)
                      pw.Positioned(
                        left: actualCellSize / 2,
                        top: 0,
                        bottom: 0,
                        child: pw.Container(
                          width: 0.4,
                          color: PdfColors.grey400,
                        ),
                      ),
                    if (gridType != GridType.square)
                      pw.Positioned(
                        top: actualCellSize / 2,
                        left: 0,
                        right: 0,
                        child: pw.Container(
                          height: 0.4,
                          color: PdfColors.grey400,
                        ),
                      ),
                    if (gridType == GridType.mi)
                      pw.CustomPaint(
                        size: PdfPoint(actualCellSize, actualCellSize),
                        painter: (canvas, size) {
                          canvas
                            ..setStrokeColor(PdfColors.grey400)
                            ..setLineWidth(0.4)
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
                            font: regular,
                            fontSize: actualCellSize * 0.68,
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
        gridRows.add(pw.SizedBox(height: 3));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
          theme: pw.ThemeData.withFont(
            base: regular,
            bold: bold,
          ),
          build: (context) {
            return [
              if (showTitle)
                pw.Center(
                  child: pw.Text(
                    poem.title,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              if (showAuthor) ...[
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    poem.author,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
              if (showTitle || showAuthor)
                pw.SizedBox(height: 16),
              if (showOriginal)
                ...poem.lines.map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Center(
                      child: pw.Text(
                        line,
                        style: pw.TextStyle(
                          font: regular,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (showOriginal)
                pw.SizedBox(height: 14),
              ...gridRows,
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
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

class _SectionHeading extends StatelessWidget {
  final String number;
  final String title;

  const _SectionHeading({
    required this.number,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E3D4),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
      ],
    );
  }
}

class _SwitchLine extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchLine({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(fontSize: 11),
            ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: accent,
    );
  }
}

class PracticeGridPainter extends CustomPainter {
  final GridType type;

  PracticeGridPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFB9B3AB)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final guidePaint = Paint()
      ..color = const Color(0xFFCEC7BD)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    if (type == GridType.tian || type == GridType.mi) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guidePaint,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guidePaint,
      );
    }

    if (type == GridType.mi) {
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width, size.height),
        guidePaint,
      );
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PracticeGridPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
