import 'package:flutter/material.dart';

Future<void> showBriefingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Today's Briefing"),
      content: const Text('Briefing popup is working.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
