import 'package:flutter/material.dart';

class EditModeBar extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onUndo;
  final VoidCallback onAdd;
  final Color baseColor;
  final Color textColor;

  const EditModeBar({
    Key? key,
    required this.onDone,
    required this.onUndo,
    required this.onAdd,
    required this.baseColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonBg = textColor.withValues(alpha: 0.16);
    final borderColor = textColor.withValues(alpha: 0.22);

    return Container(
      color: baseColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _EditBarButton(
            icon: Icons.check_rounded,
            label: 'Done',
            onTap: onDone,
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Edit Words',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _EditBarButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: onUndo,
            backgroundColor: buttonBg,
            foregroundColor: textColor,
            borderColor: borderColor,
          ),
          const SizedBox(width: 6),
          _EditBarButton(
            icon: Icons.add_rounded,
            label: 'Add New',
            onTap: onAdd,
            backgroundColor: buttonBg,
            foregroundColor: textColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}

class _EditBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _EditBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: foregroundColor),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
