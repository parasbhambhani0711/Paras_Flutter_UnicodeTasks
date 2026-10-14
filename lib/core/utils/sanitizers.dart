String sanitizeAiResponse(String rawText) {
  if (rawText.isEmpty) return rawText;

  String text = rawText;

  text = text.replaceAllMapped(
    RegExp(r'\\?\$\{([^}]*)\}\\?\$?'),
    (match) => '\$${match.group(1) ?? ''}\$',
  );

  text = text.replaceAllMapped(
    RegExp(r'(?<!\$)\$([^\$\n]+?)\$(?!\$)'),
    (match) {
      final content = match.group(1) ?? '';
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(content.trim())) {
        return 'USD ${content.trim()}';
      }
      return '\\(${content.trim()}\\)';
    },
  );

  final lines = text.split('\n');
  final StringBuffer buffer = StringBuffer();
  bool inDisplayMath = false;

  for (int i = 0; i < lines.length; i++) {
    String line = lines[i];

    int doubleDollarCount = 0;
    for (int j = 0; j < line.length - 1; j++) {
      if (line[j] == '\$' &&
          line[j + 1] == '\$' &&
          (j == 0 || line[j - 1] != '\\')) {
        doubleDollarCount++;
        j++;
      }
    }

    if (doubleDollarCount % 2 != 0) {
      inDisplayMath = !inDisplayMath;
    }

    if (inDisplayMath && line.trimLeft().startsWith('#')) {
      buffer.writeln('\$\$');
      inDisplayMath = false;
    }

    buffer.writeln(line);
  }

  if (inDisplayMath) {
    buffer.writeln('\$\$');
  }

  return buffer.toString().trimRight();
}

String sanitizeMathText(String rawText) {
  if (rawText.isEmpty) return rawText;
  String text = rawText;

  text = text.replaceAllMapped(
    RegExp(r'\\?\$\{([^}]*)\}\\?\$?'),
    (match) => '\$${match.group(1) ?? ''}\$',
  );

  text = text.replaceAllMapped(
    RegExp(r'(?<!\$)\$([^\$\n]+?)\$(?!\$)'),
    (match) {
      final content = match.group(1) ?? '';
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(content.trim())) {
        return 'USD ${content.trim()}';
      }
      return '\\(${content.trim()}\\)';
    },
  );

  return text;
}
