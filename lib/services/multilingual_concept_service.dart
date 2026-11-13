/// Service for normalizing multilingual AAC vocabulary (Sinhala, Tamil, English)
/// into canonical concept search queries suitable for image retrieval.
/// 
/// Operates 100% OFFLINE with zero paid translation APIs.
class MultilingualConceptService {
  static const Map<String, String> _conceptMap = {
    // === Greetings & Core Social ===
    'hello': 'happy waving child',
    'hi': 'happy waving child',
    'ආයුබෝවන්': 'happy waving child',
    'හෙලෝ': 'happy waving child',
    'வணக்கம்': 'happy waving child',
    'good': 'thumbs up good',
    'හොඳයි': 'thumbs up good',
    'நல்லது': 'thumbs up good',
    'more': 'more blocks toys',
    'තව': 'more blocks toys',
    'மேலும்': 'more blocks toys',
    'yes': 'happy yes nodding',
    'ඔව්': 'happy yes nodding',
    'ஆம்': 'happy yes nodding',
    'no': 'no stop hand',
    'නෑ': 'no stop hand',
    'නැහැ': 'no stop hand',
    'இல்லை': 'no stop hand',
    'want': 'reaching hand want',
    'ඕනේ': 'reaching hand want',
    'வேண்டும்': 'reaching hand want',
    'thank you': 'thank you smiling',
    'ස්තූතියි': 'thank you smiling',
    'நன்றி': 'thank you smiling',

    // === People & Family ===
    'mother': 'mother',
    'mom': 'mother',
    'mama': 'mother',
    'අම්මා': 'mother',
    'අම්මි': 'mother',
    'அம்மா': 'mother',
    'father': 'father',
    'dad': 'father',
    'තාත්තා': 'father',
    'තාත්ති': 'father',
    'அப்பா': 'father',
    'brother': 'brother',
    'brother / sister': 'family',
    'අයියා': 'brother',
    'මල්ලී': 'brother',
    'அண்ணன்': 'brother',
    'தம்பி': 'brother',
    'sister': 'sister',
    'අක්කා': 'sister',
    'නංගි': 'sister',
    'அக்கா': 'sister',
    'தங்கை': 'sister',
    'baby': 'baby',
    'බබා': 'baby',
    'குழந்தை': 'baby',
    'friend': 'friend',
    'යාලුවා': 'friend',
    'நண்பன்': 'friend',
    'teacher': 'teacher',
    'ගුරුතුමී': 'teacher',
    'ගුරුතුමා': 'teacher',
    'ஆசிரியர்': 'teacher',
    'doctor': 'doctor',
    'දොස්තර': 'doctor',
    'மருத்துவர்': 'doctor',

    // === Food & Drinks ===
    'water': 'water',
    'වතුර': 'glass of water',
    'පැන්': 'glass of water',
    'தண்ணீர்': 'glass of water',
    'milk': 'milk',
    'කිරි': 'glass of milk',
    'பால்': 'glass of milk',
    'rice': 'rice',
    'food': 'food',
    'බත්': 'cooked rice plate',
    'කෑම': 'food meal',
    'சோறு': 'cooked rice plate',
    'உணவு': 'food meal',
    'apple': 'apple fruit',
    'ඇපල්': 'apple fruit',
    'ஆப்பிள்': 'apple fruit',
    'banana': 'banana',
    'කෙසෙල්': 'banana',
    'வாழைப்பழம்': 'banana',
    'bread': 'bread',
    'පාන්': 'bread loaf',
    'ரொட்டி': 'bread loaf',
    'biscuit': 'biscuit',
    'බිස්කට්': 'biscuit cookie',
    'பிஸ்கட்': 'biscuit cookie',
    'tea': 'cup of tea',
    'තේ': 'cup of tea',
    'தேநீர்': 'cup of tea',
    'egg': 'egg',
    'බිත්තර': 'boiled egg',
    'முட்டை': 'boiled egg',
    'fish': 'fish',
    'මාළු': 'fish',
    'மீன்': 'fish',
    'chicken': 'chicken meat food',
    'කුකුල් මස්': 'chicken food',
    'கோழி இறைச்சி': 'chicken food',
    'ice cream': 'ice cream',
    'අයිස්ක්‍රීම්': 'ice cream cone',
    'ஐஸ்கிரீம்': 'ice cream cone',

    // === Daily Actions & Verbs ===
    'eat': 'eat food',
    'eating': 'eating food',
    'කනවා': 'eating food',
    'කන්න': 'eating food',
    'சாப்பிடு': 'eating food',
    'drink': 'drinking water',
    'drinking': 'drinking water',
    'බොනවා': 'drinking water',
    'බොන්න': 'drinking water',
    'குடி': 'drinking water',
    'sleep': 'sleeping in bed',
    'sleeping': 'sleeping in bed',
    'නිදාගන්නවා': 'sleeping in bed',
    'නිදාගන්න': 'sleeping in bed',
    'தூங்கு': 'sleeping in bed',
    'bath': 'taking bath wash',
    'bathing': 'taking bath wash',
    'wash': 'washing hands',
    'නානවා': 'taking bath wash',
    'නාන්න': 'taking bath wash',
    'අත හෝදනවා': 'washing hands',
    'குளி': 'taking bath wash',
    'study': 'child studying book',
    'learn': 'child studying book',
    'පාඩම් කරනවා': 'child studying book',
    'படி': 'child studying book',
    'play': 'child playing toys',
    'playing': 'child playing toys',
    'සෙල්ලම් කරනවා': 'child playing toys',
    'සෙල්ලම් කරන්න': 'child playing toys',
    'விளையாடு': 'child playing toys',
    'go': 'walking go',
    'යනවා': 'walking go',
    'යන්න': 'walking go',
    'போ': 'walking go',
    'come': 'come here',
    'එනවා': 'come here',
    'வா': 'come here',
    'stop': 'stop hand sign',
    'නවත්වන්න': 'stop hand sign',
    'නවතින්න': 'stop hand sign',
    'நில்': 'stop hand sign',
    'help': 'helping hands',
    'උදව්': 'helping hands',
    'උදව් කරන්න': 'helping hands',
    'உதவி': 'helping hands',

    // === Feelings, Needs & Sensations ===
    'happy': 'happy smiling child',
    'සතුටුයි': 'happy smiling child',
    'සතුට': 'happy smiling child',
    'மகிழ்ச்சி': 'happy smiling child',
    'sad': 'sad child',
    'දුකයි': 'sad child',
    'வருத்தம்': 'sad child',
    'angry': 'angry expression',
    'තරහයි': 'angry expression',
    'கோபம்': 'angry expression',
    'hungry': 'hungry child wanting food',
    'බඩගිනියි': 'hungry child wanting food',
    'பசி': 'hungry child wanting food',
    'thirsty': 'thirsty wanting water',
    'තිබහයි': 'thirsty wanting water',
    'தாகம்': 'thirsty wanting water',
    'tired': 'tired sleepy child',
    'මහන්සියි': 'tired sleepy child',
    'களைப்பு': 'tired sleepy child',
    'pain': 'hurt bandaid pain',
    'hurt': 'hurt bandaid pain',
    'රිදෙනවා': 'hurt bandaid pain',
    'අමාරුයි': 'hurt bandaid pain',
    'வலி': 'hurt bandaid pain',
    'love': 'heart love hug',
    'ආදරෙයි': 'heart love hug',
    'அன்பு': 'heart love hug',

    // === Animals ===
    'cat': 'cute cat',
    'kitten': 'cute cat',
    'පූසා': 'cute cat',
    'பூனை': 'cute cat',
    'dog': 'friendly dog',
    'puppy': 'friendly dog',
    'බල්ලා': 'friendly dog',
    'நாய்': 'friendly dog',
    'cow': 'cow',
    'හරකා': 'cow',
    'பசு': 'cow',
    'bird': 'bird',
    'කුරුල්ලා': 'bird',
    'பறவை': 'bird',
    'elephant': 'elephant',
    'අලියා': 'elephant',
    'யானை': 'elephant',
    'lion': 'lion',
    'සිංහයා': 'lion',
    'சிங்கம்': 'lion',

    // === Objects & School ===
    'ball': 'colorful ball',
    'බෝලය': 'colorful ball',
    'பந்து': 'colorful ball',
    'book': 'reading book',
    'පොත': 'reading book',
    'புத்தகம்': 'reading book',
    'pen': 'pen writing',
    'පෑන': 'pen writing',
    'பேனா': 'pen writing',
    'pencil': 'pencil',
    'පැන්සල': 'pencil',
    'பென்சில்': 'pencil',
    'chair': 'wooden chair',
    'පුටුව': 'wooden chair',
    'நாற்காலி': 'wooden chair',
    'table': 'table',
    'මේසය': 'table',
    'மேசை': 'table',
    'bed': 'comfortable bed',
    'ඇඳ': 'comfortable bed',
    'படுக்கை': 'comfortable bed',
    'phone': 'smartphone',
    'දුරකථනය': 'smartphone',
    'தொலைபேசி': 'smartphone',
    'toy': 'toy car blocks',
    'සෙල්ලම්බඩු': 'toy car blocks',
    'விளையாட்டுப்பொருள்': 'toy car blocks',

    // === Places & Transport ===
    'school': 'school building',
    'පාසල': 'school building',
    'ඉස්කෝලේ': 'school building',
    'பள்ளி': 'school building',
    'home': 'cozy house home',
    'house': 'cozy house home',
    'ගෙදර': 'cozy house home',
    'නිවස': 'cozy house home',
    'வீடு': 'cozy house home',
    'hospital': 'hospital clinic building',
    'රෝහල': 'hospital clinic building',
    'மருத்துவமனை': 'hospital clinic building',
    'park': 'playground park',
    'පාක් එක': 'playground park',
    'பூங்கா': 'playground park',
    'toilet': 'clean toilet bathroom',
    'bathroom': 'clean toilet bathroom',
    'වැසිකිලිය': 'clean toilet bathroom',
    'කழிப்பறை': 'clean toilet bathroom',
    'கழிப்பறை': 'clean toilet bathroom',
    'கழிவறை': 'clean toilet bathroom',
    'bus': 'passenger bus',
    'බස් එක': 'passenger bus',
    'பேருந்து': 'passenger bus',
    'car': 'passenger car',
    'කාර් එක': 'passenger car',
    'கார்': 'passenger car',
    'train': 'railway train',
    'කෝච්චිය': 'railway train',
    'දුම්රිය': 'railway train',
    'புகையிரதம்': 'railway train',
    'bicycle': 'bicycle',
    'බයිසිකලය': 'bicycle',
    'மிதிவண்டி': 'bicycle',
    'tuk tuk': 'auto rickshaw',
    'three wheeler': 'auto rickshaw',
    'ත්‍රීවීල්': 'auto rickshaw',
    'ஆட்டோ': 'auto rickshaw',

    // === Sri Lankan Everyday Items, Fruits, Clothing & Nature ===
    'mango': 'mango',
    'අඹ': 'mango',
    'மாம்பழம்': 'mango',
    'orange': 'orange fruit',
    'දොඩම්': 'orange fruit',
    'ஆரஞ்சு': 'orange fruit',
    'pineapple': 'pineapple',
    'අන්නාසි': 'pineapple',
    'அன்னாசி': 'pineapple',
    'coconut': 'coconut',
    'පොල්': 'coconut',
    'කුරුම්බා': 'coconut',
    'தேங்காய்': 'coconut',
    'hopper': 'hoppers sri lanka food',
    'ආප්ප': 'hoppers sri lanka food',
    'ஆப்பம்': 'hoppers sri lanka food',
    'kottu': 'kottu roti',
    'කොත්තු': 'kottu roti',
    'கொத்து': 'kottu roti',
    'shoe': 'shoe',
    'shoes': 'shoes',
    'සපත්තු': 'shoe',
    'காலணி': 'shoe',
    'cup': 'cup',
    'කෝප්පය': 'cup',
    'கோப்பை': 'cup',
    'plate': 'dinner plate',
    'පිඟාන': 'dinner plate',
    'தட்டு': 'dinner plate',
    'spoon': 'spoon',
    'හැන්ද': 'spoon',
    'கரண்டி': 'spoon',
    'toothbrush': 'toothbrush',
    'දත් බුරුසුව': 'toothbrush',
    'பல் துலக்கி': 'toothbrush',
    'soap': 'soap bar',
    'සබන්': 'soap bar',
    'சோப்பு': 'soap bar',
    'towel': 'bath towel',
    'තුවාය': 'bath towel',
    'துண்டு': 'bath towel',
    'shirt': 't-shirt clothes',
    'කමිසය': 't-shirt clothes',
    'சட்டை': 't-shirt clothes',
    'flower': 'flower',
    'මල': 'flower',
    'මල්': 'flower',
    'பூ': 'flower',
    'sun': 'sun',
    'ඉර': 'sun',
    'සූර්යයා': 'sun',
    'சூரியன்': 'sun',
    'rain': 'rain',
    'වැස්ස': 'rain',
    'மழை': 'rain',
    'tree': 'tree',
    'ගස': 'tree',
    'மரம்': 'tree',
    'music': 'music notes',
    'සංගීතය': 'music notes',
    'இசை': 'music notes',
  };

