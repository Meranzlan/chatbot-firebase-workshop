import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import 'bot_avatar.dart';

/// Top bar: bot name, what powers it, and the "New conversation" button.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key, required this.botName, required this.onRestart});

  final String botName;

  /// Null while the bot is replying, which disables the button.
  final VoidCallback? onRestart;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          const BotAvatar(size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                botName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                AppConfig.poweredBy,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'New conversation',
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: onRestart,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
