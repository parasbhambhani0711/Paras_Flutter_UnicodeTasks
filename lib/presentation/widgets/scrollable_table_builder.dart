import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_math_fork/flutter_math.dart';
import '../../core/constants/app_theme.dart';

class ScrollableTableBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  ScrollableTableBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final List<TableRow> rows = [];

    for (var child in element.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          for (var tr in child.children ?? []) {
            if (tr is md.Element && tr.tag == 'tr') {
              rows.add(_buildRow(tr, preferredStyle));
            }
          }
        } else if (child.tag == 'tr') {
          rows.add(_buildRow(child, preferredStyle));
        }
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }

  TableRow _buildRow(md.Element tr, TextStyle? preferredStyle) {
    final List<Widget> cells = [];

    for (var td in tr.children ?? const []) {
      if (td is md.Element && (td.tag == 'td' || td.tag == 'th')) {
        final bool isHeader = td.tag == 'th';
        final String text = td.textContent;

        cells.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _buildCellContent(text, preferredStyle, isHeader),
          ),
        );
      }
    }

    final bool isHeaderRow = tr.children.any(
      (c) => c is md.Element && c.tag == 'th',
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isHeaderRow ? Colors.red.shade50 : null,
      ),
      children: cells,
    );
  }

  Widget _buildCellContent(
      String text, TextStyle? preferredStyle, bool isHeader) {
    final style = isHeader
        ? preferredStyle?.copyWith(
            fontWeight: FontWeight.bold, color: AppTheme.primaryNavy)
        : preferredStyle;

    final cleanText = text.trim();

    if (!cleanText.contains('\$')) {
      return Text(cleanText, style: style);
    }

    final List<InlineSpan> spans = [];
    final RegExp mathRegExp = RegExp(r'\$(.*?)\$');
    int lastEnd = 0;

    for (final match in mathRegExp.allMatches(cleanText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: cleanText.substring(lastEnd, match.start),
          style: style,
        ));
      }

      final formula = match.group(1)?.trim() ?? '';
      if (formula.isNotEmpty) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Math.tex(
              formula,
              textStyle: style,
              mathStyle: MathStyle.text,
              onErrorFallback: (_) => Text('\$$formula\$', style: style),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < cleanText.length) {
      spans.add(TextSpan(
        text: cleanText.substring(lastEnd),
        style: style,
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}

extension NodeListExt on List<md.Node>? {
  bool any(bool Function(md.Node c) test) {
    final list = this;
    if (list == null) return false;
    for (final node in list) {
      if (test(node)) return true;
    }
    return false;
  }
}