  /// Distills verbose AAC visual-descriptor prompts into crisp search keywords
  /// that match encyclopedic photos and ARASAAC symbols reliably.
  static const Map<String, String> _verboseCoreMap = {
    'happy smiling child': 'happy',
    'happy waving child': 'hello',
    'thumbs up good': 'thumbs up',
    'more blocks toys': 'more',
    'happy yes nodding': 'yes',
    'no stop hand': 'stop',
    'reaching hand want': 'want',
    'thank you smiling': 'thank you',
    'taking bath wash': 'bathtub',
    'hungry child wanting food': 'hungry',
    'thirsty wanting water': 'thirsty',
    'tired sleepy child': 'tired',
    'hurt bandaid pain': 'pain',
    'heart love hug': 'love',
    'walking go': 'walk',
    'child studying book': 'study',
    'child playing toys': 'play',
    'clean toilet bathroom': 'toilet',
    'glass of water': 'drinking water',
    'glass of milk': 'milk',
    'cup of tea': 'tea',
    'bread loaf': 'bread',
    'boiled egg': 'egg',
    'apple fruit': 'apple',
    'cooked rice plate': 'rice',
    'school building': 'school',
    'hospital clinic building': 'hospital',
    'cozy house home': 'house',
    'playground park': 'playground',
    'passenger bus': 'bus',
    'passenger car': 'car',
    'railway train': 'train',
    'colorful ball': 'ball',
    'reading book': 'book',
    'wooden chair': 'chair',
    'comfortable bed': 'bed',
    'toy car blocks': 'toy',
    'friendly dog': 'dog',
    'cute cat': 'cat',
    'food meal': 'food',
    'eating food': 'eat',
    'drinking water': 'drink water',
    'sleeping in bed': 'sleep',
    'ice cream cone': 'ice cream',
    'biscuit cookie': 'biscuit',
    'chicken meat food': 'chicken food',
    'orange fruit': 'orange',
    'soap bar': 'soap',
    't-shirt clothes': 't-shirt',
    'dinner plate': 'plate',
    'music notes': 'music',
  };

