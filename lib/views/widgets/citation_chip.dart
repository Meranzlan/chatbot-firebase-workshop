import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/chat_citation.dart';
import '../../utils/open_link.dart';
import 'toast.dart';

/// A small numbered pill under a bot reply, showing one web page it used.
/// Tapping it opens the page in the browser.
class CitationChip extends StatelessWidget {
  const CitationChip({super.key, required this.number, required this.citation});

  final int number;
  final ChatCitation citation;

  Future<void> _open(BuildContext context) async {
    if (await openLink(citation.url)) return;
    if (context.mounted) showToast(context, 'Could not open ${citation.title}');
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.webCitation;
    final title = citation.title.length > 28
        ? '${citation.title.substring(0, 28)}…'
        : citation.title;

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 9,
                backgroundColor: color,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new_rounded,
                size: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
