/// Pure-Dart offline linguistic phonemizer and text normalizer.
///
/// Converts Sinhala and Tamil Unicode text into Piper-compatible IPA phoneme
/// codepoints and normalizes English text (numbers, symbols, hyphenation) for
/// `sherpa_onnx` VITS lexicon synthesis without any GPL external libraries.
library;

class SpeechSegment {
  const SpeechSegment({
    required this.languageCode,
    required this.text,
  });

  final String languageCode;
  final String text;
}

class TtsPhonemizer {
  const TtsPhonemizer._();

  // Phoneme characters accepted by Piper eSpeak-trained models (`si` / `ta`).
  static final Set<int> _allowedIpaCodepoints = <int>{
    ...' _^\$!\'(), -.:;?\u02c8\u02cc\u02d0'
        'abcdefɡhijklmnopqrstuvwxyz'
        'æçðøħŋœɐɑɒɓɔɕɖɗɘəɚɛɜɞɟɠɢɣɤɥɦɧɨɪɫɬɭɮɯɰɱɲɳɴɵɶɸɹɺɻɽɾʀʁʂʃʄʈʉʊʋʌʍʎʏʐʑʒʔʕʘʙʛʜʝʟʡʢβθχᵻⱱ'
        'ʰʲːˑ˞ˤ̧̩̪̯̺̻̃'
        .runes,
  };

