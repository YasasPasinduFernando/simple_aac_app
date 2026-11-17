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
    final borderColor = textColor.withValues(alpha: 0.25);
    final cancelBg = textColor.withValues(alpha: 0.12);
    final cancelBorderColor = textColor.withValues(alpha: 0.35);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isSingleRow = constraints.maxWidth >= 360 && textScale <= 1.25;

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
          backgroundColor: const Color(0xFF43A047),
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

        if (isSingleRow) {
          // Single compact horizontal row matching the mockup layout
          return Container(
            color: baseColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                cancelButton,
                const SizedBox(width: 6),
                doneButton,
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Edit Words',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                undoButton,
                const SizedBox(width: 6),
                addButton,
              ],
            ),
          );
        }

        // Responsive layout for narrow screens or high text scaling:
        // Compact buttons, never oversized or full-width
        return Container(
          color: baseColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Edit Words',
                        maxLines: 1,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  undoButton,
                  const SizedBox(width: 6),
                  addButton,
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  cancelButton,
                  const SizedBox(width: 10),
                  doneButton,
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
    super.key,
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minWidth: 46, maxWidth: 72, minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(height: 1.5),
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
