import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

/// Shows Gemini's reply with its Markdown tidied up: `## headings` and
/// `**bold**` turn bold, `*italic*` turns italic, `` `code` `` gets a code
/// font, `* ` or `- ` list items become bullets (•), and source numbers
/// like [1] are coloured like the citation chips.
/// You don't need to read this file to follow the chatbot flow.
class FormattedText extends StatelessWidget {
  const FormattedText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  static final _heading = RegExp(r'^#{1,6}\s+');
  static final _bullet = RegExp(r'^(\s*)[*-]\s+');

  // Found left to right, so a `code` span is taken whole and any * inside it
  // stays as typed. **bold** is tried before *italic*.
  static final _markup = RegExp(
    r'`([^`]+)`|\*\*(.+?)\*\*|\*(.+?)\*|(\[\d+\])',
  );

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      var lineStyle = style;
      if (_heading.hasMatch(line)) {
        line = line.replaceFirst(_heading, '');
        lineStyle = style.copyWith(fontWeight: FontWeight.bold);
      } else {
        line = line.replaceFirstMapped(_bullet, (m) => '${m[1]}• ');
      }

      spans.addAll(_styledPieces(line, lineStyle));
      if (i < lines.length - 1) spans.add(TextSpan(text: '\n', style: style));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  /// Splits one line into plain, `code`, **bold** and *italic* pieces.
  List<TextSpan> _styledPieces(String line, TextStyle lineStyle) {
    final pieces = <TextSpan>[];
    int start = 0;

    for (final match in _markup.allMatches(line)) {
      if (match.start > start) {
        pieces.add(
          TextSpan(text: line.substring(start, match.start), style: lineStyle),
        );
      }
      pieces.add(_styledPiece(match, lineStyle));
      start = match.end;
    }

    if (start < line.length) {
      pieces.add(TextSpan(text: line.substring(start), style: lineStyle));
    }
    return pieces;
  }

  TextSpan _styledPiece(Match match, TextStyle lineStyle) {
    if (match[1] != null) {
      return TextSpan(
        text: match[1],
        style: lineStyle.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Courier'], // iOS
          backgroundColor: AppColors.codeBackground,
        ),
      );
    }
    if (match[2] != null) {
      return TextSpan(
        text: match[2],
        style: lineStyle.copyWith(fontWeight: FontWeight.bold),
      );
    }
    if (match[4] != null) {
      return TextSpan(
        text: match[4],
        style: lineStyle.copyWith(
          color: AppColors.webCitation,
          fontWeight: FontWeight.w600,
          fontSize: (lineStyle.fontSize ?? 14) * 0.85,
        ),
      );
    }
    return TextSpan(
      text: match[3],
      style: lineStyle.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
