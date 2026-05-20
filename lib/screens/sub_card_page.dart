import 'package:flutter/material.dart';
import '../models/aac_card_model.dart';
import '../widgets/aac_card_widget.dart';

class SubCardPage extends StatelessWidget {
  final AACCard parentCard;
  final Function(String) onSpeak;
  final Function(AACCard) onEdit;

  const SubCardPage({
    Key? key,
    required this.parentCard,
    required this.onSpeak,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(parentCard.label),
        backgroundColor: Color(parentCard.colorValue),
      ),
      body: parentCard.subCards.isEmpty
          ? const Center(
              child: Text(
                'No sub-cards yet.\nLong press the parent card to add some!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: parentCard.subCards.length,
                itemBuilder: (context, index) {
                  final subCard = parentCard.subCards[index];
                  return AACCardWidget(
                    card: subCard,
                    onTap: () => onSpeak(subCard.label),
                    onLongPress: () => onEdit(subCard),
                  );
                },
              ),
            ),
    );
  }
}
