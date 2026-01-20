import 'dart:io';

import 'package:flutter/material.dart';

import '../models/tts_token.dart';

class TtsBar extends StatelessWidget {
  final List<TtsToken> tokens;
  final bool isTablet;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onSpeak;

  const TtsBar({
    Key? key,
    required this.tokens,
    required this.isTablet,
    required this.onDelete,
    required this.onClear,
    required this.onSpeak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 10 : 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              width: 26,
                              height: 26,
                              child: token.imagePath != null
                                  ? Image.file(
                                      File(token.imagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.image, size: 16);
                                      },
                                    )
                                  : const Icon(Icons.image, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            token.label,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: [
              InkWell(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.backspace, size: 18),
                      SizedBox(height: 2),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.clear, size: 18),
                      SizedBox(height: 2),
                      Text(
                        'Clear',
                        style: TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.volume_up, size: isTablet ? 36 : 28),
              color: Colors.white,
              onPressed: onSpeak,
            ),
          ),
        ],
      ),
    );
  }
}
