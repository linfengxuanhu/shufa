import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShufaApp());
}

class Poem {
  final String title;
  final String author;
  final String dynasty;
  final List<String> lines;
  const Poem(this.title, this.author, this.dynasty, this.lines);

  String get content => lines.join('\n');
}

const poems = <Poem>[
  Poem('静夜思', '李白', '唐', ['床前明月光', '疑是地上霜', '举头望明月', '低头思故乡']),
  Poem('春晓', '孟浩然', '唐', ['春眠不觉晓', '处处闻啼鸟', '夜来风雨声', '花落知多少']),
  Poem('悯农（其二）', '李绅', '唐', ['锄禾日当午', '汗滴禾下土', '谁知盘中餐', '粒粒皆辛苦']),
  Poem('登鹳雀楼', '王之涣', '唐', ['白日依山尽', '黄河入海流', '欲穷千里目', '更上一层楼']),
  Poem('咏鹅', '骆宾王', '唐', ['鹅鹅鹅', '曲项向天歌', '白毛浮绿水', '红掌拨清波']),
  Poem('江雪', '柳宗元', '唐', ['千山鸟飞绝', '万径人踪灭', '孤舟蓑笠翁', '独钓寒江雪']),
  Poem('寻隐者不遇', '贾岛', '唐', ['松下问童子', '言师采药去', '只在此山中', '云深不知处']),
  Poem('赋得古原草送别（节选）', '白居易', '唐', ['离离原上草', '一岁一枯荣', '野火烧不尽', '春风吹又生']),
  Poem('悯农（其一）', '李绅', '唐', ['春种一粒粟', '秋收万颗子', '四海无闲田', '农夫犹饿死']),
  Poem('早发白帝城', '李白', '唐', ['朝辞白帝彩云间', '千里江陵一日还', '两岸猿声啼不住', '轻舟已过万重山']),
  Poem('望庐山瀑布', '李白', '唐', ['日照香炉生紫烟', '遥看瀑布挂前川', '飞流直下三千尺', '疑是银河落九天']),
  Poem('绝句', '杜甫', '唐', ['两个黄鹂鸣翠柳', '一行白鹭上青天', '窗含西岭千秋雪', '门泊东吴万里船']),
];

enum PracticeMode { tracing, copy, mixed }

class ShufaApp extends StatelessWidget {
  const ShufaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF76553B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '书法字帖',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
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
  Poem selected = poems.first;
  PracticeMode mode = PracticeMode.mixed;
  int repeatPerLine = 3;
  bool showTitle = true;
  bool showAuthor = true;
  bool showGridDiagonals = true;
  bool includePoemText = true;
  bool busy = false;

