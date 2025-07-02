import 'package:flutter/material.dart';
import 'package:flutter_calendar99/event/event.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../event/event_dialog.dart';
import '../app_theme.dart';
import 'calendar_ui.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarView _view = CalendarView.month;
  final ValueNotifier<List<Event>> _eventsNotifier = ValueNotifier([]);
  List<Event> _selectedDayEvents = [];
  List<Event> _filteredEvents = [];
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _eventStatus = {};
  String _searchQuery = '';

  void _updateSelectedDayEvents(DateTime selectedDate) {
    final allEvents = _filteredEvents.isNotEmpty ? _filteredEvents : _eventsNotifier.value;
    setState(() {
      _selectedDate = selectedDate;
      _selectedDayEvents = allEvents.where((event) {
        if (event.recurrenceType != 'one-time') {
          return _isDateInRecurrence(event, selectedDate);
        }
        final start = event.startTime;
        return start.year == selectedDate.year &&
            start.month == selectedDate.month &&
            start.day == selectedDate.day;
      }).toList();
    });
  }

  bool _isDateInRecurrence(Event event, DateTime date) {
    // Check if date is before the event's start date
    if (date.isBefore(event.startTime)) {
      return false;
    }

    // Check if recurrence has ended
    if (event.recurrenceEndDate != null && date.isAfter(event.recurrenceEndDate!)) {
      return false;
    }

    switch (event.recurrenceType) {
      case 'daily':
        return _isDailyRecurrence(event, date);
      case 'weekly':
        return _isWeeklyRecurrence(event, date);
      case 'monthly':
        return _isMonthlyRecurrence(event, date);
      case 'yearly':
        return _isYearlyRecurrence(event, date);
      default:
        return false;
    }
  }

  bool _isDailyRecurrence(Event event, DateTime date) {
    final daysBetween = date.difference(event.startTime).inDays;
    return daysBetween % event.recurrenceInterval == 0;
  }

  bool _isWeeklyRecurrence(Event event, DateTime date) {
    // Check if it's the same day of the week
    if (date.weekday != event.startTime.weekday) {
      return false;
    }
    
    // Calculate weeks between dates
    final startDate = event.startTime;
    final weeksBetween = (date.difference(startDate).inDays / 7).floor();
    return weeksBetween % event.recurrenceInterval == 0;
  }

  bool _isMonthlyRecurrence(Event event, DateTime date) {
    // Check if it's the same day of the month
    if (date.day != event.startTime.day) {
      return false;
    }
    
    // Calculate months between dates
    final monthsBetween = (date.year - event.startTime.year) * 12 +
        (date.month - event.startTime.month);
    return monthsBetween % event.recurrenceInterval == 0;
  }

  bool _isYearlyRecurrence(Event event, DateTime date) {
    // Check if it's the same month and day
    if (date.month != event.startTime.month || date.day != event.startTime.day) {
      return false;
    }
    
    // Calculate years between dates
    final yearsBetween = date.year - event.startTime.year;
    return yearsBetween % event.recurrenceInterval == 0;
  }

  // Rest of your existing methods remain the same...
  void _filterEvents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredEvents = _searchQuery.isEmpty
          ? []
          : _eventsNotifier.value.where((event) {
              return event.subject.toLowerCase().contains(_searchQuery) ||
                  (event.notes?.toLowerCase().contains(_searchQuery) ?? false) ||
                  (event.location?.toLowerCase().contains(_searchQuery) ?? false) ||
                  (event.contact?.toLowerCase().contains(_searchQuery) ?? false);
            }).toList();
      _updateSelectedDayEvents(_selectedDate);
    });
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedDayEvents(_selectedDate);
  }

  Future<bool?> _confirmDelete(Event event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${event.subject}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
    
    if (shouldDelete == true) {
      _deleteEvent(event);
    }
    return shouldDelete;
  }

  void _deleteEvent(Event event) {
    final currentList = List<Event>.from(_eventsNotifier.value);
    currentList.remove(event);
    _eventsNotifier.value = currentList;
    _eventStatus.remove(event.id);
    _updateSelectedDayEvents(_selectedDate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${event.subject}"'),
        backgroundColor: AppTheme.eventDeletedColor,
      ),
    );
  }

  void _modifyEvent(Event oldEvent, Event newEvent) {
    final currentList = List<Event>.from(_eventsNotifier.value);
    currentList.remove(oldEvent);
    currentList.add(newEvent);
    _eventsNotifier.value = currentList;
    _updateSelectedDayEvents(newEvent.startTime);
  }

  void _updateEventStatus(Event event, String status) {
    setState(() {
      _eventStatus[event.id] = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${event.subject}" as $status'),
        backgroundColor: AppTheme.getStatusColor(status),
      ),
    );
  }

  Future<void> _showStatusOptions(Event event) async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Update Status', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Select the new status for this event:',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('Done'),
            child: const Text('Done', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('Delay'),
            child: const Text('Delay', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('Cancelled'),
            child: const Text('Cancelled', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );

    if (status != null) {
      _updateEventStatus(event, status);
    }
  }

  void _handleViewSelection(String value) {
    setState(() {
      if (value == 'month') {
        _view = CalendarView.month;
      } else if (value == 'all_tasks') {
        _view = CalendarView.schedule;
      } else if (value == 'done') {
        _view = CalendarView.day;
      } else if (value == 'delayed') {
        _view = CalendarView.week;
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatRecurrence(Event event) {
    if (event.recurrenceType == 'one-time') return 'One-time event';
    String recurrenceText = 'Repeats ';
    if (event.recurrenceInterval > 1) {
      recurrenceText += 'every ${event.recurrenceInterval} ';
    }
    recurrenceText += event.recurrenceType;
    
    if (event.recurrenceEndDate != null) {
      recurrenceText += ' until ${event.recurrenceEndDate!.day}/${event.recurrenceEndDate!.month}/${event.recurrenceEndDate!.year}';
    }
    
    return recurrenceText;
  }

  Future<void> _handleEventEdit(Event event) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => Theme(
        data: AppTheme.customDarkTheme,
        child: EventDialog(
          date: event.startTime,
          existing: event,
        ),
      ),
    );
    if (result == 'delete') {
      await _confirmDelete(event);
    } else if (result is Event) {
      _modifyEvent(event, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalendarUI(
      view: _view,
      eventsNotifier: _eventsNotifier,
      selectedDayEvents: _selectedDayEvents,
      filteredEvents: _filteredEvents,
      selectedDate: _selectedDate,
      eventStatus: _eventStatus,
      searchQuery: _searchQuery,
      context: context,
      updateSelectedDayEvents: _updateSelectedDayEvents,
      handleViewSelection: _handleViewSelection,
      showEventDetails: _showEventDetails,
      handleEventEdit: _handleEventEdit,
      confirmDelete: _confirmDelete,
      showStatusOptions: _showStatusOptions,
      filterEvents: _filterEvents,
    );
  }

  void _showEventDetails(Event event) {
    CalendarUI.showEventDetailsDialog(
      context: context,
      event: event,
      eventStatus: _eventStatus,
      formatTime: _formatTime,
      formatRecurrence: _formatRecurrence,
      handleEventEdit: _handleEventEdit,
    );
  }
}