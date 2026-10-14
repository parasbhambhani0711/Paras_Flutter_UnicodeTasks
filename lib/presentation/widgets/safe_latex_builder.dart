import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_math_fork/flutter_math.dart';
import '../../core/constants/app_theme.dart';

class SafeLatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String unicode = element.textContent;
    final bool isBlock = element.attributes['displayMode'] == 'true' ||
        element.attributes['mode'] == 'block';

    final mathWidget = Math.tex(
      unicode,
      textStyle: preferredStyle,
      mathStyle: isBlock ? MathStyle.display : MathStyle.text,
      onErrorFallback: (FlutterMathException e) {
        return SelectableText(
          unicode,
          style: preferredStyle?.copyWith(color: AppTheme.primaryNavy),
        );
      },
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: mathWidget,
      ),
    );
  }
}
