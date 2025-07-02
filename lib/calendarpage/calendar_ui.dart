import 'package:flutter/material.dart';
import 'package:flutter_calendar99/event/event.dart';
import 'package:flutter_calendar99/event/event_dialog.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../app_theme.dart';
import '../event/EventDataSource.dart';
import '../calendar_app_bar.dart';
import '../alltaskpage/all_tasks_page.dart';
import '../alltaskpage/done_tasks_page.dart';
import '../alltaskpage/delayed_tasks_page.dart';
import 'event_list_view.dart';

class CalendarUI extends StatelessWidget {
  final CalendarView view;
  final ValueNotifier<List<Event>> eventsNotifier;
  final List<Event> selectedDayEvents;
  final List<Event> filteredEvents;
  final DateTime selectedDate;
  final Map<String, String> eventStatus;
  final String searchQuery;
  final BuildContext context;
  final Function(DateTime) updateSelectedDayEvents;
  final Function(String) handleViewSelection;
  final Function(Event) showEventDetails;
  final Function(Event) handleEventEdit;
  final Function(Event) confirmDelete;
  final Function(Event) showStatusOptions;
  final Function(String) filterEvents;

  const CalendarUI({
    required this.view,
    required this.eventsNotifier,
    required this.selectedDayEvents,
    required this.filteredEvents,
    required this.selectedDate,
    required this.eventStatus,
    required this.searchQuery,
    required this.context,
    required this.updateSelectedDayEvents,
    required this.handleViewSelection,
    required this.showEventDetails,
    required this.handleEventEdit,
    required this.confirmDelete,
    required this.showStatusOptions,
    required this.filterEvents,
    Key? key,
  }) : super(key: key);

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
    if (date.weekday != event.startTime.weekday) {
      return false;
    }
    final weeksBetween = (date.difference(event.startTime).inDays / 7).floor();
    return weeksBetween % event.recurrenceInterval == 0;
  }

  bool _isMonthlyRecurrence(Event event, DateTime date) {
    if (date.day != event.startTime.day) {
      return false;
    }
    final monthsBetween = (date.year - event.startTime.year) * 12 + 
        (date.month - event.startTime.month);
    return monthsBetween % event.recurrenceInterval == 0;
  }

  bool _isYearlyRecurrence(Event event, DateTime date) {
    if (date.month != event.startTime.month || date.day != event.startTime.day) {
      return false;
    }
    final yearsBetween = date.year - event.startTime.year;
    return yearsBetween % event.recurrenceInterval == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.customDarkTheme,
      child: Scaffold(
        appBar: CalendarAppBar(
          currentView: view,
          eventsNotifier: eventsNotifier,
          onViewSelected: handleViewSelection,
          onSearch: filterEvents,
        ),
        body: ValueListenableBuilder<List<Event>>(
          valueListenable: eventsNotifier,
          builder: (context, events, _) {
            final displayEvents = filteredEvents.isNotEmpty ? filteredEvents : events;
            
            if (view == CalendarView.month) {
              return _buildMonthView(displayEvents);
            } else if (view == CalendarView.schedule) {
              return AllTasksPage(
                events: displayEvents,
                onEdit: handleEventEdit,
                onDelete: confirmDelete,
                onStatusChange: showStatusOptions,
                eventStatus: eventStatus,
              );
            } else if (view == CalendarView.day) {
              return DoneTasksPage(
                events: displayEvents,
                onEdit: handleEventEdit,
                onDelete: confirmDelete,
                onStatusChange: showStatusOptions,
                eventStatus: eventStatus,
              );
            } else if (view == CalendarView.week) {
              return DelayedTasksPage(
                events: displayEvents,
                onEdit: handleEventEdit,
                onDelete: confirmDelete,
                onStatusChange: showStatusOptions,
                eventStatus: eventStatus,
              );
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () async {
            final result = await showDialog<Event>(
              context: context,
              builder: (ctx) => Theme(
                data: AppTheme.customDarkTheme,
                child: EventDialog(date: selectedDate, existing: null),
              ),
            );
            if (result != null) {
              final currentList = List<Event>.from(eventsNotifier.value);
              currentList.add(result);
              eventsNotifier.value = currentList;
              updateSelectedDayEvents(result.startTime);
            }
          },
          tooltip: "Add Event",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMonthView(List<Event> displayEvents) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: SfCalendar(
            view: view,
            dataSource: EventDataSource(displayEvents),
            showNavigationArrow: true,
            backgroundColor: AppTheme.backgroundColor,
            cellBorderColor: Colors.transparent,
            headerStyle: const CalendarHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.transparent,
            ),
            todayHighlightColor: Colors.transparent,
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.none,
              showAgenda: false,
            ),
            monthCellBuilder: (context, details) {
              final date = details.date;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              final dayEvents = displayEvents.where((event) {
                if (event.recurrenceType != 'one-time') {
                  return _isDateInRecurrence(event, date);
                }
                return event.startTime.year == date.year &&
                    event.startTime.month == date.month &&
                    event.startTime.day == date.day;
              }).toList();

              final focusedDate = details.visibleDates[details.visibleDates.length ~/ 2];
              final isCurrentMonth = date.month == focusedDate.month && date.year == focusedDate.year;

              return GestureDetector(
                onTap: () => updateSelectedDayEvents(date),
                child: Container(
                  height: 60,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isToday)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrentMonth ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: dayEvents.take(5).map((event) {
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: event.color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onTap: (details) {
              final date = details.date ?? DateTime.now();
              updateSelectedDayEvents(date);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: EventListView(
            events: selectedDayEvents,
            selectedDate: selectedDate,
            searchQuery: searchQuery,
            onShowDetails: showEventDetails,
            onEdit: handleEventEdit,
            onDelete: confirmDelete,
            onStatusChange: showStatusOptions,
            eventStatus: eventStatus,
          ),
        ),
      ],
    );
  }

  static void showEventDetailsDialog({
    required BuildContext context,
    required Event event,
    required Map<String, String> eventStatus,
    required String Function(DateTime) formatTime,
    required String Function(Event) formatRecurrence,
    required Function(Event) handleEventEdit,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.customDarkTheme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.subject,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (eventStatus[event.id] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(eventStatus[event.id]!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.getStatusColor(eventStatus[event.id]!),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    eventStatus[event.id]!.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.getStatusColor(eventStatus[event.id]!),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                title: 'Time',
                content: '${formatTime(event.startTime)} - ${formatTime(event.endTime)}',
              ),
              
              const SizedBox(height: 12),
              
              _buildDetailRow(
                icon: Icons.repeat_outlined,
                title: 'Recurrence',
                content: formatRecurrence(event),
              ),
              
              const SizedBox(height: 12),
              
              if (event.location?.isNotEmpty ?? false) 
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  content: event.location!,
                ),
              
              const SizedBox(height: 12),
              
              if (event.contact?.isNotEmpty ?? false) 
                _buildDetailRow(
                  icon: Icons.contact_phone_outlined,
                  title: 'Contact',
                  content: event.contact!,
                ),
              
              const SizedBox(height: 12),
              
              if (event.notes?.isNotEmpty ?? false) 
                _buildDetailRow(
                  icon: Icons.notes_outlined,
                  title: 'Notes',
                  content: event.notes!,
                  isMultiline: true,
                ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      handleEventEdit(event);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}