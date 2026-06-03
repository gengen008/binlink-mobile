import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Horizontal 14-day scroll date picker matching v1 style.
class DatePickerRow extends StatefulWidget {
  const DatePickerRow({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<DatePickerRow> createState() => _DatePickerRowState();
}

class _DatePickerRowState extends State<DatePickerRow> {
  late final ScrollController _scroll;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    final now = DateTime.now();
    _dates = List.generate(14, (i) => now.add(Duration(days: i)));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final date     = _dates[i];
          final selected = widget.selectedDate != null &&
              _isSameDay(widget.selectedDate!, date);
          final isToday  = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.steelBlue
                      : isToday
                          ? AppColors.skyBlue.withAlpha(100)
                          : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.steelBlue.withAlpha(60),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbr(date),
                    style: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.iceBlue
                          : isToday
                              ? AppColors.skyBlue
                              : AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.h4.copyWith(
                      color: selected ? AppColors.white : AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthAbbr(date),
                    style: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.iceBlue
                          : AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayAbbr(DateTime d) =>
      const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][d.weekday % 7];

  String _monthAbbr(DateTime d) =>
      const ['JAN','FEB','MAR','APR','MAY','JUN',
             'JUL','AUG','SEP','OCT','NOV','DEC'][d.month - 1];
}
