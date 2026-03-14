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
        borderRadius: BorderRadius.circular(12),
        splashColor: chipColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withOpacity(0.25),
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
                  style: TextStyle(
                    color: chipColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${source.scorePercent}%',
                style: TextStyle(
                  color: chipColor.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
    if (source.isVideo) return const Color(0xFFA855F7);
    return AppTheme.accentBlue;
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