  static final List<MapEntry<String, String>> _sortedEntries = (() {
    final entries = _conceptMap.entries.toList();
    entries.sort((a, b) => b.key.length.compareTo(a.key.length));
    return entries;
  })();

  /// Normalizes any input text across Sinhala, Tamil, or English into a child-friendly
  /// English image search query.
  static String normalizeConcept(String rawInput) {
    final cleaned = rawInput.trim().toLowerCase();
    if (cleaned.isEmpty) return '';

    // Direct match in dictionary
    if (_conceptMap.containsKey(cleaned)) {
      return _conceptMap[cleaned]!;
    }

    // Whole-word/token matching longest-first prevents partial substring collisions
    // (e.g. 'good' hitting 'go', or Sinhala 'කිරිබත්' hitting 'කිරි'/'බත්').
    for (final entry in _sortedEntries) {
      final escaped = RegExp.escape(entry.key);
      final pattern = isLatinScript(entry.key)
          ? RegExp('(?:^|\\b)$escaped(?:\\b|\$)')
          : RegExp('(?:^|[\\s.,!?])$escaped(?:[\\s.,!?]|\$)');
      if (pattern.hasMatch(cleaned)) {
        return entry.value;
      }
    }

    // Fallback: Return cleaned input so user can refine manually if needed.
    return cleaned;
  }

  /// Simplifies verbose concept prompts into core search keywords while leaving
  /// free-form multi-word English queries (like "red apple" or "school bus") intact.
  static String toSearchCore(String query) {
    final cleaned = query.trim().toLowerCase();
    if (cleaned.isEmpty) return '';
    if (_verboseCoreMap.containsKey(cleaned)) {
      return _verboseCoreMap[cleaned]!;
    }
    if (isLatinScript(cleaned) && !_conceptMap.containsKey(cleaned)) {
      return cleaned;
    }
    final normalized = normalizeConcept(cleaned);
    return _verboseCoreMap[normalized] ?? normalized;
  }

  /// Returns true if the query is in English/Latin script.
  static bool isLatinScript(String text) {
    return RegExp(r'^[a-zA-Z0-9\s.,!?_-]+$').hasMatch(text.trim());
  }

