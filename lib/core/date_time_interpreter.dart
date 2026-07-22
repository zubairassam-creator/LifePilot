class DateTimeInterpreter {
  const DateTimeInterpreter({DateTime? now}) : _fixedNow = now;

  final DateTime? _fixedNow;
  DateTime get now => _fixedNow ?? DateTime.now();

  DateTime? dateFromText(String text) {
    final lower = text.toLowerCase();
    final base = DateTime(now.year, now.month, now.day);
    if (lower.contains('today')) return base;
    if (lower.contains('tomorrow')) return base.add(const Duration(days: 1));

    final inMonths = RegExp(
      r'\bin (\d+|one|two|three|four|five|six) months?\b',
    ).firstMatch(lower);
    if (inMonths != null) {
      final months = _number(inMonths.group(1)!);
      return DateTime(
        now.year,
        now.month + months,
        now.day,
        now.hour,
        now.minute,
      );
    }

    final monthDay = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(january|february|march|april|may|june|july|august|september|october|november|december)\b|\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?\b',
    ).firstMatch(lower);
    if (monthDay == null) return null;
    final day = int.parse(monthDay.group(1) ?? monthDay.group(4)!);
    final month = _month(monthDay.group(2) ?? monthDay.group(3)!);
    var date = DateTime(now.year, month, day);
    if (date.isBefore(base)) date = DateTime(now.year + 1, month, day);
    return date;
  }

  DateTime? dateTimeFromText(String text) {
    final date = dateFromText(text);
    if (date == null) return null;
    final match = RegExp(
      r'\b(?:at|by)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    ).firstMatch(text.toLowerCase());
    if (match == null) return date;
    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final meridian = match.group(3);
    if (meridian == 'pm' && hour < 12) hour += 12;
    if (meridian == 'am' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  int _number(String value) => switch (value) {
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    _ => int.parse(value),
  };

  int _month(String name) => const {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  }[name]!;
}
