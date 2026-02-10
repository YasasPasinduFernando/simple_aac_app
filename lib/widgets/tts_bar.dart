import 'dart:io';

import 'package:flutter/material.dart';

import '../models/tts_token.dart';

class TtsBar extends StatelessWidget {
  final List<TtsToken> tokens;
  final bool isTablet;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onSpeak;
  final Color? speakerColor;
  final double sizeFactor;
  final bool showActions;
  final bool showText;

  const TtsBar({
    Key? key,
    required this.tokens,
    required this.isTablet,
    required this.onDelete,
    required this.onClear,
    required this.onSpeak,
    this.speakerColor,
    this.sizeFactor = 1.0,
    this.showActions = true,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isTablet ? 16 : 12) * sizeFactor,
        vertical: (isTablet ? 10 : 8) * sizeFactor,
      ),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tokens.map((token) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * sizeFactor,
                        vertical: 1 * sizeFactor,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 26 * sizeFactor,
                              height: 26 * sizeFactor,
                              child: token.imagePath != null
                                  ? Image.file(
                                      File(token.imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.image,
                                            size: 16 * sizeFactor);
                                      },
                                    )
                                  : Icon(Icons.image, size: 16 * sizeFactor),
                            ),
                          ),
                          if (showText) ...[
                            SizedBox(width: 6 * sizeFactor),
                            Text(
                              token.label,
                              style: TextStyle(
                                fontSize: (isTablet ? 14 : 12) * sizeFactor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(width: 6 * sizeFactor),
          if (showActions)
            Row(
              children: [
                InkWell(
                  onTap: onDelete,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4 * sizeFactor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.backspace, size: 18 * sizeFactor),
                        SizedBox(height: 2 * sizeFactor),
                        Text(
                          'Delete',
                          style: TextStyle(fontSize: 9 * sizeFactor),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 2 * sizeFactor),
                InkWell(
                  onTap: onClear,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4 * sizeFactor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.clear, size: 18 * sizeFactor),
                        SizedBox(height: 2 * sizeFactor),
                        Text(
                          'Clear',
                          style: TextStyle(fontSize: 9 * sizeFactor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(width: 6 * sizeFactor),
          Container(
            decoration: BoxDecoration(
              color: speakerColor ?? Colors.brown.shade700,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.volume_up,
                  size: (isTablet ? 36 : 28) * sizeFactor),
              color: Colors.white,
              onPressed: onSpeak,
            ),
          ),
        ],
      ),
    );
  }
}
