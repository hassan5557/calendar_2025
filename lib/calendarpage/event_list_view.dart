import 'package:flutter/material.dart';
import 'package:flutter_calendar99/event/event.dart';
import '../app_theme.dart';

class EventListView extends StatelessWidget {
  final List<Event> events;
  final DateTime selectedDate;
  final String searchQuery;
  final Function(Event) onShowDetails;
  final Function(Event) onEdit;
  final Function(Event) onDelete;
  final Function(Event) onStatusChange;
  final Map<String, String> eventStatus;

  const EventListView({
    super.key,
    required this.events,
    required this.selectedDate,
    required this.searchQuery,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
    required this.eventStatus,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        searchQuery.isNotEmpty
            ? "No matching events found"
            : "No events on ${selectedDate.toLocal().toString().split(' ')[0]}",
        style: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final status = eventStatus[event.id] ?? 'Pending';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: event.color.withOpacity(0.25),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const Icon(Icons.event, color: Colors.white),
        title: Row(
          children: [
            _buildEventColorIndicator(event.color),
            Expanded(
              child: Text(
                event.subject,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: _buildActionButtons(event, status),
      ),
    );
  }

  Widget _buildEventColorIndicator(Color color) {
    return Container(
      width: 4,
      height: 20,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildActionButtons(Event event, String status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'Details',
          onPressed: () => onShowDetails(event),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blueAccent),
          tooltip: 'Modify',
          onPressed: () => onEdit(event),
        ),
        _buildStatusButton(event, status),
      ],
    );
  }

  Widget _buildStatusButton(Event event, String status) {
    return TextButton(
      onPressed: () => onStatusChange(event),
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.getStatusButtonColor(status),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.backgroundColor,
      child: events.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            ),
    );
  }
}