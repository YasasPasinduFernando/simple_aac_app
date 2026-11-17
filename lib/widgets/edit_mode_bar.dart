import 'package:flutter/material.dart';

class EditModeBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback onUndo;
  final VoidCallback onAdd;
  final Color baseColor;
  final Color textColor;
  final Key? cancelKey;
  final Key? doneKey;
  final Key? undoKey;
  final Key? addKey;

  const EditModeBar({
    Key? key,
    required this.onCancel,
    required this.onDone,
    required this.onUndo,
    required this.onAdd,
    required this.baseColor,
    required this.textColor,
    this.cancelKey,
    this.doneKey,
    this.undoKey,
    this.addKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonBg = textColor.withValues(alpha: 0.16);
    final borderColor = textColor.withValues(alpha: 0.24);
    final cancelBg = textColor.withValues(alpha: 0.08);
    final cancelBorderColor = textColor.withValues(alpha: 0.38);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 480;

        final cancelButton = _EditBarButton(
          key: cancelKey ?? const ValueKey('edit_mode_cancel_btn'),
          icon: Icons.close_rounded,
          label: 'Cancel',
          onTap: onCancel,
          backgroundColor: cancelBg,
          foregroundColor: textColor,
          borderColor: cancelBorderColor,
        );

        final doneButton = _EditBarButton(
          key: doneKey ?? const ValueKey('edit_mode_done_btn'),
          icon: Icons.check_rounded,
          label: 'Done',
          onTap: onDone,
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        );

        final undoButton = _EditBarButton(
          key: undoKey ?? const ValueKey('edit_mode_undo_btn'),
          icon: Icons.undo_rounded,
          label: 'Undo',
          onTap: onUndo,
          backgroundColor: buttonBg,
          foregroundColor: textColor,
          borderColor: borderColor,
        );

        final addButton = _EditBarButton(
          key: addKey ?? const ValueKey('edit_mode_add_btn'),
          icon: Icons.add_rounded,
          label: 'Add New',
          onTap: onAdd,
          backgroundColor: buttonBg,
          foregroundColor: textColor,
          borderColor: borderColor,
        );

        if (isWide) {
          // Single horizontal row for landscape/tablets
          return Container(
            color: baseColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                cancelButton,
                const SizedBox(width: 8),
                doneButton,
                const SizedBox(width: 10),
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
                const SizedBox(width: 10),
                undoButton,
                const SizedBox(width: 6),
                addButton,
              ],
            ),
          );
        }

        // Adaptive two-row toolbar for compact portrait screens
        return Container(
          color: baseColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Edit Mode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  undoButton,
                  const SizedBox(width: 6),
                  addButton,
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: cancelButton),
                  const SizedBox(width: 8),
                  Expanded(child: doneButton),
                ],
              ),
            ],
          ),
        );
      },
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
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null ? Border.all(color: borderColor!, width: 1.2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: foregroundColor),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
