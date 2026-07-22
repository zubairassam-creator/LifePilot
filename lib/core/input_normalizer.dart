class InputNormalizer {
  const InputNormalizer();

  String normalize(String input) {
    var text = input.toLowerCase();
    text = text.replaceAll(RegExp(r'[‘’`´]'), "'");
    text = text.replaceAll(RegExp(r"\b(what's|whats)\b"), 'what is');
    text = text.replaceAll(RegExp(r"\b(today's|todays)\b"), 'today');
    text = text.replaceAll(RegExp(r"\b(tomorrow's|tomorrows)\b"), 'tomorrow');
    text = text.replaceAll(RegExp(r'\b(aadhar|adhar)\b'), 'aadhaar');
    text = text.replaceAll(RegExp(r'\buid card\b'), 'aadhaar card');
    text = text.replaceAll(RegExp(r'\bpancard\b'), 'pan card');
    text = text.replaceAll(RegExp(r'\bdriving license\b'), 'driving licence');
    text = text.replaceAll(RegExp(r'\bdrivers? license\b'), 'driving licence');
    text = text.replaceAll(RegExp(r'\bdl\b'), 'driving licence');
    text = text.replaceAll(RegExp(r'\bvoter card\b'), 'voter id');
    text = text.replaceAll(RegExp(r"\bdont\b"), "don't");
    text = text.replaceAll(RegExp(r"\bto do\b"), 'todo');
    text = text.replaceAll(RegExp(r"\bshed ule\b"), 'schedule');
    text = text.replaceAll(RegExp(r"\bschedules\b"), 'schedule');
    text = text.replaceAll(RegExp(r"\breminders\b"), 'reminder');
    text = text.replaceAll(RegExp(r"\btasks\b"), 'task');
    text = text.replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ');
    text = text.replaceAll("don't", 'do not');
    text = text.replaceAll("'", '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }
}
