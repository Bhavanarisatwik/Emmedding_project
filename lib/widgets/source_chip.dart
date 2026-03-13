import 'package:flutter/material.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class SourceChip extends StatelessWidget {
  final Source source;
  final VoidCallback? onTap;

  const SourceChip({
    super.key,
    required this.source,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.divider,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  source.filename,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${source.scorePercent}%',
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    if (source.isImage) {
      icon = Icons.image;
      color = Colors.orange;
    } else if (source.isVideo) {
      icon = Icons.videocam;
      color = Colors.purple;
    } else {
      icon = Icons.description;
      color = AppTheme.accentBlue;
    }

    return Icon(icon, size: 14, color: color);
  }
}
