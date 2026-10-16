
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const ShufaApp());
}

const Color ink = Color(0xFF263238);
const Color accent = Color(0xFF8B5E3C);
const Color paper = Color(0xFFFFFCF5);

class Poem {
  final String title;
  final String author;
  final List<String> lines;

  const Poem(this.title, this.author, this.lines);
}

const List<Poem> poems = [
  Poem('静夜思', '李白', ['床前明月光', '疑是地上霜', '举头望明月', '低头思故乡']),
  Poem('春晓', '孟浩然', ['春眠不觉晓', '处处闻啼鸟', '夜来风雨声', '花落知多少']),
  Poem('悯农', '李绅', ['锄禾日当午', '汗滴禾下土', '谁知盘中餐', '粒粒皆辛苦']),
  Poem('登鹳雀楼', '王之涣', ['白日依山尽', '黄河入海流', '欲穷千里目', '更上一层楼']),
  Poem('咏鹅', '骆宾王', ['鹅鹅鹅', '曲项向天歌', '白毛浮绿水', '红掌拨清波']),
  Poem('悯农·其二', '李绅', ['春种一粒粟', '秋收万颗子', '四海无闲田', '农夫犹饿死']),
  Poem('江雪', '柳宗元', ['千山鸟飞绝', '万径人踪灭', '孤舟蓑笠翁', '独钓寒江雪']),
  Poem('赋得古原草送别', '白居易', ['离离原上草', '一岁一枯荣', '野火烧不尽', '春风吹又生']),
  Poem('寻隐者不遇', '贾岛', ['松下问童子', '言师采药去', '只在此山中', '云深不知处']),
  Poem('望庐山瀑布', '李白', ['日照香炉生紫烟', '遥看瀑布挂前川', '飞流直下三千尺', '疑是银河落九天']),
  Poem('清明', '杜牧', ['清明时节雨纷纷', '路上行人欲断魂', '借问酒家何处有', '牧童遥指杏花村']),
  Poem('早发白帝城', '李白', ['朝辞白帝彩云间', '千里江陵一日还', '两岸猿声啼不住', '轻舟已过万重山']),
];

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

  String get hint {
    switch (this) {
      case PracticeMode.tracing:
        return '浅灰色字迹可供描摹';
      case PracticeMode.copying:
        return '保留格线，自己书写';
      case PracticeMode.dictation:
        return '仅保留格线，独立默写';
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

class ShufaApp extends StatelessWidget {
  const ShufaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '书法练习',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        scaffoldBackgroundColor: paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
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
  Poem selectedPoem = poems.first;
  PracticeMode mode = PracticeMode.tracing;
  GridType gridType = GridType.tian;

  int repetitions = 2;
  double cellSize = 44;

  bool showTitle = true;
  bool showAuthor = true;
  bool showPoemText = true;

  Future<void> _exportPdf() async {
    try {
      final doc = pw.Document();

      final font = await PdfGoogleFonts.notoSansSCRegular();
      final boldFont = await PdfGoogleFonts.notoSansSCBold();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 30),
          build: (context) {
            return [
              if (showTitle)
                pw.Center(
                  child: pw.Text(
                    selectedPoem.title,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 22,
                    ),
                  ),
                ),
              if (showAuthor)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 5, bottom: 12),
                  child: pw.Center(
                    child: pw.Text(
                      '作者：${selectedPoem.author}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (showPoemText)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: pw.Center(
                    child: pw.Text(
                      selectedPoem.lines.join('　'),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              pw.Text(
                '${mode.label}练习    ${gridType.label}    每字重复 $repetitions 次',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                ),
              ),
              pw.SizedBox(height: 10),
              for (final line in selectedPoem.lines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: List.generate(
                      line.length * repetitions,
                      (index) {
                        final char = line[index % line.length];

                        return _pdfCell(
                          char,
                          font,
                          cellSize,
                          gridType,
                          mode,
                        );
                      },
                    ),
                  ),
                ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: '书法练习_${selectedPoem.title}.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  pw.Widget _pdfCell(
    String char,
    pw.Font font,
    double size,
    GridType type,
    PracticeMode practiceMode,
  ) {
    final double s = size.clamp(26.0, 54.0);

    return pw.Container(
      width: s,
      height: s,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey600,
          width: 0.55,
        ),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.CustomPaint(
              painter: (canvas, box) {
                // PdfPoint 的 x、y 分别表示绘制区域的宽、高。
                final double w = box.x;
                final double h = box.y;

                canvas.setStrokeColor(PdfColors.grey400);
                canvas.setLineWidth(0.45);

                if (type == GridType.tian || type == GridType.mi) {
                  canvas.drawLine(0, h / 2, w, h / 2);
                  canvas.drawLine(w / 2, 0, w / 2, h);
                }

                if (type == GridType.mi) {
                  canvas.drawLine(0, 0, w, h);
                  canvas.drawLine(w, 0, 0, h);
                }
              },
            ),
          ),
          if (practiceMode != PracticeMode.dictation)
            pw.Center(
              child: pw.Text(
                char,
                style: pw.TextStyle(
                  font: font,
                  fontSize: s * 0.65,
                  color: practiceMode == PracticeMode.tracing
                      ? PdfColors.grey400
                      : PdfColors.grey900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书法练习'),
        actions: [
          IconButton(
            tooltip: '导出 PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _sectionTitle('选择诗词', Icons.menu_book_outlined),
            DropdownButtonFormField<Poem>(
              initialValue: selectedPoem,
              isExpanded: true,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              items: poems.map((poem) {
                return DropdownMenuItem<Poem>(
                  value: poem,
                  child: Text('${poem.title} · ${poem.author}'),
                );
              }).toList(),
              onChanged: (poem) {
                if (poem != null) {
                  setState(() => selectedPoem = poem);
                }
              },
            ),
            const SizedBox(height: 18),

            _sectionTitle('练习方式', Icons.edit_outlined),
            SegmentedButton<PracticeMode>(
              segments: PracticeMode.values.map((m) {
                return ButtonSegment<PracticeMode>(
                  value: m,
                  label: Text(m.label),
                );
              }).toList(),
              selected: {mode},
              onSelectionChanged: (values) {
                setState(() => mode = values.first);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                mode.hint,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 18),

            _sectionTitle('格子样式', Icons.grid_4x4),
            SegmentedButton<GridType>(
              segments: GridType.values.map((g) {
                return ButtonSegment<GridType>(
                  value: g,
                  label: Text(g.label),
                );
              }).toList(),
              selected: {gridType},
              onSelectionChanged: (values) {
                setState(() => gridType = values.first);
              },
            ),
            const SizedBox(height: 16),

            _sectionTitle('练习页面设置', Icons.tune),
            _settingRow(
              '每个字重复次数',
              Text('$repetitions 次'),
              Slider(
                value: repetitions.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$repetitions 次',
                onChanged: (value) {
                  setState(() => repetitions = value.round());
                },
              ),
            ),
            _settingRow(
              '格子大小',
              Text('${cellSize.round()}'),
              Slider(
                value: cellSize,
                min: 30,
                max: 54,
                divisions: 8,
                onChanged: (value) {
                  setState(() => cellSize = value);
                },
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('显示诗词标题'),
              value: showTitle,
              activeThumbColor: accent,
              onChanged: (value) {
                setState(() => showTitle = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('显示作者'),
              value: showAuthor,
              activeThumbColor: accent,
              onChanged: (value) {
                setState(() => showAuthor = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('显示原诗'),
              value: showPoemText,
              activeThumbColor: accent,
              onChanged: (value) {
                setState(() => showPoemText = value);
              },
            ),
            const SizedBox(height: 10),

            _sectionTitle('页面预览', Icons.visibility_outlined),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE7DFD2),
                ),
              ),
              child: Column(
                children: [
                  if (showTitle)
                    Text(
                      selectedPoem.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (showAuthor)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        selectedPoem.author,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  if (showPoemText)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        selectedPoem.lines.join('　'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.8,
                        ),
                      ),
                    ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${mode.label} · ${gridType.label}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final line in selectedPoem.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: List.generate(
                          line.length * repetitions,
                          (index) {
                            return _previewCell(
                              line[index % line.length],
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.download_outlined),
              label: const Text('导出 / 分享 PDF 练习页'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '导出后可以保存 PDF，或发送到打印机。预览用于查看排版，实际打印效果以 PDF 为准。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
    String title,
    Widget trailing,
    Widget control,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            trailing,
          ],
        ),
        control,
      ],
    );
  }

  Widget _previewCell(String char) {
    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: CustomPaint(
        painter: GridPainter(gridType),
        child: Center(
          child: mode == PracticeMode.dictation
              ? const SizedBox.shrink()
              : Text(
                  char,
                  style: TextStyle(
                    fontSize: cellSize * 0.62,
                    color: mode == PracticeMode.tracing
                        ? Colors.grey.shade400
                        : ink,
                    fontFamily: 'KaiTi',
                  ),
                ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final GridType type;

  GridPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final border = Paint()
      ..color = const Color(0xFF8C8C8C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final guide = Paint()
      ..color = const Color(0xFFCEBEB0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawRect(rect, border);

    if (type == GridType.tian || type == GridType.mi) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guide,
      );
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guide,
      );
    }

    if (type == GridType.mi) {
      canvas.drawLine(
        Offset.zero,
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
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