  // =========================================================================
  // TRILINGUAL AAC VOCABULARY DICTIONARY (English • Sinhala • Tamil)
  // Operates 100% offline with verified native AAC terms.
  // =========================================================================

  static const Map<String, AacTranslation> _trilingualVocabulary = {
    // === Core Communication & Social ===
    'hello': AacTranslation(english: 'Hello', sinhala: 'ආයුබෝවන්', tamil: 'வணக்கம்', category: 'General'),
    'yes': AacTranslation(english: 'Yes', sinhala: 'ඔව්', tamil: 'ஆம்', category: 'General'),
    'no': AacTranslation(english: 'No', sinhala: 'නැහැ', tamil: 'இல்லை', category: 'General'),
    'good': AacTranslation(english: 'Good', sinhala: 'හොඳයි', tamil: 'நல்லது', category: 'General'),
    'more': AacTranslation(english: 'More', sinhala: 'තව', tamil: 'மேலும்', category: 'General'),
    'want': AacTranslation(english: 'Want', sinhala: 'ඕනේ', tamil: 'வேண்டும்', category: 'General'),
    'stop': AacTranslation(english: 'Stop', sinhala: 'නවත්වන්න', tamil: 'நில்', category: 'General'),
    'help': AacTranslation(english: 'Help', sinhala: 'උදව්', tamil: 'உதவி', category: 'General'),
    'thank you': AacTranslation(english: 'Thank You', sinhala: 'ස්තූතියි', tamil: 'நன்றி', category: 'General'),
    'please': AacTranslation(english: 'Please', sinhala: 'කරුණාකර', tamil: 'தயவுசெய்து', category: 'General'),
    'finished': AacTranslation(english: 'Finished', sinhala: 'ඉවරයි', tamil: 'முடிந்தது', category: 'General'),

    // === Food & Drinks ===
    'water': AacTranslation(english: 'Water', sinhala: 'වතුර', tamil: 'தண்ணீர்', category: 'Food & Drink'),
    'milk': AacTranslation(english: 'Milk', sinhala: 'කිරි', tamil: 'பால்', category: 'Food & Drink'),
    'rice': AacTranslation(english: 'Rice', sinhala: 'බත්', tamil: 'சோறு', category: 'Food & Drink'),
    'food': AacTranslation(english: 'Food', sinhala: 'කෑම', tamil: 'உணவு', category: 'Food & Drink'),
    'bread': AacTranslation(english: 'Bread', sinhala: 'පාන්', tamil: 'ரொட்டி', category: 'Food & Drink'),
    'apple': AacTranslation(english: 'Apple', sinhala: 'ඇපල්', tamil: 'ஆப்பிள்', category: 'Food & Drink'),
    'banana': AacTranslation(english: 'Banana', sinhala: 'කෙසෙල්', tamil: 'வாழைப்பழம்', category: 'Food & Drink'),
    'orange': AacTranslation(english: 'Orange', sinhala: 'දොඩම්', tamil: 'ஆரஞ்சு', category: 'Food & Drink'),
    'mango': AacTranslation(english: 'Mango', sinhala: 'අඹ', tamil: 'மாம்பழம்', category: 'Food & Drink'),
    'fruit': AacTranslation(english: 'Fruit', sinhala: 'පලතුරු', tamil: 'பழம்', category: 'Food & Drink'),
    'egg': AacTranslation(english: 'Egg', sinhala: 'බිත්තරය', tamil: 'முட்டை', category: 'Food & Drink'),
    'tea': AacTranslation(english: 'Tea', sinhala: 'තේ', tamil: 'தேநீர்', category: 'Food & Drink'),
    'coffee': AacTranslation(english: 'Coffee', sinhala: 'කෝපි', tamil: 'காப்பி', category: 'Food & Drink'),
    'biscuit': AacTranslation(english: 'Biscuit', sinhala: 'බිස්කට්', tamil: 'பிஸ்கட்', category: 'Food & Drink'),
    'cake': AacTranslation(english: 'Cake', sinhala: 'කේක්', tamil: 'கேக்', category: 'Food & Drink'),
    'fish': AacTranslation(english: 'Fish', sinhala: 'මාළු', tamil: 'மீன்', category: 'Food & Drink'),
    'chicken': AacTranslation(english: 'Chicken', sinhala: 'කුකුල් මස්', tamil: 'கோழி இறைச்சி', category: 'Food & Drink'),
    'vegetable': AacTranslation(english: 'Vegetable', sinhala: 'එළවළු', tamil: 'காய்கறி', category: 'Food & Drink'),
    'potato': AacTranslation(english: 'Potato', sinhala: 'අල', tamil: 'உருளைக்கிழங்கு', category: 'Food & Drink'),
    'carrot': AacTranslation(english: 'Carrot', sinhala: 'කැරට්', tamil: 'கேரட்', category: 'Food & Drink'),
    'ice cream': AacTranslation(english: 'Ice Cream', sinhala: 'අයිස්ක්‍රීම්', tamil: 'ஐஸ்கிரீம்', category: 'Food & Drink'),
    'beverage': AacTranslation(english: 'Beverage', sinhala: 'බීම', tamil: 'பானம்', category: 'Food & Drink'),
    'juice': AacTranslation(english: 'Juice', sinhala: 'යුෂ', tamil: 'சாறு', category: 'Food & Drink'),
    'soup': AacTranslation(english: 'Soup', sinhala: 'සුප්', tamil: 'சூப்', category: 'Food & Drink'),
    'chocolate': AacTranslation(english: 'Chocolate', sinhala: 'චොකලට්', tamil: 'சாக்லேட்', category: 'Food & Drink'),
    'cup': AacTranslation(english: 'Cup', sinhala: 'කෝප්පය', tamil: 'கோப்பை', category: 'Food & Drink'),
    'mug': AacTranslation(english: 'Mug', sinhala: 'මග් එක', tamil: 'மக்', category: 'Food & Drink'),
    'bottle': AacTranslation(english: 'Bottle', sinhala: 'බෝතලය', tamil: 'பாட்டில்', category: 'Food & Drink'),
    'plate': AacTranslation(english: 'Plate', sinhala: 'පිඟාන', tamil: 'தட்டு', category: 'Food & Drink'),
    'dish': AacTranslation(english: 'Dish', sinhala: 'පිඟාන', tamil: 'தட்டு', category: 'Food & Drink'),
    'bowl': AacTranslation(english: 'Bowl', sinhala: 'බඳුන', tamil: 'கிண்ணம்', category: 'Food & Drink'),
    'spoon': AacTranslation(english: 'Spoon', sinhala: 'හැන්ද', tamil: 'கரண்டி', category: 'Food & Drink'),
    'fork': AacTranslation(english: 'Fork', sinhala: 'ගෑරුප්පුව', tamil: 'முட்கரண்டி', category: 'Food & Drink'),

    // === Animals & Nature ===
    'dog': AacTranslation(english: 'Dog', sinhala: 'බල්ලා', tamil: 'நாய்', category: 'Animals'),
    'puppy': AacTranslation(english: 'Puppy', sinhala: 'බලු පැටියා', tamil: 'நாய்க்குட்டி', category: 'Animals'),
    'cat': AacTranslation(english: 'Cat', sinhala: 'පූසා', tamil: 'பூனை', category: 'Animals'),
    'kitten': AacTranslation(english: 'Kitten', sinhala: 'පූස් පැටියා', tamil: 'பூனைக்குட்டி', category: 'Animals'),
    'bird': AacTranslation(english: 'Bird', sinhala: 'කුරුල්ලා', tamil: 'பறவை', category: 'Animals'),
    'cow': AacTranslation(english: 'Cow', sinhala: 'හරකා', tamil: 'பசு', category: 'Animals'),
    'elephant': AacTranslation(english: 'Elephant', sinhala: 'අලියා', tamil: 'யானை', category: 'Animals'),
    'horse': AacTranslation(english: 'Horse', sinhala: 'අශ්වයා', tamil: 'குதிரை', category: 'Animals'),
    'lion': AacTranslation(english: 'Lion', sinhala: 'සිංහයා', tamil: 'சிங்கம்', category: 'Animals'),
    'tiger': AacTranslation(english: 'Tiger', sinhala: 'කොටියා', tamil: 'புலி', category: 'Animals'),
    'monkey': AacTranslation(english: 'Monkey', sinhala: 'වඳුරා', tamil: 'குரங்கு', category: 'Animals'),
    'rabbit': AacTranslation(english: 'Rabbit', sinhala: 'හාවා', tamil: 'முயல்', category: 'Animals'),
    'duck': AacTranslation(english: 'Duck', sinhala: 'තාරාවා', tamil: 'வாத்து', category: 'Animals'),
    'butterfly': AacTranslation(english: 'Butterfly', sinhala: 'සමනලයා', tamil: 'பட்டாம்பூச்சி', category: 'Animals'),
    'animal': AacTranslation(english: 'Animal', sinhala: 'සතා', tamil: 'விலங்கு', category: 'Animals'),
    'pet': AacTranslation(english: 'Pet', sinhala: 'සුරතලා', tamil: 'செல்லப்பிராணி', category: 'Animals'),
    'tree': AacTranslation(english: 'Tree', sinhala: 'ගස', tamil: 'மரம்', category: 'Nature'),
    'flower': AacTranslation(english: 'Flower', sinhala: 'මල', tamil: 'பூ', category: 'Nature'),
    'plant': AacTranslation(english: 'Plant', sinhala: 'පැලය', tamil: 'செடி', category: 'Nature'),
    'grass': AacTranslation(english: 'Grass', sinhala: 'තණකොළ', tamil: 'புல்', category: 'Nature'),
    'sun': AacTranslation(english: 'Sun', sinhala: 'ඉර', tamil: 'சூரியன்', category: 'Nature'),
    'moon': AacTranslation(english: 'Moon', sinhala: 'හඳ', tamil: 'நிலா', category: 'Nature'),
    'star': AacTranslation(english: 'Star', sinhala: 'තරුව', tamil: 'நட்சத்திரம்', category: 'Nature'),
    'rain': AacTranslation(english: 'Rain', sinhala: 'වැස්ස', tamil: 'மழை', category: 'Nature'),

    // === Objects, Household & Learning ===
    'ball': AacTranslation(english: 'Ball', sinhala: 'බෝලය', tamil: 'பந்து', category: 'Toys & Learning'),
    'book': AacTranslation(english: 'Book', sinhala: 'පොත', tamil: 'புத்தகம்', category: 'Toys & Learning'),
    'pen': AacTranslation(english: 'Pen', sinhala: 'පෑන', tamil: 'பேனா', category: 'Toys & Learning'),
    'pencil': AacTranslation(english: 'Pencil', sinhala: 'පැන්සල', tamil: 'பென்சில்', category: 'Toys & Learning'),
    'paper': AacTranslation(english: 'Paper', sinhala: 'කොළය', tamil: 'தாள்', category: 'Toys & Learning'),
    'scissors': AacTranslation(english: 'Scissors', sinhala: 'කතුර', tamil: 'கத்தரிக்கோல்', category: 'Toys & Learning'),
    'toy': AacTranslation(english: 'Toy', sinhala: 'සෙල්ලම්බඩු', tamil: 'விளையாட்டுப்பொருள்', category: 'Toys & Learning'),
    'doll': AacTranslation(english: 'Doll', sinhala: 'බෝනික්කා', tamil: 'பொம்மை', category: 'Toys & Learning'),
    'chair': AacTranslation(english: 'Chair', sinhala: 'පුටුව', tamil: 'நாற்காலி', category: 'Household'),
    'table': AacTranslation(english: 'Table', sinhala: 'මේසය', tamil: 'மேசை', category: 'Household'),
    'desk': AacTranslation(english: 'Desk', sinhala: 'මේසය', tamil: 'மேசை', category: 'Household'),
    'bed': AacTranslation(english: 'Bed', sinhala: 'ඇඳ', tamil: 'படுக்கை', category: 'Household'),
    'couch': AacTranslation(english: 'Couch', sinhala: 'සෝෆාව', tamil: 'சோபா', category: 'Household'),
    'sofa': AacTranslation(english: 'Sofa', sinhala: 'සෝෆාව', tamil: 'சோபா', category: 'Household'),
    'door': AacTranslation(english: 'Door', sinhala: 'දොර', tamil: 'கதவு', category: 'Household'),
    'window': AacTranslation(english: 'Window', sinhala: 'ජනේලය', tamil: 'ஜன்னல்', category: 'Household'),
    'clock': AacTranslation(english: 'Clock', sinhala: 'ඔරලෝසුව', tamil: 'கடிகாரம்', category: 'Household'),
    'watch': AacTranslation(english: 'Watch', sinhala: 'අත් ඔරලෝසුව', tamil: 'கைக்கடிகாரம்', category: 'Household'),
    'phone': AacTranslation(english: 'Phone', sinhala: 'දුරකථනය', tamil: 'தொலைபேசி', category: 'Electronics'),
    'computer': AacTranslation(english: 'Computer', sinhala: 'පරිගණකය', tamil: 'கணினி', category: 'Electronics'),
    'laptop': AacTranslation(english: 'Laptop', sinhala: 'ලැප්ටොප් පරිගණකය', tamil: 'மடிக்கணினி', category: 'Electronics'),
    'television': AacTranslation(english: 'Television', sinhala: 'රූපවාහිනිය', tamil: 'தொலைக்காட்சி', category: 'Electronics'),
    'camera': AacTranslation(english: 'Camera', sinhala: 'කැමරාව', tamil: 'கேமரா', category: 'Electronics'),
    'lamp': AacTranslation(english: 'Lamp', sinhala: 'ලාම්පුව', tamil: 'விளக்கு', category: 'Household'),
    'light': AacTranslation(english: 'Light', sinhala: 'එළිය', tamil: 'ஒளி', category: 'Household'),
    'box': AacTranslation(english: 'Box', sinhala: 'පෙට්ටිය', tamil: 'பெட்டி', category: 'Household'),
    'bag': AacTranslation(english: 'Bag', sinhala: 'බෑගය', tamil: 'பை', category: 'Personal'),
    'backpack': AacTranslation(english: 'Backpack', sinhala: 'පසුම්බිය', tamil: 'முதுகுப்பை', category: 'Personal'),
    'glasses': AacTranslation(english: 'Glasses', sinhala: 'කණ්ණාඩි', tamil: 'கண்ணாடிகள்', category: 'Personal'),
    'umbrella': AacTranslation(english: 'Umbrella', sinhala: 'කුඩය', tamil: 'குடை', category: 'Personal'),
    'key': AacTranslation(english: 'Key', sinhala: 'යතුර', tamil: 'சாவி', category: 'Personal'),
    'mirror': AacTranslation(english: 'Mirror', sinhala: 'කැඩපත', tamil: 'கண்ணாடி', category: 'Household'),
    'soap': AacTranslation(english: 'Soap', sinhala: 'සබන්', tamil: 'சோப்பு', category: 'Personal Care'),
    'towel': AacTranslation(english: 'Towel', sinhala: 'තුවාය', tamil: 'துண்டு', category: 'Personal Care'),
    'toothbrush': AacTranslation(english: 'Toothbrush', sinhala: 'දත් බුරුසුව', tamil: 'பல் துலக்கி', category: 'Personal Care'),

    // === Clothing & Footwear ===
    'clothing': AacTranslation(english: 'Clothing', sinhala: 'ඇඳුම්', tamil: 'ஆடைகள்', category: 'Clothing'),
    'clothes': AacTranslation(english: 'Clothes', sinhala: 'ඇඳුම්', tamil: 'ஆடைகள்', category: 'Clothing'),
    'shirt': AacTranslation(english: 'Shirt', sinhala: 'කමිසය', tamil: 'சட்டை', category: 'Clothing'),
    't-shirt': AacTranslation(english: 'T-shirt', sinhala: 'ටී-ෂර්ට්', tamil: 'டி-சர்ட்', category: 'Clothing'),
    'pants': AacTranslation(english: 'Pants', sinhala: 'කලිසම', tamil: 'கால்சட்டை', category: 'Clothing'),
    'trousers': AacTranslation(english: 'Trousers', sinhala: 'කලිසම', tamil: 'கால்சட்டை', category: 'Clothing'),
    'shorts': AacTranslation(english: 'Shorts', sinhala: 'කොට කලිසම', tamil: 'அரைக்கால் சட்டை', category: 'Clothing'),
    'dress': AacTranslation(english: 'Dress', sinhala: 'ගවුම', tamil: 'கவுன்', category: 'Clothing'),
    'frock': AacTranslation(english: 'Frock', sinhala: 'ගවුම', tamil: 'கவுன்', category: 'Clothing'),
    'shoes': AacTranslation(english: 'Shoes', sinhala: 'සපත්තු', tamil: 'காலணிகள்', category: 'Footwear'),
    'shoe': AacTranslation(english: 'Shoe', sinhala: 'සපත්තුව', tamil: 'காலணி', category: 'Footwear'),
    'footwear': AacTranslation(english: 'Footwear', sinhala: 'සපත්තු', tamil: 'காலணிகள்', category: 'Footwear'),
    'slippers': AacTranslation(english: 'Slippers', sinhala: 'සෙරෙප්පු', tamil: 'செருப்பு', category: 'Footwear'),
    'sandals': AacTranslation(english: 'Sandals', sinhala: 'සෙරෙප්පු', tamil: 'செருப்பு', category: 'Footwear'),
    'socks': AacTranslation(english: 'Socks', sinhala: 'මේස්', tamil: 'காலுறைகள்', category: 'Clothing'),
    'hat': AacTranslation(english: 'Hat', sinhala: 'තොප්පිය', tamil: 'தொப்பி', category: 'Clothing'),
    'cap': AacTranslation(english: 'Cap', sinhala: 'තොප්පිය', tamil: 'தொப்பி', category: 'Clothing'),

    // === People & Family ===
    'mother': AacTranslation(english: 'Mother', sinhala: 'අම්මා', tamil: 'அம்மா', category: 'People'),
    'father': AacTranslation(english: 'Father', sinhala: 'තාත්තා', tamil: 'அப்பா', category: 'People'),
    'baby': AacTranslation(english: 'Baby', sinhala: 'බබා', tamil: 'குழந்தை', category: 'People'),
    'child': AacTranslation(english: 'Child', sinhala: 'ළමයා', tamil: 'குழந்தை', category: 'People'),
    'boy': AacTranslation(english: 'Boy', sinhala: 'පිරිමි ළමයා', tamil: 'சிறுவன்', category: 'People'),
    'girl': AacTranslation(english: 'Girl', sinhala: 'ගැහැණු ළමයා', tamil: 'சிறுமி', category: 'People'),
    'person': AacTranslation(english: 'Person', sinhala: 'පුද්ගලයා', tamil: 'நபர்', category: 'People'),
    'teacher': AacTranslation(english: 'Teacher', sinhala: 'ගුරුතුමී', tamil: 'ஆசிரியர்', category: 'People'),
    'doctor': AacTranslation(english: 'Doctor', sinhala: 'දොස්තර', tamil: 'மருத்துவர்', category: 'People'),
    'friend': AacTranslation(english: 'Friend', sinhala: 'යහළුවා', tamil: 'நண்பன்', category: 'People'),
    'brother': AacTranslation(english: 'Brother', sinhala: 'සහෝදරයා', tamil: 'சகோதரன்', category: 'People'),
    'sister': AacTranslation(english: 'Sister', sinhala: 'සහෝදරිය', tamil: 'சகோதரி', category: 'People'),

    // === Body Parts ===
    'hand': AacTranslation(english: 'Hand', sinhala: 'අත', tamil: 'கை', category: 'Body'),
    'leg': AacTranslation(english: 'Leg', sinhala: 'කකුල', tamil: 'கால்', category: 'Body'),
    'foot': AacTranslation(english: 'Foot', sinhala: 'පාදය', tamil: 'பாதம்', category: 'Body'),
    'face': AacTranslation(english: 'Face', sinhala: 'මුහුණ', tamil: 'முகம்', category: 'Body'),
    'eye': AacTranslation(english: 'Eye', sinhala: 'ඇස', tamil: 'கண்', category: 'Body'),
    'ear': AacTranslation(english: 'Ear', sinhala: 'කන', tamil: 'காது', category: 'Body'),
    'nose': AacTranslation(english: 'Nose', sinhala: 'නාසය', tamil: 'மூக்கு', category: 'Body'),
    'mouth': AacTranslation(english: 'Mouth', sinhala: 'කට', tamil: 'வாய்', category: 'Body'),
    'head': AacTranslation(english: 'Head', sinhala: 'හිස', tamil: 'தலை', category: 'Body'),

    // === Actions & Verbs ===
    'eat': AacTranslation(english: 'Eat', sinhala: 'කනවා', tamil: 'சாப்பிடு', category: 'Actions'),
    'drink': AacTranslation(english: 'Drink', sinhala: 'බොනවා', tamil: 'குடி', category: 'Actions'),
    'sleep': AacTranslation(english: 'Sleep', sinhala: 'නිදාගන්නවා', tamil: 'தூங்கு', category: 'Actions'),
    'play': AacTranslation(english: 'Play', sinhala: 'සෙල්ලම් කරනවා', tamil: 'விளையாடு', category: 'Actions'),
    'wash': AacTranslation(english: 'Wash', sinhala: 'හෝදනවා', tamil: 'கழுவு', category: 'Actions'),
    'bath': AacTranslation(english: 'Bath', sinhala: 'නානවා', tamil: 'குளி', category: 'Actions'),
    'walk': AacTranslation(english: 'Walk', sinhala: 'ඇවිදිනවා', tamil: 'நட', category: 'Actions'),
    'run': AacTranslation(english: 'Run', sinhala: 'දුවනවා', tamil: 'ஓடு', category: 'Actions'),
    'read': AacTranslation(english: 'Read', sinhala: 'කියවනවා', tamil: 'படி', category: 'Actions'),
    'write': AacTranslation(english: 'Write', sinhala: 'ලියනවා', tamil: 'எழுது', category: 'Actions'),
    'sit': AacTranslation(english: 'Sit', sinhala: 'වාඩිවෙනවා', tamil: 'உட்காரு', category: 'Actions'),
    'stand': AacTranslation(english: 'Stand', sinhala: 'හිටගන්නවා', tamil: 'நில்', category: 'Actions'),
    'go': AacTranslation(english: 'Go', sinhala: 'යනවා', tamil: 'போ', category: 'Actions'),
    'come': AacTranslation(english: 'Come', sinhala: 'එනවා', tamil: 'வா', category: 'Actions'),

    // === Feelings & Sensations ===
    'happy': AacTranslation(english: 'Happy', sinhala: 'සතුටුයි', tamil: 'மகிழ்ச்சி', category: 'Feelings'),
    'sad': AacTranslation(english: 'Sad', sinhala: 'දුකයි', tamil: 'வருத்தம்', category: 'Feelings'),
    'angry': AacTranslation(english: 'Angry', sinhala: 'තරහයි', tamil: 'கோபம்', category: 'Feelings'),
    'hungry': AacTranslation(english: 'Hungry', sinhala: 'බඩගිනියි', tamil: 'பசி', category: 'Feelings'),
    'thirsty': AacTranslation(english: 'Thirsty', sinhala: 'තිබහයි', tamil: 'தாகம்', category: 'Feelings'),
    'tired': AacTranslation(english: 'Tired', sinhala: 'මහන්සියි', tamil: 'களைப்பு', category: 'Feelings'),
    'pain': AacTranslation(english: 'Pain', sinhala: 'රිදෙනවා', tamil: 'வலி', category: 'Feelings'),
    'hurt': AacTranslation(english: 'Hurt', sinhala: 'රිදෙනවා', tamil: 'வலி', category: 'Feelings'),
    'sick': AacTranslation(english: 'Sick', sinhala: 'අසනීපයි', tamil: 'நோய்', category: 'Feelings'),
    'cold': AacTranslation(english: 'Cold', sinhala: 'සීතලයි', tamil: 'குளிர்', category: 'Feelings'),
    'hot': AacTranslation(english: 'Hot', sinhala: 'රස්නෙයි', tamil: 'சூடு', category: 'Feelings'),

    // === Places & Vehicles ===
    'home': AacTranslation(english: 'Home', sinhala: 'ගෙදර', tamil: 'வீடு', category: 'Places'),
    'house': AacTranslation(english: 'House', sinhala: 'නිවස', tamil: 'வீடு', category: 'Places'),
    'school': AacTranslation(english: 'School', sinhala: 'පාසල', tamil: 'பள்ளி', category: 'Places'),
    'hospital': AacTranslation(english: 'Hospital', sinhala: 'රෝහල', tamil: 'மருத்துவமனை', category: 'Places'),
    'room': AacTranslation(english: 'Room', sinhala: 'කාමරය', tamil: 'அறை', category: 'Places'),
    'car': AacTranslation(english: 'Car', sinhala: 'කාර් එක', tamil: 'கார்', category: 'Vehicles'),
    'bus': AacTranslation(english: 'Bus', sinhala: 'බස් එක', tamil: 'பேருந்து', category: 'Vehicles'),
    'bicycle': AacTranslation(english: 'Bicycle', sinhala: 'බයිසිකලය', tamil: 'மிதிவண்டி', category: 'Vehicles'),
    'bike': AacTranslation(english: 'Bike', sinhala: 'බයිසිකලය', tamil: 'மிதிவண்டி', category: 'Vehicles'),
    'train': AacTranslation(english: 'Train', sinhala: 'කෝච්චිය', tamil: 'ரயில்', category: 'Vehicles'),
    'van': AacTranslation(english: 'Van', sinhala: 'වෑන් එක', tamil: 'வேன்', category: 'Vehicles'),
    'tuk tuk': AacTranslation(english: 'Tuk Tuk', sinhala: 'ත්‍රිරෝද රථය', tamil: 'ஆட்டோ', category: 'Vehicles'),
  };