  /// Splits input text into script-homogeneous runs (`en`, `si`, `ta`).
  ///
  /// Keeps a pure single-script sentence as one segment so card taps suffer zero
  /// artificial chunk pauses while still allowing mixed-script cards like
  /// "TV බලන්න" to pronounce every word naturally.
  static List<SpeechSegment> splitByScript(
    String text, {
    required String preferredLanguage,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final segments = <SpeechSegment>[];
    final buf = StringBuffer();
    String? activeLang;

    for (final rune in trimmed.runes) {
      final lang = _scriptForRune(rune);
      if (lang == null) {
        buf.writeCharCode(rune);
        continue;
      }
      if (activeLang != null && activeLang != lang) {
        final chunk = buf.toString().trim();
        if (chunk.isNotEmpty) {
          segments.add(SpeechSegment(languageCode: activeLang, text: chunk));
        }
        buf.clear();
      }
      activeLang = lang;
      buf.writeCharCode(rune);
    }

    final tail = buf.toString().trim();
    if (tail.isNotEmpty) {
      segments.add(
        SpeechSegment(
          languageCode: activeLang ?? _normalizeLanguage(preferredLanguage),
          text: tail,
        ),
      );
    }
    return segments;
  }

  static String _normalizeLanguage(String lang) {
    final lower = lang.toLowerCase();
    if (lower.startsWith('si')) return 'si';
    if (lower.startsWith('ta')) return 'ta';
    return 'en';
  }

  static String? _scriptForRune(int rune) {
    if (rune >= 0x0D80 && rune <= 0x0DFF) return 'si';
    if (rune >= 0x0B80 && rune <= 0x0BFF) return 'ta';
    if ((rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x30 && rune <= 0x39)) {
      return 'en';
    }
    return null;
  }

  /// Normalizes English text so lexicon lookup handles numbers & punctuation.
  static String normalizeEnglishText(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    text = text
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('&', ' and ')
        .replaceAll('%', ' percent ')
        .replaceAll('+', ' plus ')
        .replaceAll('@', ' at ')
        .replaceAll('/', ' ');

    text = text.replaceAllMapped(RegExp(r'\b\d{1,6}\b'), (m) {
      final value = int.tryParse(m.group(0)!);
      if (value == null) return m.group(0)!;
      return _englishIntToWords(value);
    });

    // Replace unsupported symbols cleanly while keeping cadence punctuation.
    text = text.replaceAll(RegExp(r'''[^A-Za-z0-9\s,\.!\?;:'"]'''), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static List<int> phonemizeToCodepoints(String text, String languageCode) {
    final normalized = _normalizeLanguage(languageCode);
    final ipa = switch (normalized) {
      'si' => phonemizeSinhala(text),
      'ta' => phonemizeTamil(text),
      _ => normalizeEnglishText(text),
    };
    if (ipa.isEmpty) return const [];
    return ipa.runes.where(_allowedIpaCodepoints.contains).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // SINHALA PHONEMIZER (Unicode si -> Piper IPA)
  // ---------------------------------------------------------------------------

  static const Map<int, String> _siIndependentVowels = {
    0x0D85: 'a', // අ (contextual -> ɐ / ə)
    0x0D86: 'aː', // ආ
    0x0D87: 'æ', // ඇ
    0x0D88: 'æː', // ඈ
    0x0D89: 'i', // ඉ
    0x0D8A: 'iː', // ඊ
    0x0D8B: 'u', // උ
    0x0D8C: 'uː', // ඌ
    0x0D8D: 'ɾu', // ඍ
    0x0D8E: 'ɾuː', // ඎ
    0x0D8F: 'li', // ඏ
    0x0D90: 'liː', // ඐ
    0x0D91: 'e', // එ
    0x0D92: 'eː', // ඒ
    0x0D93: 'aɪ', // ඓ
    0x0D94: 'o', // ඔ
    0x0D95: 'oː', // ඕ
    0x0D96: 'aʊ', // ඖ
  };

  static const Map<int, String> _siConsonants = {
    0x0D9A: 'k', // ක
    0x0D9B: 'kʰ', // ඛ
    0x0D9C: 'ɡ', // ග
    0x0D9D: 'ɡʰ', // ඝ
    0x0D9E: 'ŋ', // ඞ
    0x0D9F: 'ŋɡ', // ඟ
    0x0DA0: 'tʃ', // ච
    0x0DA1: 'tʃʰ', // ඡ
    0x0DA2: 'dʒ', // ජ
    0x0DA3: 'dʒʰ', // ඣ
    0x0DA4: 'ɲ', // ඤ
    0x0DA5: 'ɡn', // ඥ
    0x0DA6: 'ɲdʒ', // ඦ
    0x0DA7: 'ʈ', // ට
    0x0DA8: 'ʈʰ', // ඨ
    0x0DA9: 'ɖ', // ඩ
    0x0DAA: 'ɖʰ', // ඪ
    0x0DAB: 'ɳ', // ණ
    0x0DAC: 'ɳɖ', // ඬ
    0x0DAD: 't̪', // ත
    0x0DAE: 't̪ʰ', // ථ
    0x0DAF: 'd̪', // ද
    0x0DB0: 'd̪ʰ', // ධ
    0x0DB1: 'n', // න
    0x0DB3: 'nd̪', // ඳ
    0x0DB4: 'p', // ප
    0x0DB5: 'pʰ', // ඵ
    0x0DB6: 'b', // බ
    0x0DB7: 'bʰ', // භ
    0x0DB8: 'm', // ම
    0x0DB9: 'mb', // ඹ
    0x0DBA: 'j', // ය
    0x0DBB: 'r', // ර
    0x0DBD: 'l', // ල
    0x0DC0: 'w', // ව
    0x0DC1: 'ʃ', // ශ
    0x0DC2: 'ʃ', // ෂ
    0x0DC3: 's', // ස
    0x0DC4: 'h', // හ
    0x0DC5: 'ɭ', // ළ
    0x0DC6: 'f', // ෆ
  };

  static const Map<int, String> _siVowelSigns = {
    0x0DCF: 'aː', // ා
    0x0DD0: 'æ', // ැ
    0x0DD1: 'æː', // ෑ
    0x0DD2: 'i', // ි
    0x0DD3: 'iː', // ී
    0x0DD4: 'u', // ු
    0x0DD6: 'uː', // ූ
    0x0DD8: 'ɾu', // ෘ
    0x0DD9: 'e', // ෙ
    0x0DDA: 'eː', // ේ
    0x0DDB: 'aɪ', // ෛ
    0x0DDC: 'o', // ො
    0x0DDD: 'oː', // ෝ
    0x0DDE: 'aʊ', // ෞ
    0x0DDF: 'li', // ෟ
    0x0DF2: 'ɾuː', // ෲ
    0x0DF3: 'liː', // ෳ
  };

  static String phonemizeSinhala(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return '';

    final words = cleaned.split(RegExp(r'\s+'));
    final outWords = <String>[];

    for (final w in words) {
      if (w.isEmpty) continue;
      final cp = w.runes.toList(growable: false);
      final sb = StringBuffer();
      var syllableCount = 0;

      for (var i = 0; i < cp.length; i++) {
        final r = cp[i];

        if (r == 0x200D || r == 0x200C) continue; // ZWJ/ZWNJ

        if (r == 0x0D82) {
          // Anusvara (ං) assimilates to following consonant place, else ŋ.
          final next = i + 1 < cp.length ? cp[i + 1] : 0;
          if (next >= 0x0D9A && next <= 0x0D9F) {
            sb.write('ŋ');
          } else if (next >= 0x0DA0 && next <= 0x0DA6) {
            sb.write('ɲ');
          } else if (next >= 0x0DA7 && next <= 0x0DAC) {
            sb.write('ɳ');
          } else if (next >= 0x0DAD && next <= 0x0DB3) {
            sb.write('n');
          } else if (next >= 0x0DB4 && next <= 0x0DB9) {
            sb.write('m');
          } else {
            sb.write('ŋ');
          }
          continue;
        }
        if (r == 0x0D83) {
          sb.write('h'); // Visarga (ඃ)
          continue;
        }

        final indV = _siIndependentVowels[r];
        if (indV != null) {
          if (syllableCount == 0) {
            sb.write('ˈ');
            sb.write(r == 0x0D85 ? 'ɐ' : indV);
          } else {
            sb.write(r == 0x0D85 ? 'ə' : indV);
          }
          syllableCount++;
          continue;
        }

        final cons = _siConsonants[r];
        if (cons != null) {
          // Check Repaya: ර + ් + ZWJ + <consonant>
          if (r == 0x0DBB &&
              i + 3 < cp.length &&
              cp[i + 1] == 0x0DCA &&
              cp[i + 2] == 0x200D &&
              _siConsonants.containsKey(cp[i + 3])) {
            sb.write('r');
            i += 2;
            continue;
          }

          sb.write(cons);

          // Consume Yansaya (්+ZWJ+ය) or Rakaransaya (්+ZWJ+ර) medial clusters.
          while (i + 3 < cp.length &&
              cp[i + 1] == 0x0DCA &&
              cp[i + 2] == 0x200D &&
              (cp[i + 3] == 0x0DBA || cp[i + 3] == 0x0DBB)) {
            sb.write(cp[i + 3] == 0x0DBA ? 'j' : 'r');
            i += 3;
          }

          final next = i + 1 < cp.length ? cp[i + 1] : 0;
          if (next == 0x0DCA) {
            i++; // Halanta suppresses vowel
          } else if (_siVowelSigns.containsKey(next)) {
            if (syllableCount == 0) sb.write('ˈ');
            sb.write(_siVowelSigns[next]);
            syllableCount++;
            i++;
          } else {
            // Inherent vowel: initial syllable stressed ɐ, subsequent syllables reduce to ə.
            if (syllableCount == 0) {
              sb.write('ˈɐ');
            } else {
              sb.write('ə');
            }
            syllableCount++;
          }
          continue;
        }

        if (_isPunctuation(r)) {
          sb.writeCharCode(r);
        }
      }

      if (sb.isNotEmpty) {
        outWords.add(sb.toString());
      }
    }

    return outWords.join(' ');
  }

  // ---------------------------------------------------------------------------
  // TAMIL PHONEMIZER (Unicode ta -> Piper IPA)
  // ---------------------------------------------------------------------------

  static const Map<int, String> _taIndependentVowels = {
    0x0B85: 'a', // அ
    0x0B86: 'aː', // ஆ
    0x0B87: 'i', // இ
    0x0B88: 'iː', // ஈ
    0x0B89: 'u', // உ
    0x0B8A: 'uː', // ஊ
    0x0B8E: 'e', // எ
    0x0B8F: 'eː', // ஏ
    0x0B90: 'aɪ', // ஐ
    0x0B92: 'o', // ஒ
    0x0B93: 'oː', // ஓ
    0x0B94: 'aʊ', // ஔ
  };

  static const Map<int, String> _taVowelSigns = {
    0x0BBE: 'aː', // ா
    0x0BBF: 'i', // ி
    0x0BC0: 'iː', // ீ
    0x0BC1: 'u', // ு
    0x0BC2: 'uː', // ூ
    0x0BC6: 'e', // ெ
    0x0BC7: 'eː', // ே
    0x0BC8: 'aɪ', // ை
    0x0BCA: 'o', // ொ
    0x0BCB: 'oː', // ோ
    0x0BCC: 'aʊ', // ௌ
  };

  static const Set<int> _taNasals = {
    0x0B99, // ங
    0x0B9E, // ஞ
    0x0BA3, // ண
    0x0BA8, // ந
    0x0BA9, // ன
    0x0BAE, // ம
  };

  static const Set<int> _taStops = {
    0x0B95, // க
    0x0B9A, // ச
    0x0B9F, // ட
    0x0BA4, // த
    0x0BAA, // ப
    0x0BB1, // ற
  };

  static bool _isTamilBaseConsonant(int r) =>
      (r >= 0x0B95 && r <= 0x0BB9);

  static String phonemizeTamil(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return '';

    final words = cleaned.split(RegExp(r'\s+'));
    final outWords = <String>[];

    for (final w in words) {
      if (w.isEmpty) continue;
      final cp = w.runes.toList(growable: false);
      final sb = StringBuffer();
      var syllableCount = 0;

      for (var i = 0; i < cp.length; i++) {
        final r = cp[i];

        if (r == 0x200D || r == 0x200C) continue;

        if (r == 0x0B83) {
          sb.write('x'); // Aytham (ஃ)
          continue;
        }
        if (r == 0x0B82) {
          sb.write('m'); // Anusvara
          continue;
        }

        // Split Grantha ligature க்ஷ (0B95 0BCD 0BB7) -> kʃ
        if (r == 0x0B95 &&
            i + 2 < cp.length &&
            cp[i + 1] == 0x0BCD &&
            cp[i + 2] == 0x0BB7) {
          sb.write('kʃ');
          i += 2;
          final next = i + 1 < cp.length ? cp[i + 1] : 0;
          if (next == 0x0BCD) {
            i++;
          } else if (_taVowelSigns.containsKey(next)) {
            if (syllableCount == 0) sb.write('ˈ');
            sb.write(_taVowelSigns[next]);
            syllableCount++;
            i++;
          } else {
            sb.write(syllableCount == 0 ? 'ˈa' : 'ə');
            syllableCount++;
          }
          continue;
        }

        final indV = _taIndependentVowels[r];
        if (indV != null) {
          if (syllableCount == 0) {
            sb.write('ˈ');
            sb.write(indV);
          } else {
            sb.write(r == 0x0B85 ? 'ʌ' : indV);
          }
          syllableCount++;
          continue;
        }

        if (_isTamilBaseConsonant(r)) {
          final isInitial = i == 0;
          final prevHasPulli = i >= 2 && cp[i - 1] == 0x0BCD;
          final prevBase = prevHasPulli ? cp[i - 2] : 0;
          final isGeminate = prevHasPulli && prevBase == r;
          final afterNasal = prevHasPulli && _taNasals.contains(prevBase);
          final afterOtherPulli = prevHasPulli && prevBase != r && !_taNasals.contains(prevBase);
          final nextIsPulli = i + 1 < cp.length && cp[i + 1] == 0x0BCD;
          final nextIsSameStop =
              nextIsPulli && i + 2 < cp.length && cp[i + 2] == r && _taStops.contains(r);

          sb.write(_mapTamilConsonant(
            r,
            isInitial: isInitial,
            isGeminate: isGeminate || nextIsSameStop,
            afterNasal: afterNasal,
            afterStopOrLiquid: afterOtherPulli,
            hasPulli: nextIsPulli,
          ));

          if (nextIsPulli) {
            i++; // Pulli suppresses vowel
          } else if (_taVowelSigns.containsKey(
              i + 1 < cp.length ? cp[i + 1] : 0)) {
            final vSign = cp[i + 1];
            final mappedV = _taVowelSigns[vSign]!;
            if (syllableCount == 0) {
              sb.write('ˈ');
              sb.write(mappedV);
            } else if (vSign == 0x0BC1) {
              // Unstressed non-initial u reduces to ʉ in ph_tamil.
              sb.write('ʉ');
            } else {
              sb.write(mappedV);
            }
            syllableCount++;
            i++;
          } else {
            // Inherent short vowel: stressed a initially, ə before word-final ம், else ʌ.
            if (syllableCount == 0) {
              sb.write('ˈa');
            } else if (i + 2 < cp.length &&
                cp[i + 1] == 0x0BAE &&
                cp[i + 2] == 0x0BCD &&
                i + 3 == cp.length) {
              sb.write('ə');
            } else {
              sb.write('ʌ');
            }
            syllableCount++;
          }
          continue;
        }

        if (_isPunctuation(r)) {
          sb.writeCharCode(r);
        }
      }

      if (sb.isNotEmpty) {
        outWords.add(sb.toString());
      }
    }

    return outWords.join(' ');
  }

  static String _mapTamilConsonant(
    int rune, {
    required bool isInitial,
    required bool isGeminate,
    required bool afterNasal,
    required bool afterStopOrLiquid,
    required bool hasPulli,
  }) {
    final hard = isInitial || isGeminate || afterStopOrLiquid || hasPulli;
    switch (rune) {
      case 0x0B95: // க
        if (isGeminate || isInitial || afterStopOrLiquid || hasPulli) return 'k';
        return 'ɡ';
      case 0x0B99: // ங
        return 'ŋ';
      case 0x0B9A: // ச
        if (afterNasal) return 'dʒ';
        if (isGeminate || afterStopOrLiquid) return 'tʃ';
        return isInitial ? 's' : 's';
      case 0x0B9C: // ஜ
        return 'dʒ';
      case 0x0B9E: // ஞ
        return 'ɲ';
      case 0x0B9F: // ட
        return (isGeminate || afterStopOrLiquid) ? 'ʈ' : (hard ? 'ʈ' : 'ɖ');
      case 0x0BA3: // ண
        return 'ɳ';
      case 0x0BA4: // த
        if (isInitial || isGeminate || afterStopOrLiquid || hasPulli) return 't̪';
        return afterNasal ? 'd̪' : 'ð';
      case 0x0BA8: // ந
      case 0x0BA9: // ன
        return 'n';
      case 0x0BAA: // ப
        if (afterNasal && !isGeminate) return 'b';
        if (isInitial || isGeminate || afterStopOrLiquid || hasPulli) return 'p';
        return 'b';
      case 0x0BAE: // ம
        return 'm';
      case 0x0BAF: // ய
        return 'j';
      case 0x0BB0: // ர
        return 'r';
      case 0x0BB1: // ற
        if (isGeminate) return 't̪r';
        if (afterNasal) return 'd̪r';
        return 'r';
      case 0x0BB2: // ல
        return 'l';
      case 0x0BB3: // ள
        return 'ɭ';
      case 0x0BB4: // ழ
        return 'ɻ';
      case 0x0BB5: // வ
        return 'ʋ';
      case 0x0BB6: // ஶ
      case 0x0BB7: // ஷ
        return 'ʃ';
      case 0x0BB8: // ஸ
        return 's';
      case 0x0BB9: // ஹ
        return 'h';
      default:
        return '';
    }
  }

  static bool _isPunctuation(int rune) {
    return rune == 0x2C || // ,
        rune == 0x2E || // .
        rune == 0x21 || // !
        rune == 0x3F || // ?
        rune == 0x3A || // :
        rune == 0x3B || // ;
        rune == 0x2D; // -
  }

  // ---------------------------------------------------------------------------
  // ENGLISH NUMBER-TO-WORDS NORMALIZER (0..999,999)
  // ---------------------------------------------------------------------------

  static const List<String> _ones = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  static String _englishIntToWords(int n) {
    if (n < 20) return _ones[n];
    if (n < 100) {
      final t = _tens[n ~/ 10];
      final r = n % 10;
      return r == 0 ? t : '$t ${_ones[r]}';
    }
    if (n < 1000) {
      final h = '${_ones[n ~/ 100]} hundred';
      final r = n % 100;
      return r == 0 ? h : '$h ${_englishIntToWords(r)}';
    }
    final th = '${_englishIntToWords(n ~/ 1000)} thousand';
    final r = n % 1000;
    return r == 0 ? th : '$th ${_englishIntToWords(r)}';
  }
}