  String get modeLabel => switch (mode) {
    PracticeMode.tracing => '描红练习',
    PracticeMode.copy => '临摹练习',
    PracticeMode.mixed => '范字 + 描红 + 临摹',
  };

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    // PDF base fonts do not reliably contain Chinese glyphs on every platform.
    // Printing.layoutPdf runs in Flutter's platform printing pipeline; this
    // first version uses PDF built-in fonts, so preview text may depend on
    // device support. A bundled CJK font can be added in a later revision.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 30),
        build: (context) {
          final widgets = <pw.Widget>[];
          if (showTitle) {
            widgets.add(pw.Center(
              child: pw.Text(selected.title,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ));
            widgets.add(pw.SizedBox(height: 5));
          }
          if (showAuthor) {
            widgets.add(pw.Center(
              child: pw.Text('${selected.dynasty} · ${selected.author}',
                  style: const pw.TextStyle(fontSize: 10)),
            ));
            widgets.add(pw.SizedBox(height: 12));
          }
          if (includePoemText) {
            widgets.add(pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
              ),
              child: pw.Text(selected.content,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 13, lineSpacing: 4)),
            ));
            widgets.add(pw.SizedBox(height: 14));
          }

          for (final line in selected.lines) {
            final chars = line.split('');
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  for (final ch in chars)
                    for (int n = 0; n < repeatPerLine; n++)
                      _pdfCell(ch, n == 0, mode),
                ],
              ),
            ));
          }
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('练习提示：先观察范字的结构，再按笔顺认真书写。',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)));
          return widgets;
        },
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfCell(String ch, bool first, PracticeMode mode) {
    const size = 36.0;
    final isModel = first && mode != PracticeMode.tracing;
    final isTrace = !first || mode == PracticeMode.tracing;
    return pw.Container(
      width: size,
      height: size,
      margin: const pw.EdgeInsets.symmetric(horizontal: 1),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
      ),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (showGridDiagonals)
            pw.CustomPaint(
              size: const PdfPoint(size, size),
              painter: (canvas, size) {
                canvas
                  ..setStrokeColor(PdfColors.grey300)
                  ..setLineWidth(0.35)
                  ..drawLine(0, size.y / 2, size.x, size.y / 2)
                  ..drawLine(size.x / 2, 0, size.x / 2, size.y)
                  ..drawLine(0, 0, size.x, size.y)
                  ..drawLine(0, size.y, size.x, 0)
                  ..strokePath();
              },
            ),
          if (isModel)
            pw.Text(ch, style: const pw.TextStyle(fontSize: 24))
          else if (isTrace)
            pw.Text(ch, style: pw.TextStyle(fontSize: 24, color: PdfColors.grey400))
          else
            pw.SizedBox(),
        ],
      ),
    );
  }

  Future<void> _previewAndPrint() async {
    setState(() => busy = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '书法字帖_${selected.title}.pdf',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成 PDF 失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => busy = true);
    try {
      final bytes = await _buildPdf();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: '书法字帖_${selected.title}.pdf',
            ),
          ],
          text: '书法字帖：${selected.title}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书法字帖'),
        actions: [
          IconButton(
            tooltip: '关于',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: '书法字帖',
              applicationVersion: '1.0.0',
              children: const [
                Text('选择古诗，生成 A4 练字字帖。'),
                Text('首版以硬笔楷书练习为目标。'),
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择古诗',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Poem>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '内置诗词',
                    ),
                    items: poems.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.title} · ${p.author}'),
                    )).toList(),
                    onChanged: (p) {
                      if (p != null) setState(() => selected = p);
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(selected.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${selected.dynasty} · ${selected.author}',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 10),
                        for (final line in selected.lines)
                          Text(line, style: const TextStyle(fontSize: 20, height: 1.6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('字帖设置',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('练习模式'),
                  const SizedBox(height: 6),
                  SegmentedButton<PracticeMode>(
                    segments: const [
                      ButtonSegment(value: PracticeMode.tracing, label: Text('描红')),
                      ButtonSegment(value: PracticeMode.copy, label: Text('临摹')),
                      ButtonSegment(value: PracticeMode.mixed, label: Text('混合')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setState(() => mode = s.first),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Text('每个诗句字符的格数')),
                      Text('$repeatPerLine 格'),
                    ],
                  ),
                  Slider(
                    value: repeatPerLine.toDouble(),
                    min: 2,
                    max: 5,
                    divisions: 3,
                    label: '$repeatPerLine',
                    onChanged: (v) => setState(() => repeatPerLine = v.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示诗题'),
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
                    title: const Text('田字格中显示辅助线'),
                    subtitle: const Text('中线与对角线，方便观察字形结构'),
                    value: showGridDiagonals,
                    onChanged: (v) => setState(() => showGridDiagonals = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示原诗'),
                    subtitle: const Text('关闭后只保留练字格'),
                    value: includePoemText,
                    onChanged: (v) => setState(() => includePoemText = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('练习预览',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('当前选择：${selected.title} · $modeLabel'),
                  const SizedBox(height: 8),
                  const Text(
                    '首版使用 A4 PDF 输出。由于尚未嵌入专用楷体字体，'
                    '不同设备的 PDF 中文字形可能存在差异；后续可加入合法授权的楷体字体文件。',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _previewAndPrint,
                      icon: busy
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_outlined),
                      label: Text(busy ? '正在生成…' : '预览 / 打印 PDF'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _sharePdf,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('分享 PDF 文件'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('书法字帖 · 第一版',
                style: TextStyle(color: Colors.black45, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