  static const Map<String, String> _vocabularyAliases = {
    'mom': 'mother',
    'mama': 'mother',
    'dad': 'father',
    'daddy': 'father',
    'infant': 'baby',
    'toddler': 'baby',
    'mobile phone': 'phone',
    'cell phone': 'phone',
    'smartphone': 'phone',
    'telephone': 'phone',
    'dining table': 'table',
    'seat': 'chair',
    'armchair': 'chair',
    'spectacles': 'glasses',
    'eyeglasses': 'glasses',
    'eyewear': 'glasses',
    'sunglasses': 'glasses',
    'automobile': 'car',
    'passenger car': 'car',
    'sneaker': 'shoes',
    'sneakers': 'shoes',
    'athletic shoe': 'shoes',
    'jeans': 'pants',
    'slacks': 'pants',
    'beverage': 'drink',
    'water bottle': 'bottle',
    'coffee cup': 'cup',
    'teacup': 'cup',
    'dinner plate': 'plate',
    'saucer': 'plate',
    'tableware': 'plate',
    'canine': 'dog',
    'feline': 'cat',
    'three wheeler': 'tuk tuk',
    'auto rickshaw': 'tuk tuk',
    'rickshaw': 'tuk tuk',
  };

  /// Safely normalizes input before dictionary lookup (case-insensitive, trims,
  /// strips articles like 'a', 'an', 'the', and removes punctuation).
  static String normalizeVocabularyLookup(String query) {
    var s = query.trim().toLowerCase();
    if (s.isEmpty) return '';
    s = s.replaceFirst(RegExp(r'^(a|an|the)\s+'), '');
    s = s.replaceAll(RegExp(r'[\(\)\.,!?;:"\-_]'), ' ').trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// Looks up verified trilingual AAC translations (English, Sinhala, Tamil) for [query].
  /// Returns null if no verified translation exists, strictly preventing any guessed translations.
  static AacTranslation? lookupTranslations(String query) {
    final normalized = normalizeVocabularyLookup(query);
    if (normalized.isEmpty) return null;

    final canonical = _vocabularyAliases[normalized] ?? normalized;
    final direct = _trilingualVocabulary[canonical];
    if (direct != null) return direct;

    // Handle common English regular plurals without modifying distinct words
    if (canonical.endsWith('s') && canonical.length > 3) {
      final singular = canonical.substring(0, canonical.length - 1);
      final singularMatch = _vocabularyAliases[singular] ?? singular;
      if (_trilingualVocabulary.containsKey(singularMatch)) {
        return _trilingualVocabulary[singularMatch];
      }
    }

    return null;
  }

  /// Read-only view of the verified trilingual AAC vocabulary.
  static Map<String, AacTranslation> get trilingualVocabulary => _trilingualVocabulary;
}

/// Represents a verified trilingual AAC concept with English, Sinhala, and Tamil labels.
class AacTranslation {
  final String english;
  final String sinhala;
  final String tamil;
  final String category;

  const AacTranslation({
    required this.english,
    required this.sinhala,
    required this.tamil,
    required this.category,
  });
}
