import 'package:flutter/material.dart';

enum ReminderFilter { all, today, upcoming, missed, completed }

class FilterBar extends StatelessWidget {
  final ReminderFilter selectedFilter;
  final ValueChanged<ReminderFilter> onChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  String _label(ReminderFilter filter) {
    switch (filter) {
      case ReminderFilter.all:
        return 'All';
      case ReminderFilter.today:
        return 'Today';
      case ReminderFilter.upcoming:
        return 'Upcoming';
      case ReminderFilter.missed:
        return 'Missed';
      case ReminderFilter.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: ReminderFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReminderFilter.values[index];

          return ChoiceChip(
            label: Text(_label(filter)),
            selected: selectedFilter == filter,
            onSelected: (_) => onChanged(filter),
          );
        },
      ),
    );
  }
}
