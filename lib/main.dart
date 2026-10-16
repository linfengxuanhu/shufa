import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const ShufaApp());
}

const Color ink = Color(0xFF292821);
const Color paper = Color(0xFFFFFEFA);
const Color muted = Color(0xFF817F76);
const Color accent = Color(0xFF66745B);

class Poem {
  final String title;
  final String author;
  final String dynasty;
  final List<String> lines;

  const Poem(this.title, this.author, this.dynasty, this.lines);

  String get text => lines.join('\n');
}

const List<Poem> poems = [
  Poem('静夜思', '李白', '唐', [
    '床前明月光',
    '疑是地上霜',
    '举头望明月',
    '低头思故乡',
  ]),
  Poem('春晓', '孟浩然', '唐', [
    '春眠不觉晓',
    '处处闻啼鸟',
    '夜来风雨声',
    '花落知多少',
  ]),
  Poem('悯农（其二）', '李绅', '唐', [
    '锄禾日当午',
    '汗滴禾下土',
    '谁知盘中餐',
    '粒粒皆辛苦',
  ]),
  Poem('登鹳雀楼', '王之涣', '唐', [
    '白日依山尽',
    '黄河入海流',
    '欲穷千里目',
    '更上一层楼',
  ]),
  Poem('咏鹅', '骆宾王', '唐', [
    '鹅鹅鹅',
    '曲项向天歌',
    '白毛浮绿水',
    '红掌拨清波',
  ]),
  Poem('江雪', '柳宗元', '唐', [
    '千山鸟飞绝',
    '万径人踪灭',
    '孤舟蓑笠翁',
    '独钓寒江雪',
  ]),
  Poem('寻隐者不遇', '贾岛', '唐', [
    '松下问童子',
    '言师采药去',
    '只在此山中',
    '云深不知处',
  ]),
  Poem('早发白帝城', '李白', '唐', [
    '朝辞白帝彩云间',
    '千里江陵一日还',
    '两岸猿声啼不住',
    '轻舟已过万重山',
  ]),
  Poem('望庐山瀑布', '李白', '唐', [
    '日照香炉生紫烟',
    '遥看瀑布挂前川',
    '飞流直下三千尺',
    '疑是银河落九天',
  ]),
  Poem('绝句', '杜甫', '唐', [
    '两个黄鹂鸣翠柳',
    '一行白鹭上青天',
    '窗含西岭千秋雪',
    '门泊东吴万里船',
  ]),
  Poem('赋得古原草送别（节选）', '白居易', '唐', [
    '离离原上草',
    '一岁一枯荣',
    '野火烧不尽',
    '春风吹又生',
  ]),
  Poem('悯农（其一）', '李绅', '唐', [
    '春种一粒粟',
    '秋收万颗子',
    '四海无闲田',
    '农夫犹饿死',
  ]),
];

enum PracticeMode { tracing, copying, dictation }

enum GridType { square, tian, mi }

extension PracticeModeLabel on PracticeMode {
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

  String get description {
    switch (this) {
      case PracticeMode.tracing:
        return '浅灰范字，沿字练习';
      case PracticeMode.copying:
        return '先看范字，再独立书写';
      case PracticeMode.dictation:
        return '只留方格，检验记忆';
    }
  }
}

extension GridTypeLabel on GridType {
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

class ShufaApp extends StatelessWidget {
  const ShufaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '书法练习',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFEAE7DD)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPoem = 0;
  PracticeMode mode = PracticeMode.tracing;
  GridType gridType = GridType.tian;
  int repeatCount = 2;
  double cellSize = 40;
  bool showTitle = true;
  bool showAuthor = true;
  bool showPoemText = true;
  bool showHelperLines = true;
  bool busy = false;

  Poem get poem => poems[selectedPoem];

