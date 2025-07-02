import 'package:flutter/material.dart';
import '../event/event.dart';
import '../app_theme.dart';

class DelayedTasksPage extends StatelessWidget {
  final List<Event> events;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final Function(Event) onStatusChange;
  final Map<String, String> eventStatus;

  const DelayedTasksPage({
    super.key,
    required this.events,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
    required this.eventStatus,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDay(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${date.day} ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final delayedEvents = events.where((event) => 
        eventStatus[event.id]?.toLowerCase() == 'delay').toList();

    final Map<DateTime, List<Event>> eventsByDate = {};
    for (final event in delayedEvents) {
      final date = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      eventsByDate.putIfAbsent(date, () => []).add(event);
    }

    final sortedDates = eventsByDate.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: delayedEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule_outlined, 
                      // ignore: deprecated_member_use
                      size: 48, color: Colors.orange.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No delayed tasks yet',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, dateIndex) {
                final date = sortedDates[dateIndex];
                final dailyEvents = eventsByDate[date]!
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        _formatDay(date),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: dailyEvents.length,
                      itemBuilder: (context, index) {
                        final event = dailyEvents[index];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showEventDetails(context, event),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: Colors.grey[900]?.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: event.color,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatTime(event.startTime),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatTime(event.endTime),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            // ignore: deprecated_member_use
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.orange,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: const Text(
                                            'DELAYED',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.subject,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (event.location != null && event.location!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                event.location!,
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      color: Colors.grey[400],
                                      onPressed: () => _showActionMenu(context, event),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),
                  ],
                );
              },
            ),
    );
  }

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange,
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'DELAYED',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: Icons.access_time,
                title: 'Time',
                content: '${_formatDay(event.startTime)} ${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
              ),
              if (event.location != null && event.location!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: event.location!,
                ),
              if (event.notes != null && event.notes!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.notes,
                  title: 'Notes',
                  content: event.notes!,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit(event);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                    ),
                    child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onEdit(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Done', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onStatusChange(event);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(event);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}