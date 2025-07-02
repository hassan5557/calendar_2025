import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? notes;
  final String? location;
  final String? contact;
  final String recurrenceType;
  final int recurrenceInterval;
  final DateTime? recurrenceEndDate;

  Event({
    String? id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.notes,
    this.location,
    this.contact,
    this.recurrenceType = 'one-time',
    this.recurrenceInterval = 1,
    this.recurrenceEndDate,
  }) : id = id ?? const Uuid().v4();

  Appointment toAppointment() {
    return Appointment(
      startTime: startTime,
      endTime: endTime,
      subject: subject,
      color: color,
      notes: notes,
      id: id,
      recurrenceRule: _getRecurrenceRule(),
      recurrenceExceptionDates: _getExceptionDates(),
    );
  }

  String? _getRecurrenceRule() {
    if (recurrenceType == 'one-time') return null;
    
    String rule = 'FREQ=${recurrenceType.toUpperCase()};INTERVAL=$recurrenceInterval';
    
    if (recurrenceEndDate != null) {
      rule += ';UNTIL=${_formatDateForRule(recurrenceEndDate!)}';
    }
    
    return rule;
  }

  String _formatDateForRule(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}T235959Z';
  }

  List<DateTime>? _getExceptionDates() {
    // You can implement this if you need to handle exceptions to recurrence
    return null;
  }

  static Event fromAppointment(Appointment appointment) {
    final rule = appointment.recurrenceRule ?? '';
    final recurrenceType = _parseRecurrenceType(rule);
    final interval = _parseRecurrenceInterval(rule);
    final endDate = _parseRecurrenceEndDate(rule);

    return Event(
      id: appointment.id as String?,
      subject: appointment.subject,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      color: appointment.color,
      notes: appointment.notes,
      location: appointment.location,
      recurrenceType: recurrenceType,
      recurrenceInterval: interval,
      recurrenceEndDate: endDate,
    );
  }

  static String _parseRecurrenceType(String rule) {
    if (rule.contains('FREQ=DAILY')) return 'daily';
    if (rule.contains('FREQ=WEEKLY')) return 'weekly';
    if (rule.contains('FREQ=MONTHLY')) return 'monthly';
    if (rule.contains('FREQ=YEARLY')) return 'yearly';
    return 'one-time';
  }

  static int _parseRecurrenceInterval(String rule) {
    try {
      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
      return intervalMatch != null ? int.parse(intervalMatch.group(1)!) : 1;
    } catch (e) {
      return 1;
    }
  }

  static DateTime? _parseRecurrenceEndDate(String rule) {
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
}