  String get fontFamily {
    // 将 KaiTi.ttf 放入 assets/fonts 并在 pubspec.yaml 注册后生效。
    return 'KaiTi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '书法练习',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            Text(
              '硬笔楷书 · 古诗字帖',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '关于',
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _buildIntro(),
            const SizedBox(height: 20),
            _sectionTitle('01', '选择古诗', '内置 ${poems.length} 首经典诗词'),
            const SizedBox(height: 10),
            _buildPoemSelector(),
            const SizedBox(height: 22),
            _sectionTitle('02', '练习方式', '按自己的书写阶段选择'),
            const SizedBox(height: 10),
            _buildModes(),
            const SizedBox(height: 22),
            _sectionTitle('03', '字帖设置', '调整练习纸的样式'),
            const SizedBox(height: 10),
            _buildSettings(),
            const SizedBox(height: 22),
            _sectionTitle('04', '页面预览', '预览所选古诗的练习效果'),
            const SizedBox(height: 10),
            _buildPreview(),
            const SizedBox(height: 20),
            _buildExportButton(),
            const SizedBox(height: 10),
            const Text(
              '提示：导出 PDF 时会优先读取项目内的 KaiTi.ttf 字体；'
              '若没有该文件，将尝试获取可显示中文的字体。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECEDE4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '一诗一字帖',
                  style: TextStyle(
                    color: ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '从描红到默写，慢慢写好每一个字。',
                  style: TextStyle(color: Color(0xFF62665B), height: 1.6),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'A4 打印 · PDF 导出',
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.edit_note, size: 76, color: accent),
        ],
      ),
    );
  }

  Widget _sectionTitle(String number, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE7E9DF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoemSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedPoem,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '选择一首古诗',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                poems.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(
                    '${poems[index].title} · ${poems[index].author}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value != null) setState(() => selectedPoem = value);
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (showTitle)
                    Text(
                      poem.title,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  if (showAuthor)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Text(
                        '〔${poem.dynasty}〕${poem.author}',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  for (final line in poem.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 17,
                          color: ink,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModes() {
    return Column(
      children: PracticeMode.values.map((item) {
        final selected = mode == item;
        final icon = switch (item) {
          PracticeMode.tracing => Icons.border_color_outlined,
          PracticeMode.copying => Icons.edit_outlined,
          PracticeMode.dictation => Icons.draw_outlined,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => setState(() => mode = item),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE9ECE2) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? accent : const Color(0xFFEAE7DD),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: selected ? accent : muted, size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: accent),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '练习格样式',
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GridType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: gridType == type,
                  onSelected: (_) => setState(() => gridType = type),
                );
              }).toList(),
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '每个字重复次数',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: repeatCount > 1
                      ? () => setState(() => repeatCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$repeatCount 次',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: repeatCount < 6
                      ? () => setState(() => repeatCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '格子大小',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${cellSize.round()} pt',
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
            Slider(
              value: cellSize,
              min: 28,
              max: 48,
              divisions: 10,
              label: '${cellSize.round()}',
              onChanged: (value) => setState(() => cellSize = value),
            ),
            const Divider(height: 24),
            _toggleRow('显示诗题', showTitle,
                (value) => setState(() => showTitle = value)),
            _toggleRow('显示作者', showAuthor,
                (value) => setState(() => showAuthor = value)),
            _toggleRow('显示诗句提示', showPoemText,
                (value) => setState(() => showPoemText = value)),
            _toggleRow('显示格子辅助线', showHelperLines,
                (value) => setState(() => showHelperLines = value)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: accent,
      onChanged: onChanged,
    );
  }

  Widget _buildPreview() {
    final maxLineLength = poem.lines
        .map((line) => line.runes.length)
        .fold<int>(0, math.max);
    final displayCells = math.min(maxLineLength * repeatCount, 8);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFC),
            border: Border.all(color: const Color(0xFFE3DFD3)),
          ),
          child: Column(
            children: [
              if (showTitle)
                Text(
                  poem.title,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 22,
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (showAuthor)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    '〔${poem.dynasty}〕${poem.author}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              for (final line in poem.lines) ...[
                if (showPoemText)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 5),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF5D5B53),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                _buildPreviewLine(line, displayCells),
              ],
              const SizedBox(height: 10),
              const Text(
                '书写贵在持之以恒',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB2AEA2),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewLine(String line, int maxCells) {
    final characters = <String>[];
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      for (var i = 0; i < repeatCount; i++) {
        characters.add(char);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: characters.map((char) {
          final isFirst = characters.indexOf(char) == 0;
          final showModel = mode == PracticeMode.tracing ||
              (mode == PracticeMode.copying && isFirst);

          return SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(
              painter: PracticeGridPainter(
                gridType: gridType,
                helperLines: showHelperLines,
              ),
              child: Center(
                child: Text(
                  mode == PracticeMode.dictation ? '' : char,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 21,
                    color: showModel
                        ? (mode == PracticeMode.tracing
                            ? const Color(0xFFB7B7B1)
                            : ink)
                        : const Color(0xFFDBD9D2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: busy ? null : _exportPdf,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          busy ? '正在生成字帖…' : '生成 A4 字帖 PDF',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<pw.Font> _loadPdfFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/KaiTi.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      // 未添加本地楷体时，尝试加载可显示中文的字体。
      return await PdfGoogleFonts.notoSansSCRegular();
    }
  }

  Future<void> _exportPdf() async {
    setState(() => busy = true);

    try {
      final font = await _loadPdfFont();
      final boldFont = await _loadBoldPdfFont();
      final document = pw.Document(
        title: '${poem.title} - 硬笔书法练习',
        author: '书法练习',
      );

      final regularTextStyle = pw.TextStyle(
        font: font,
        fontSize: 11,
        color: PdfColors.grey800,
      );

      final cellsPerRow = (500 / cellSize).floor().clamp(1, 12);

      final content = <pw.Widget>[];

      if (showTitle) {
        content.add(
          pw.Center(
            child: pw.Text(
              poem.title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 24,
                color: PdfColors.grey900,
              ),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 5));
      }

      if (showAuthor) {
        content.add(
          pw.Center(
            child: pw.Text(
              '〔${poem.dynasty}〕${poem.author}',
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 18));
      }

      for (final line in poem.lines) {
        if (showPoemText) {
          content.add(pw.Text(line, style: regularTextStyle));
          content.add(pw.SizedBox(height: 4));
        }

        final cells = <String>[];
        for (final rune in line.runes) {
          final char = String.fromCharCode(rune);
          for (var i = 0; i < repeatCount; i++) {
            cells.add(char);
          }
        }

        if (cells.isEmpty) continue;

        for (var start = 0; start < cells.length; start += cellsPerRow) {
          final end = math.min(start + cellsPerRow, cells.length);
          final rowCells = cells.sublist(start, end);

          content.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rowCells.length; i++)
                  pw.Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey500,
                        width: 0.55,
                      ),
                    ),
                    child: pw.Stack(
                      children: [
                        if (showHelperLines && gridType != GridType.square)
                          pw.Positioned.fill(
                            child: pw.CustomPaint(
                              painter: (canvas, size) {
                                final midX = size.x / 2;
                                final midY = size.y / 2;
                                canvas
                                  ..setStrokeColor(PdfColors.grey400)
                                  ..setLineWidth(0.35);

                                if (gridType == GridType.tian) {
                                  canvas
                                    ..drawLine(midX, 0, midX, size.y)
                                    ..drawLine(0, midY, size.x, midY);
                                } else {
                                  canvas
                                    ..drawLine(0, 0, size.x, size.y)
                                    ..drawLine(size.x, 0, 0, size.y)
                                    ..drawLine(midX, 0, midX, size.y)
                                    ..drawLine(0, midY, size.x, midY);
                                }

                                canvas.strokePath();
                              },
                            ),
                          ),
                        if (mode != PracticeMode.dictation)
                          pw.Center(
                            child: pw.Text(
                              rowCells[i],
                              style: pw.TextStyle(
                                font: font,
                                fontSize: cellSize * 0.57,
                                color: mode == PracticeMode.tracing
                                    ? PdfColors.grey400
                                    : PdfColors.grey900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
          content.add(pw.SizedBox(height: 3));
        }
        content.add(pw.SizedBox(height: 10));
      }

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(35, 35, 35, 35),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (_) => content,
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '书法练习 · ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ),
      );

      final bytes = await document.save();
      if (!mounted) return;

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: '${poem.title}_${mode.label}_字帖.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失败：$error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<pw.Font> _loadBoldPdfFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/KaiTi.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return await PdfGoogleFonts.notoSansSCRegular();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '书法练习',
      applicationVersion: '2.0',
      applicationLegalese: '硬笔楷书 · 古诗字帖 · A4 PDF',
      children: const [
        SizedBox(height: 12),
        Text('选择古诗、设置练习方式和格子样式，然后生成可打印的字帖。'),
      ],
    );
  }
}

class PracticeGridPainter extends CustomPainter {
  final GridType gridType;
  final bool helperLines;

  PracticeGridPainter({
    required this.gridType,
    required this.helperLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFAAA79C)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    final helperPaint = Paint()
      ..color = const Color(0xFFD5D1C6)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    if (!helperLines || gridType == GridType.square) return;

    final midX = size.width / 2;
    final midY = size.height / 2;

    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), helperPaint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), helperPaint);

    if (gridType == GridType.mi) {
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), helperPaint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        helperPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PracticeGridPainter oldDelegate) {
    return oldDelegate.gridType != gridType ||
        oldDelegate.helperLines != helperLines;
  }
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const ShufaApp());
}

const Color ink = Color(0xFF292821);
const Color paper = Color(0xFFFFFEFA);
const Color muted = Color(0xFF817F76);
const Color accent = Color(0xFF66745B);

class Poem {
  final String title;
  final String author;
  final String dynasty;
  final List<String> lines;

  const Poem(this.title, this.author, this.dynasty, this.lines);

  String get text => lines.join('\n');
}

const List<Poem> poems = [
  Poem('静夜思', '李白', '唐', [
    '床前明月光',
    '疑是地上霜',
    '举头望明月',
    '低头思故乡',
  ]),
  Poem('春晓', '孟浩然', '唐', [
    '春眠不觉晓',
    '处处闻啼鸟',
    '夜来风雨声',
    '花落知多少',
  ]),
  Poem('悯农（其二）', '李绅', '唐', [
    '锄禾日当午',
    '汗滴禾下土',
    '谁知盘中餐',
    '粒粒皆辛苦',
  ]),
  Poem('登鹳雀楼', '王之涣', '唐', [
    '白日依山尽',
    '黄河入海流',
    '欲穷千里目',
    '更上一层楼',
  ]),
  Poem('咏鹅', '骆宾王', '唐', [
    '鹅鹅鹅',
    '曲项向天歌',
    '白毛浮绿水',
    '红掌拨清波',
  ]),
  Poem('江雪', '柳宗元', '唐', [
    '千山鸟飞绝',
    '万径人踪灭',
    '孤舟蓑笠翁',
    '独钓寒江雪',
  ]),
  Poem('寻隐者不遇', '贾岛', '唐', [
    '松下问童子',
    '言师采药去',
    '只在此山中',
    '云深不知处',
  ]),
  Poem('早发白帝城', '李白', '唐', [
    '朝辞白帝彩云间',
    '千里江陵一日还',
    '两岸猿声啼不住',
    '轻舟已过万重山',
  ]),
  Poem('望庐山瀑布', '李白', '唐', [
    '日照香炉生紫烟',
    '遥看瀑布挂前川',
    '飞流直下三千尺',
    '疑是银河落九天',
  ]),
  Poem('绝句', '杜甫', '唐', [
    '两个黄鹂鸣翠柳',
    '一行白鹭上青天',
    '窗含西岭千秋雪',
    '门泊东吴万里船',
  ]),
  Poem('赋得古原草送别（节选）', '白居易', '唐', [
    '离离原上草',
    '一岁一枯荣',
    '野火烧不尽',
    '春风吹又生',
  ]),
  Poem('悯农（其一）', '李绅', '唐', [
    '春种一粒粟',
    '秋收万颗子',
    '四海无闲田',
    '农夫犹饿死',
  ]),
];

enum PracticeMode { tracing, copying, dictation }

enum GridType { square, tian, mi }

extension PracticeModeLabel on PracticeMode {
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

  String get description {
    switch (this) {
      case PracticeMode.tracing:
        return '浅灰范字，沿字练习';
      case PracticeMode.copying:
        return '先看范字，再独立书写';
      case PracticeMode.dictation:
        return '只留方格，检验记忆';
    }
  }
}

extension GridTypeLabel on GridType {
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

class ShufaApp extends StatelessWidget {
  const ShufaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '书法练习',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFEAE7DD)),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPoem = 0;
  PracticeMode mode = PracticeMode.tracing;
  GridType gridType = GridType.tian;
  int repeatCount = 2;
  double cellSize = 40;
  bool showTitle = true;
  bool showAuthor = true;
  bool showPoemText = true;
  bool showHelperLines = true;
  bool busy = false;

  Poem get poem => poems[selectedPoem];

  String get fontFamily {
    // 将 KaiTi.ttf 放入 assets/fonts 并在 pubspec.yaml 注册后生效。
    return 'KaiTi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '书法练习',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
            Text(
              '硬笔楷书 · 古诗字帖',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '关于',
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _buildIntro(),
            const SizedBox(height: 20),
            _sectionTitle('01', '选择古诗', '内置 ${poems.length} 首经典诗词'),
            const SizedBox(height: 10),
            _buildPoemSelector(),
            const SizedBox(height: 22),
            _sectionTitle('02', '练习方式', '按自己的书写阶段选择'),
            const SizedBox(height: 10),
            _buildModes(),
            const SizedBox(height: 22),
            _sectionTitle('03', '字帖设置', '调整练习纸的样式'),
            const SizedBox(height: 10),
            _buildSettings(),
            const SizedBox(height: 22),
            _sectionTitle('04', '页面预览', '预览所选古诗的练习效果'),
            const SizedBox(height: 10),
            _buildPreview(),
            const SizedBox(height: 20),
            _buildExportButton(),
            const SizedBox(height: 10),
            const Text(
              '提示：导出 PDF 时会优先读取项目内的 KaiTi.ttf 字体；'
              '若没有该文件，将尝试获取可显示中文的字体。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECEDE4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '一诗一字帖',
                  style: TextStyle(
                    color: ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '从描红到默写，慢慢写好每一个字。',
                  style: TextStyle(color: Color(0xFF62665B), height: 1.6),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'A4 打印 · PDF 导出',
                    style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.edit_note, size: 76, color: accent),
        ],
      ),
    );
  }

  Widget _sectionTitle(String number, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE7E9DF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoemSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedPoem,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '选择一首古诗',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                poems.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(
                    '${poems[index].title} · ${poems[index].author}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value != null) setState(() => selectedPoem = value);
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (showTitle)
                    Text(
                      poem.title,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  if (showAuthor)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Text(
                        '〔${poem.dynasty}〕${poem.author}',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                  for (final line in poem.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 17,
                          color: ink,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModes() {
    return Column(
      children: PracticeMode.values.map((item) {
        final selected = mode == item;
        final icon = switch (item) {
          PracticeMode.tracing => Icons.border_color_outlined,
          PracticeMode.copying => Icons.edit_outlined,
          PracticeMode.dictation => Icons.draw_outlined,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => setState(() => mode = item),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE9ECE2) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? accent : const Color(0xFFEAE7DD),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: selected ? accent : muted, size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: accent),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '练习格样式',
              style: TextStyle(fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GridType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: gridType == type,
                  onSelected: (_) => setState(() => gridType = type),
                );
              }).toList(),
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '每个字重复次数',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: repeatCount > 1
                      ? () => setState(() => repeatCount--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$repeatCount 次',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: repeatCount < 6
                      ? () => setState(() => repeatCount++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '格子大小',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${cellSize.round()} pt',
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
            Slider(
              value: cellSize,
              min: 28,
              max: 48,
              divisions: 10,
              label: '${cellSize.round()}',
              onChanged: (value) => setState(() => cellSize = value),
            ),
            const Divider(height: 24),
            _toggleRow('显示诗题', showTitle,
                (value) => setState(() => showTitle = value)),
            _toggleRow('显示作者', showAuthor,
                (value) => setState(() => showAuthor = value)),
            _toggleRow('显示诗句提示', showPoemText,
                (value) => setState(() => showPoemText = value)),
            _toggleRow('显示格子辅助线', showHelperLines,
                (value) => setState(() => showHelperLines = value)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: accent,
      onChanged: onChanged,
    );
  }

  Widget _buildPreview() {
    final maxLineLength = poem.lines
        .map((line) => line.runes.length)
        .fold<int>(0, math.max);
    final displayCells = math.min(maxLineLength * repeatCount, 8);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEFC),
            border: Border.all(color: const Color(0xFFE3DFD3)),
          ),
          child: Column(
            children: [
              if (showTitle)
                Text(
                  poem.title,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 22,
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (showAuthor)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    '〔${poem.dynasty}〕${poem.author}',
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ),
              for (final line in poem.lines) ...[
                if (showPoemText)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 5),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF5D5B53),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                _buildPreviewLine(line, displayCells),
              ],
              const SizedBox(height: 10),
              const Text(
                '书写贵在持之以恒',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB2AEA2),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewLine(String line, int maxCells) {
    final characters = <String>[];
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune);
      for (var i = 0; i < repeatCount; i++) {
        characters.add(char);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: characters.map((char) {
          final isFirst = characters.indexOf(char) == 0;
          final showModel = mode == PracticeMode.tracing ||
              (mode == PracticeMode.copying && isFirst);

          return SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(
              painter: PracticeGridPainter(
                gridType: gridType,
                helperLines: showHelperLines,
              ),
              child: Center(
                child: Text(
                  mode == PracticeMode.dictation ? '' : char,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 21,
                    color: showModel
                        ? (mode == PracticeMode.tracing
                            ? const Color(0xFFB7B7B1)
                            : ink)
                        : const Color(0xFFDBD9D2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: busy ? null : _exportPdf,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          busy ? '正在生成字帖…' : '生成 A4 字帖 PDF',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<pw.Font> _loadPdfFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/KaiTi.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      // 未添加本地楷体时，尝试加载可显示中文的字体。
      return await PdfGoogleFonts.notoSansSCRegular();
    }
  }

  Future<void> _exportPdf() async {
    setState(() => busy = true);

    try {
      final font = await _loadPdfFont();
      final boldFont = await _loadBoldPdfFont();
      final document = pw.Document(
        title: '${poem.title} - 硬笔书法练习',
        author: '书法练习',
      );

      final regularTextStyle = pw.TextStyle(
        font: font,
        fontSize: 11,
        color: PdfColors.grey800,
      );

      final cellsPerRow = (500 / cellSize).floor().clamp(1, 12);

      final content = <pw.Widget>[];

      if (showTitle) {
        content.add(
          pw.Center(
            child: pw.Text(
              poem.title,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 24,
                color: PdfColors.grey900,
              ),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 5));
      }

      if (showAuthor) {
        content.add(
          pw.Center(
            child: pw.Text(
              '〔${poem.dynasty}〕${poem.author}',
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 18));
      }

      for (final line in poem.lines) {
        if (showPoemText) {
          content.add(pw.Text(line, style: regularTextStyle));
          content.add(pw.SizedBox(height: 4));
        }

        final cells = <String>[];
        for (final rune in line.runes) {
          final char = String.fromCharCode(rune);
          for (var i = 0; i < repeatCount; i++) {
            cells.add(char);
          }
        }

        if (cells.isEmpty) continue;

        for (var start = 0; start < cells.length; start += cellsPerRow) {
          final end = math.min(start + cellsPerRow, cells.length);
          final rowCells = cells.sublist(start, end);

          content.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rowCells.length; i++)
                  pw.Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey500,
                        width: 0.55,
                      ),
                    ),
                    child: pw.Stack(
                      children: [
                        if (showHelperLines && gridType != GridType.square)
                          pw.Positioned.fill(
                            child: pw.CustomPaint(
                              painter: (canvas, size) {
                                final midX = size.x / 2;
                                final midY = size.y / 2;
                                canvas
                                  ..setStrokeColor(PdfColors.grey400)
                                  ..setLineWidth(0.35);

                                if (gridType == GridType.tian) {
                                  canvas
                                    ..drawLine(midX, 0, midX, size.y)
                                    ..drawLine(0, midY, size.x, midY);
                                } else {
                                  canvas
                                    ..drawLine(0, 0, size.x, size.y)
                                    ..drawLine(size.x, 0, 0, size.y)
                                    ..drawLine(midX, 0, midX, size.y)
                                    ..drawLine(0, midY, size.x, midY);
                                }

                                canvas.strokePath();
                              },
                            ),
                          ),
                        if (mode != PracticeMode.dictation)
                          pw.Center(
                            child: pw.Text(
                              rowCells[i],
                              style: pw.TextStyle(
                                font: font,
                                fontSize: cellSize * 0.57,
                                color: mode == PracticeMode.tracing
                                    ? PdfColors.grey400
                                    : PdfColors.grey900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
          content.add(pw.SizedBox(height: 3));
        }
        content.add(pw.SizedBox(height: 10));
      }

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(35, 35, 35, 35),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (_) => content,
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              '书法练习 · ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ),
      );

      final bytes = await document.save();
      if (!mounted) return;

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: '${poem.title}_${mode.label}_字帖.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成失败：$error'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<pw.Font> _loadBoldPdfFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/KaiTi.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return await PdfGoogleFonts.notoSansSCRegular();
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '书法练习',
      applicationVersion: '2.0',
      applicationLegalese: '硬笔楷书 · 古诗字帖 · A4 PDF',
      children: const [
        SizedBox(height: 12),
        Text('选择古诗、设置练习方式和格子样式，然后生成可打印的字帖。'),
      ],
    );
  }
}

class PracticeGridPainter extends CustomPainter {
  final GridType gridType;
  final bool helperLines;

  PracticeGridPainter({
    required this.gridType,
    required this.helperLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFAAA79C)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    final helperPaint = Paint()
      ..color = const Color(0xFFD5D1C6)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    if (!helperLines || gridType == GridType.square) return;

    final midX = size.width / 2;
    final midY = size.height / 2;

    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), helperPaint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), helperPaint);

    if (gridType == GridType.mi) {
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), helperPaint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        helperPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PracticeGridPainter oldDelegate) {
    return oldDelegate.gridType != gridType ||
        oldDelegate.helperLines != helperLines;
  }
}
