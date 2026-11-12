/// Multilingual text segmentation and normalization router for Simple AAC.
///
/// Preserves original user-visible card labels while routing each Unicode-script
/// span (`en`, `si`, `ta`) and curated unambiguous Romanized expressions to the
/// right language voice without running English words through Sinhala rules.
library;

class SpeechRouteSegment {
  const SpeechRouteSegment({
    required this.languageCode,
    required this.text,
  });

  final String languageCode;
  final String text;

  Map<String, String> toMap() => {
        'lang': languageCode,
        'text': text,
      };
}

class MultilingualSpeechRouter {
  const MultilingualSpeechRouter._();

  // Small, high-precision dictionary ONLY for unambiguous Romanized Sinhala/Tamil
  // expressions so normal English words like "water" or "school" stay English.
  static const Map<String, String> _unambiguousRomanizedSinhala = {
    'ayubowan': 'ආයුබෝවන්',
    'aayubowan': 'ආයුබෝවන්',
    'sthuthi': 'ස්තූතියි',
    'sthoothiyi': 'ස්තූතියි',
    'sthuthiyi': 'ස්තූතියි',
    'karunakara': 'කරුණාකර',
    'kohomada': 'කොහොමද',
    'hondai': 'හොඳයි',
    'satutui': 'සතුටුයි',
    'sathutui': 'සතුටුයි',
    'subha': 'සුභ',
  };

  static const Map<String, String> _unambiguousRomanizedTamil = {
    'vanakkam': 'வணக்கம்',
    'vannakkam': 'வணக்கம்',
    'nandri': 'நன்றி',
    'nanri': 'நன்றி',
    'nalama': 'நலமா',
  };

  /// Splits [rawText] into clean language-tagged speech segments using Unicode
  /// script runs plus unambiguous Romanized Sinhala/Tamil expressions.
  static List<SpeechRouteSegment> route(
    String rawText, {
    required String preferredLanguage,
    String? cardLanguageHint,
  }) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return const [];

    final fallbackLang = _normalizeLang(cardLanguageHint ?? preferredLanguage);
    final scriptRuns = _splitByUnicodeScript(trimmed, fallbackLang: fallbackLang);

    // Within Latin runs, promote only curated unambiguous Romanized expressions
    // to Sinhala/Tamil script so e.g. "ayubowan, good morning" works accurately
    // while leaving "school", "water", "hello" cleanly as English.
    final refined = <SpeechRouteSegment>[];
    for (final seg in scriptRuns) {
      if (seg.languageCode != 'en') {
        _appendOrMerge(refined, seg.languageCode, seg.text);
        continue;
      }

      final tokens = seg.text.split(RegExp(r'\s+'));
      for (final tok in tokens) {
        if (tok.isEmpty) continue;
        final match = RegExp(r'^([^A-Za-z]*)([A-Za-z]+)([^A-Za-z]*)$').firstMatch(tok);
        if (match != null) {
          final lead = match.group(1) ?? '';
          final word = match.group(2)!;
          final trail = match.group(3) ?? '';
          final lower = word.toLowerCase();

          final siHit = _unambiguousRomanizedSinhala[lower];
          if (siHit != null) {
            _appendOrMerge(refined, 'si', '$lead$siHit$trail');
            continue;
          }
          final taHit = _unambiguousRomanizedTamil[lower];
          if (taHit != null) {
            _appendOrMerge(refined, 'ta', '$lead$taHit$trail');
            continue;
          }
        }
        _appendOrMerge(refined, 'en', tok);
      }
    }

    return refined
        .map(
          (s) => SpeechRouteSegment(
            languageCode: s.languageCode,
            text: s.languageCode == 'en'
                ? normalizeEnglishText(s.text)
                : normalizeIndicText(s.text),
          ),
        )
        .where((s) => s.text.isNotEmpty)
        .toList(growable: false);
  }

  static List<SpeechRouteSegment> _splitByUnicodeScript(
    String text, {
    required String fallbackLang,
  }) {
    final segments = <SpeechRouteSegment>[];
    final buf = StringBuffer();
    String? activeLang;

    for (final rune in text.runes) {
      final lang = _scriptForRune(rune);
      if (lang == null) {
        buf.writeCharCode(rune);
        continue;
      }
      if (activeLang != null && activeLang != lang) {
        final chunk = buf.toString().trim();
        if (chunk.isNotEmpty) {
          segments.add(SpeechRouteSegment(languageCode: activeLang, text: chunk));
        }
        buf.clear();
      }
      activeLang = lang;
      buf.writeCharCode(rune);
    }

    final tail = buf.toString().trim();
    if (tail.isNotEmpty) {
      segments.add(
        SpeechRouteSegment(
          languageCode: activeLang ?? fallbackLang,
          text: tail,
        ),
      );
    }
    return segments;
  }

  static void _appendOrMerge(
    List<SpeechRouteSegment> out,
    String lang,
    String token,
  ) {
    final cleaned = token.trim();
    if (cleaned.isEmpty) return;
    if (out.isNotEmpty && out.last.languageCode == lang) {
      out[out.length - 1] = SpeechRouteSegment(
        languageCode: lang,
        text: '${out.last.text} $cleaned',
      );
    } else {
      out.add(SpeechRouteSegment(languageCode: lang, text: cleaned));
    }
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

  static String _normalizeLang(String lang) {
    final lower = lang.trim().toLowerCase();
    if (lower.startsWith('si')) return 'si';
    if (lower.startsWith('ta')) return 'ta';
    return 'en';
  }

  /// Cleans symbols & punctuation in Sinhala/Tamil text without changing words.
  static String normalizeIndicText(String raw) {
    return raw
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalizes English text (numbers, symbols, hyphenation) cleanly.
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

    text = text.replaceAll(RegExp(r'''[^A-Za-z0-9\s,\.!\?;:'"]'''), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

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
