import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';

const String seedHelloImage = 'assets/images/seed/hello.png';
const String seedHappyImage = 'assets/images/seed/happy.png';
const String seedSadImage = 'assets/images/seed/sad.png';
const String seedAngryImage = 'assets/images/seed/angry.png';
const String seedBlocksImage = 'assets/images/seed/blocks.png';
const String seedGoodImage = 'assets/images/seed/good.png';
const String seedPlayImage = 'assets/images/seed/play.png';

const String sinhalaHello = '\u0dc4\u0dd9\u0dbd\u0ddd';
const String sinhalaHappy = '\u0dc3\u0dad\u0dd4\u0da7\u0dd4\u0dba\u0dd2';
const String sinhalaSad = '\u0daf\u0dd4\u0d9a\u0dba\u0dd2';
const String sinhalaAngry = '\u0dad\u0dbb\u0dc4\u0dba\u0dd2';
const String sinhalaMore = '\u0dad\u0dc0\u0dad\u0dca';
const String sinhalaGood = '\u0dc4\u0ddc\u0db3\u0dba\u0dd2';
const String sinhalaPlay = '\u0dc3\u0dd9\u0dbd\u0dca\u0dbd\u0db8\u0dca';

const String tamilHello = '\u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd';
const String tamilHappy =
    '\u0bae\u0b95\u0bbf\u0bb4\u0bcd\u0b9a\u0bcd\u0b9a\u0bbf';
const String tamilSad = '\u0b9a\u0bcb\u0b95\u0bae\u0bcd';
const String tamilAngry = '\u0b95\u0bcb\u0baa\u0bae\u0bcd';
const String tamilMore = '\u0bae\u0bc7\u0bb2\u0bc1\u0bae\u0bcd';
const String tamilGood = '\u0ba8\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1';
const String tamilPlay = '\u0bb5\u0bbf\u0bb3\u0bc8\u0baf\u0bbe\u0b9f\u0bc1';

List<AACCard> createDefaultSeedCards() {
  return [
    AACCard(
      id: 'seed_hello',
      label: 'Hello',
      labelSinhala: sinhalaHello,
      labelTamil: tamilHello,
      imagePath: seedHelloImage,
      colorValue: Colors.yellow.shade300.value,
    ),
    AACCard(
      id: 'seed_happy',
      label: 'Happy',
      labelSinhala: sinhalaHappy,
      labelTamil: tamilHappy,
      imagePath: seedHappyImage,
      colorValue: Colors.lightBlue.shade200.value,
    ),
    AACCard(
      id: 'seed_sad',
      label: 'Sad',
      labelSinhala: sinhalaSad,
      labelTamil: tamilSad,
      imagePath: seedSadImage,
      colorValue: Colors.lightBlue.shade300.value,
    ),
    AACCard(
      id: 'seed_angry',
      label: 'Angry',
      labelSinhala: sinhalaAngry,
      labelTamil: tamilAngry,
      imagePath: seedAngryImage,
      colorValue: Colors.red.shade300.value,
    ),
    AACCard(
      id: 'seed_more',
      label: 'More',
      labelSinhala: sinhalaMore,
      labelTamil: tamilMore,
      imagePath: seedBlocksImage,
      colorValue: Colors.indigo.shade500.value,
      type: 'folder',
      subCards: [
        AACCard(
          id: 'seed_good',
          label: 'Good',
          labelSinhala: sinhalaGood,
          labelTamil: tamilGood,
          imagePath: seedGoodImage,
          colorValue: Colors.green.shade300.value,
        ),
        AACCard(
          id: 'seed_play',
          label: 'Play',
          labelSinhala: sinhalaPlay,
          labelTamil: tamilPlay,
          imagePath: seedPlayImage,
          colorValue: Colors.orange.shade300.value,
        ),
      ],
    ),
  ];
}
