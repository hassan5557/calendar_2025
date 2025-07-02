import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'event.dart';

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> appointments) {
    this.appointments = appointments;
  }

  List<DateTime>? getRecurrenceDateTime(DateTime date, String? rule, String? type, int interval) {
    if (type == null || type == 'one-time') return null;

    final recurrenceDates = <DateTime>[];
    final currentDate = date;
    final endDate = _getRecurrenceEndDate(rule) ?? currentDate.add(const Duration(days: 365 * 2));

    DateTime nextDate = currentDate;
    while (nextDate.isBefore(endDate)) {
      recurrenceDates.add(nextDate);
      
      switch (type) {
        case 'daily':
          nextDate = nextDate.add(Duration(days: interval));
          break;
        case 'weekly':
          nextDate = nextDate.add(Duration(days: 7 * interval));
          break;
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + interval, nextDate.day);
          break;
        case 'yearly':
          nextDate = DateTime(nextDate.year + interval, nextDate.month, nextDate.day);
          break;
        default:
          return null;
      }
    }

    return recurrenceDates;
  }

  DateTime? _getRecurrenceEndDate(String? rule) {
    if (rule == null) return null;
    try {
      final untilMatch = RegExp(r'UNTIL=(\d+)').firstMatch(rule);
      if (untilMatch != null) {
        final dateStr = untilMatch.group(1)!;
        return DateTime.parse(dateStr.substring(0, 8));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  DateTime getRecurrenceStartDate(DateTime date) => date;

  DateTime getRecurrenceEndDate(DateTime date) => date.add(const Duration(days: 365 * 2));
}