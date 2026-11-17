import 'package:flutter/material.dart';
import '../../services/tutorial_service.dart';
import '../../utils/tutorial_strings.dart';

class WelcomeTourDialog extends StatelessWidget {
  final String language;

  const WelcomeTourDialog({
    Key? key,
    required this.language,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required String language}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WelcomeTourDialog(language: language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = TutorialStrings.getWelcomeTitle(language);
    final desc = TutorialStrings.getWelcomeDesc(language);
    final startLabel = TutorialStrings.getStartTourLabel(language);
    final notNowLabel = TutorialStrings.getNotNowLabel(language);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header icon and title
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 28,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Simple AAC Sri Lanka',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),

          // 3 Feature Highlights
          _buildFeatureRow(
            icon: Icons.record_voice_over_rounded,
            iconColor: const Color(0xFF1976D2),
            title: 'Communicate with Picture Cards',
            subtitle: 'Tap cards to speak instantly in English, Sinhala, or Tamil.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.add_photo_alternate_rounded,
            iconColor: const Color(0xFF2E7D32),
            title: 'Create Your Own Cards',
            subtitle: 'Add photos from camera, gallery, or smart search with custom voice.',
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.offline_bolt_rounded,
            iconColor: const Color(0xFFE65100),
            title: 'Privacy-Focused',
            subtitle:
                'Core card communication works offline.\nSmart Image Search uses the internet.',
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    TutorialService.instance.skipTour();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    notNowLabel,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    TutorialService.instance.startTour();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    startLabel,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
