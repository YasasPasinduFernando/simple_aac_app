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
    final buttonColor = baseColor.withOpacity(0.9);

    return Container(
      color: baseColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _EditBarButton(
            icon: Icons.check,
            label: 'Done',
            onTap: onDone,
            color: buttonColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Edit Words',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _EditBarButton(
            icon: Icons.undo,
            label: 'Undo',
            onTap: onUndo,
            color: buttonColor,
          ),
          const SizedBox(width: 6),
          _EditBarButton(
            icon: Icons.add,
            label: 'Add New',
            onTap: onAdd,
            color: buttonColor,
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
  final Color color;

  const _EditBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
