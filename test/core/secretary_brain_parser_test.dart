import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/date_time_interpreter.dart';

void main() {
  test('interprets future month-day dates without inventing past years', () {
    const interpreter = DateTimeInterpreter(now: DateTime(2026, 7, 18));

    final date = interpreter.dateFromText('My bike pollution expires on November 2nd');

    expect(date, DateTime(2026, 11, 2));
  });

  test('interprets reminder date and time', () {
    const interpreter = DateTimeInterpreter(now: DateTime(2026, 7, 18, 9));

    final date = interpreter.dateTimeFromText('Remind me tomorrow at 8 PM to call the bank');

    expect(date, DateTime(2026, 7, 19, 20));
  });

  test('interprets loan repayment relative duration', () {
    const interpreter = DateTimeInterpreter(now: DateTime(2026, 7, 18));

    final date = interpreter.dateFromText('repay it in two months');

    expect(date, DateTime(2026, 9, 18));
  });
}
