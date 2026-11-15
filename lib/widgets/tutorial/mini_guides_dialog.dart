import 'package:flutter/material.dart';
import '../../utils/tutorial_strings.dart';

class MiniGuidesDialog extends StatelessWidget {
  final String language;

  const MiniGuidesDialog({
    Key? key,
    required this.language,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required String language}) {
    return showDialog(
      context: context,
      builder: (ctx) => MiniGuidesDialog(language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      TutorialStrings.getMiniGuidesTitle(language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Scrollable Guides List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                  children: [
                    _buildGuideCard(
                      icon: Icons.lock_outline_rounded,
                      color: const Color(0xFFD97706),
                      title: TutorialStrings.getPinGuideTitle(language),
                      desc: TutorialStrings.getPinGuideDesc(language),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideCard(
                      icon: Icons.backup_rounded,
                      color: const Color(0xFF2563EB),
                      title: TutorialStrings.getBackupGuideTitle(language),
                      desc: TutorialStrings.getBackupGuideDesc(language),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideCard(
                      icon: Icons.shield_outlined,
                      color: const Color(0xFF059669),
                      title: TutorialStrings.getPermissionsGuideTitle(language),
                      desc: TutorialStrings.getPermissionsGuideDesc(language),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideCard(
                      icon: Icons.wifi_find_rounded,
                      color: const Color(0xFF7C3AED),
                      title: TutorialStrings.getSmartSearchGuideTitle(language),
                      desc: TutorialStrings.getSmartSearchGuideDesc(language),
                    ),
                    const SizedBox(height: 12),
                    _buildGuideCard(
                      icon: Icons.gif_box_rounded,
                      color: const Color(0xFFDB2777),
                      title: TutorialStrings.getGifGuideTitle(language),
                      desc: TutorialStrings.getGifGuideDesc(language),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Close button
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  TutorialStrings.getFinishLabel(language),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
