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
    final chipColor = _chipColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(chipColor),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  source.filename,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _chipColor() {
    if (source.isImage) return Colors.orange;
    if (source.isVideo) return AppTheme.textSecondary;
    return AppTheme.textSecondary;
  }

  Widget _buildIcon(Color color) {
    IconData icon;

    if (source.isImage) {
      icon = Icons.image_outlined;
    } else if (source.isVideo) {
      icon = Icons.videocam_outlined;
    } else {
      icon = Icons.description_outlined;
    }

    return Icon(icon, size: 14, color: color);
  }
}
