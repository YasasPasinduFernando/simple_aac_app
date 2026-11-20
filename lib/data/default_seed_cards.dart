import 'package:flutter/material.dart';

import '../models/aac_card_model.dart';
import '../services/starter_pack_service.dart';

const String seedHelloImage = 'assets/home/hello.webp';
const String seedHappyImage = 'assets/home/happy.webp';
const String seedSadImage = 'assets/home/sad.webp';
const String seedAngryImage = 'assets/home/angry.webp';
const String seedBlocksImage = 'assets/images/seed_v2/more.webp';
const String seedGoodImage = 'assets/images/seed_v2/good.webp';
const String seedPlayImage = 'assets/images/seed_v2/play.webp';
const String seedYesImage = 'assets/images/seed_v2/yes.webp';
const String seedNoImage = 'assets/images/seed_v2/no.webp';
const String seedPleaseImage = 'assets/images/seed_v2/please.webp';
const String seedThankYouImage = 'assets/images/seed_v2/thank_you.webp';
const String seedHelpImage = 'assets/images/seed_v2/help.webp';
const String seedStopImage = 'assets/images/seed_v2/stop.webp';

// Legacy seed image paths for migration identification
const String legacySeedHelloImage = 'assets/images/seed/hello.png';
const String legacySeedHappyImage = 'assets/images/seed/happy.png';
const String legacySeedSadImage = 'assets/images/seed/sad.png';
const String legacySeedAngryImage = 'assets/images/seed/angry.png';
const String legacySeedBlocksImage = 'assets/images/seed/blocks.png';
const String legacySeedGoodImage = 'assets/images/seed/good.png';
const String legacySeedPlayImage = 'assets/images/seed/play.png';

const String sinhalaHello = '\u0dc4\u0dd9\u0dbd\u0ddd';
const String sinhalaHappy = '\u0dc3\u0dad\u0dd4\u0da7\u0dd4\u0dba\u0dd2';
const String sinhalaSad = '\u0daf\u0dd4\u0d9a\u0dba\u0dd2';
const String sinhalaAngry = '\u0dad\u0dbb\u0dc4\u0dba\u0dd2';
const String sinhalaMore = '\u0dad\u0dc0\u0dad\u0dca';
const String sinhalaGood = '\u0dc4\u0ddc\u0db3\u0dba\u0dd2';
const String sinhalaPlay = '\u0dc3\u0dd9\u0dbd\u0dca\u0dbd\u0db8\u0dca';
const String sinhalaYes = '\u0d94\u0dc0\u0dca';
const String sinhalaNo = '\u0db1\u0dd0\u0dc4\u0dd0';
const String sinhalaPlease = '\u0d9a\u0dbb\u0dd4\u0dab\u0dcf\u0d9a\u0dbb';
const String sinhalaThankYou = '\u0dc3\u0dca\u0dad\u0dd4\u0dad\u0dd2\u0dba\u0dd2';
const String sinhalaHelp = '\u0d8b\u0daf\u0dc0\u0dca';
const String sinhalaStop = '\u0db1\u0dc0\u0dad\u0dca\u0dc0\u0db1\u0dca\u0db1';

const String tamilHello = '\u0bb5\u0ba3\u0b95\u0bcd\u0b95\u0bae\u0bcd';
const String tamilHappy =
    '\u0bae\u0b95\u0bbf\u0bb4\u0bcd\u0b9a\u0bcd\u0b9a\u0bbf';
const String tamilSad = '\u0b9a\u0bcb\u0b95\u0bae\u0bcd';
const String tamilAngry = '\u0b95\u0bcb\u0baa\u0bae\u0bcd';
const String tamilMore = '\u0bae\u0bc7\u0bb2\u0bc1\u0bae\u0bcd';
const String tamilGood = '\u0ba8\u0bb2\u0bcd\u0bb2\u0ba4\u0bc1';
const String tamilPlay = '\u0bb5\u0bbf\u0bb3\u0bc8\u0baf\u0bbe\u0b9f\u0bc1';
const String tamilYes = '\u0b86\u0bae\u0bcd';
const String tamilNo = '\u0b87\u0bb2\u0bcd\u0bb2\u0bc8';
const String tamilPlease = '\u0ba4\u0baf\u0bb5\u0bc1\u0b9a\u0bc6\u0baf\u0bcd\u0ba4\u0bc1';
const String tamilThankYou = '\u0ba8\u0ba9\u0bcd\u0bb1\u0bbf';
const String tamilHelp = '\u0b89\u0ba4\u0bb5\u0bbf';
const String tamilStop = '\u0ba8\u0bbf\u0bb1\u0bc1\u0ba4\u0bcd\u0ba4\u0bc1';

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
      colorValue: Colors.yellow.shade300.value,
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
      colorValue: 0xFF475CC5,
      type: 'folder',
      subCards: [
        AACCard(
          id: 'seed_good',
          label: 'Good',
          labelSinhala: sinhalaGood,
          labelTamil: tamilGood,
          imagePath: seedGoodImage,
          colorValue: 0xFF7CCA7E,
        ),
        AACCard(
          id: 'seed_play',
          label: 'Play',
          labelSinhala: sinhalaPlay,
          labelTamil: tamilPlay,
          imagePath: seedPlayImage,
          colorValue: 0xFFFEAE3E,
        ),
        AACCard(
          id: 'seed_yes',
          label: 'Yes',
          labelSinhala: sinhalaYes,
          labelTamil: tamilYes,
          imagePath: seedYesImage,
          colorValue: 0xFF9ADEA7,
        ),
        AACCard(
          id: 'seed_no',
          label: 'No',
          labelSinhala: sinhalaNo,
          labelTamil: tamilNo,
          imagePath: seedNoImage,
          colorValue: 0xFFEB9698,
        ),
        AACCard(
          id: 'seed_please',
          label: 'Please',
          labelSinhala: sinhalaPlease,
          labelTamil: tamilPlease,
          imagePath: seedPleaseImage,
          colorValue: 0xFFCF99DB,
        ),
        AACCard(
          id: 'seed_thank_you',
          label: 'Thank You',
          labelSinhala: sinhalaThankYou,
          labelTamil: tamilThankYou,
          imagePath: seedThankYouImage,
          colorValue: 0xFFFDE473,
        ),
        AACCard(
          id: 'seed_help',
          label: 'Help',
          labelSinhala: sinhalaHelp,
          labelTamil: tamilHelp,
          imagePath: seedHelpImage,
          colorValue: 0xFF70E3EC,
        ),
        AACCard(
          id: 'seed_stop',
          label: 'Stop',
          labelSinhala: sinhalaStop,
          labelTamil: tamilStop,
          imagePath: seedStopImage,
          colorValue: 0xFFFC877C,
        ),
      ],
    ),
    StarterPackService.getStarterPackRootClone(),
  ];
}
