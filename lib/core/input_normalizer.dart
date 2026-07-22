/// Converts natural user input into a consistent form before intent analysis.
///
/// This class deliberately does not decide what the user wants. It only
/// removes harmless variation such as capitalization, punctuation, spacing,
/// common abbreviations, and frequent spelling variants.
class InputNormalizer {
  const InputNormalizer();

  static final List<MapEntry<RegExp, String>> _replacements = [
    MapEntry(RegExp(r'[‘’`´]'), "'"),
    MapEntry(RegExp(r'[“”]'), '"'),
    MapEntry(RegExp(r'[–—]'), '-'),

    // Conversational contractions and shorthand.
    MapEntry(RegExp(r"\b(what's|whats)\b"), 'what is'),
    MapEntry(RegExp(r"\b(who's|whos)\b"), 'who is'),
    MapEntry(RegExp(r"\b(where's|wheres)\b"), 'where is'),
    MapEntry(RegExp(r"\b(when's|whens)\b"), 'when is'),
    MapEntry(RegExp(r"\b(can't|cant)\b"), 'cannot'),
    MapEntry(RegExp(r"\b(won't|wont)\b"), 'will not'),
    MapEntry(RegExp(r"\b(don't|dont)\b"), 'do not'),
    MapEntry(RegExp(r"\b(i'm|im)\b"), 'i am'),
    MapEntry(RegExp(r"\b(i've|ive)\b"), 'i have'),
    MapEntry(RegExp(r"\b(i'll|ill)\b"), 'i will'),
    MapEntry(RegExp(r'\bpls\b|\bplz\b'), 'please'),
    MapEntry(RegExp(r'\bthx\b|\bthanx\b'), 'thanks'),
    MapEntry(RegExp(r'\btmrw\b|\btomoro\b|\btomm?orow\b'), 'tomorrow'),
    MapEntry(RegExp(r'\bmsg\b'), 'message'),
    MapEntry(RegExp(r'\bappt\b'), 'appointment'),

    // Dates and schedules.
    MapEntry(RegExp(r"\b(today's|todays)\b"), 'today'),
    MapEntry(RegExp(r"\b(tomorrow's|tomorrows)\b"), 'tomorrow'),
    MapEntry(RegExp(r'\bto\s*day\b'), 'today'),
    MapEntry(RegExp(r'\bto\s*morrow\b'), 'tomorrow'),
    MapEntry(RegExp(r'\bto do\b'), 'todo'),
    MapEntry(RegExp(r'\bshed\s*ule\b'), 'schedule'),
    MapEntry(RegExp(r'\bschedules\b'), 'schedule'),
    MapEntry(RegExp(r'\breminders\b'), 'reminder'),
    MapEntry(RegExp(r'\btasks\b'), 'task'),

    // Communication applications and actions.
    MapEntry(RegExp(r'\bwhats\s*app\b|\bwhat\s*app\b'), 'whatsapp'),
    MapEntry(RegExp(r'\bcall up\b|\bphone up\b'), 'call'),
    MapEntry(RegExp(r'\bsend a message to\b'), 'message'),

    // Frequently used Indian document names.
    MapEntry(RegExp(r'\b(aadhar|adhar)\b'), 'aadhaar'),
    MapEntry(RegExp(r'\buid card\b'), 'aadhaar card'),
    MapEntry(RegExp(r'\bpancard\b'), 'pan card'),
    MapEntry(RegExp(r'\bdriving license\b'), 'driving licence'),
    MapEntry(RegExp(r'\bdrivers? license\b'), 'driving licence'),
    MapEntry(RegExp(r'\bdl\b'), 'driving licence'),
    MapEntry(RegExp(r'\bvoter card\b'), 'voter id'),

    // Common life-event spelling variations.
    MapEntry(RegExp(r'\bannivers+ary\b|\bannivarsary\b|\banniversary\b'), 'anniversary'),
    MapEntry(RegExp(r'\bbirth\s*day\b'), 'birthday'),
  ];

  String normalize(String input) {
    var text = input.toLowerCase().trim();

    for (final replacement in _replacements) {
      text = text.replaceAll(replacement.key, replacement.value);
    }

    // Keep English, Bengali and Devanagari text. Replace decorative
    // punctuation with spaces while retaining apostrophes during processing.
    text = text.replaceAll(
      RegExp(r"[^a-z0-9\u0980-\u09ff\u0900-\u097f'\s:/.-]"),
      ' ',
    );

    // Punctuation that separates words should not merge them.
    text = text.replaceAll(RegExp(r'[,:/.-]+'), ' ');
    text = text.replaceAll("'", '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }
}