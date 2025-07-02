import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'event_ui.dart';
import 'event.dart';
import 'package:intl/intl.dart';

class EventDialog extends StatefulWidget {
  final DateTime date;
  final Event? existing;

  const EventDialog({super.key, required this.date, this.existing});

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late String _selectedSubject;
  late TextEditingController _locationController;
  late TextEditingController _noteController;
  late TextEditingController _contactController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  Color _selectedColor = Colors.blue;
  final List<Map<String, dynamic>> _items = [];
  String _recurrenceType = 'one-time';
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;

  final List<String> subjects = [
    'Appointment',
    'Meeting',
    'Order Time',
    'Subscription',
    'To Do List',
    'Shopping List',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _selectedSubject = widget.existing?.subject ?? subjects.first;
    _locationController = TextEditingController(text: widget.existing?.location ?? "");
    _noteController = TextEditingController(text: widget.existing?.notes ?? "");
    _contactController = TextEditingController(text: widget.existing?.contact ?? "");

    final now = TimeOfDay.fromDateTime(widget.date);
    _startTime = widget.existing != null
        ? TimeOfDay.fromDateTime(widget.existing!.startTime)
        : now;
    _endTime = widget.existing != null
        ? TimeOfDay.fromDateTime(widget.existing!.endTime)
        : now.replacing(hour: (now.hour + 1) % 24);

    _startTimeController = TextEditingController(text: _formatTimeOfDay(_startTime));
    _endTimeController = TextEditingController(text: _formatTimeOfDay(_endTime));

    _selectedColor = widget.existing?.color ?? Colors.blue;
    _recurrenceType = widget.existing?.recurrenceType ?? 'one-time';
    _recurrenceInterval = widget.existing?.recurrenceInterval ?? 1;
    _recurrenceEndDate = widget.existing?.recurrenceEndDate;

    _initializeItemsFromExisting();
  }

  void _initializeItemsFromExisting() {
    if (widget.existing != null &&
        (_selectedSubject == 'Order Time' ||
            _selectedSubject == 'Subscription' ||
            _selectedSubject == 'To Do List' ||
            _selectedSubject == 'Shopping List')) {
      final lines = widget.existing!.notes?.split('\n') ?? [];
      for (var line in lines) {
        if (line.trim().toLowerCase().startsWith('total:')) continue;
        final parts = line.split(' - \$');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          String pricePart = parts[1].trim();
          bool done = false;
          if (_selectedSubject == 'To Do List' || _selectedSubject == 'Shopping List') {
            final priceParts = pricePart.split(' - ');
            pricePart = priceParts[0].trim();
            if (priceParts.length > 1) {
              done = priceParts[1].toLowerCase() == 'done';
            }
          }
          final nameController = TextEditingController(text: name);
          final priceController = TextEditingController(text: pricePart);
          priceController.addListener(() => setState(() {}));
          _items.add({
            'name': nameController,
            'price': priceController,
            if (_selectedSubject == 'To Do List' || _selectedSubject == 'Shopping List') 'done': done,
          });
        }
      }
      if (_items.isNotEmpty) {
        final nonProductLines = lines.takeWhile((line) => !line.contains(' - \$')).toList();
        _noteController.text = nonProductLines.join('\n');
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['price']!.text) ?? 0.0);
    });
  }

  void _addItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    priceController.addListener(() => setState(() {}));
    setState(() {
      _items.add({
        'name': nameController,
        'price': priceController,
        if (_selectedSubject == 'To Do List' || _selectedSubject == 'Shopping List') 'done': false,
      });
    });
  }

  void _showColorPickerDialog() {
    showColorPickerDialog(context, _selectedColor, (color) => setState(() => _selectedColor = color));
  }

  Future<void> _selectContact() async {
    try {
      final Contact? contact = await ContactsService.openDeviceContactPicker();
      if (contact != null) {
        setState(() {
          _contactController.text = contact.displayName ?? '';
          if (contact.phones != null && contact.phones!.isNotEmpty) {
            _contactController.text += ' (${contact.phones!.first.value})';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to select contact')),
      );
    }
  }

  Future<void> _selectEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null) {
      setState(() {
        _recurrenceEndDate = pickedDate;
      });
    }
  }

  Future<void> _pickLocation() async {
    final selectedAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      setState(() {
        _locationController.text = selectedAddress;
      });
    }
  }

  void _onSave() {
    final start = DateTime(widget.date.year, widget.date.month, widget.date.day, _startTime.hour, _startTime.minute);
    final end = DateTime(widget.date.year, widget.date.month, widget.date.day, _endTime.hour, _endTime.minute);

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    String notes = _noteController.text;
    if (_items.isNotEmpty) {
      notes += '\n${_items.map((item) {
        String doneText = '';
        if (_selectedSubject == 'To Do List' || _selectedSubject == 'Shopping List') {
          doneText = item['done'] == true ? ' - Done' : ' - Not Done';
        }
        return "${item['name']!.text} - \$${item['price']!.text}$doneText";
      }).join('\n')}';
      notes += '\nTotal: \$${totalPrice.toStringAsFixed(2)}';
    }

    final newEvent = Event(
      id: widget.existing?.id,
      subject: _selectedSubject,
      startTime: start,
      endTime: end,
      color: _selectedColor,
      location: _locationController.text,
      notes: notes,
      contact: _contactController.text,
      recurrenceType: _recurrenceType,
      recurrenceInterval: _recurrenceInterval,
      recurrenceEndDate: _recurrenceType != 'one-time' ? _recurrenceEndDate : null,
    );

    Navigator.pop(context, newEvent);
  }

  @override
  Widget build(BuildContext context) {
    return buildEventDialog(
      context: context,
      isEditing: widget.existing != null,
      onDelete: () => Navigator.pop(context, 'delete'),
      onCancel: () => Navigator.pop(context, null),
      onSave: _onSave,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            items: subjects.map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(subject),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSubject = val;
                  _items.clear();
                });
              }
            },
            decoration: const InputDecoration(labelText: 'Event Type'),
          ),
          const SizedBox(height: 16),
          buildTextField(
            context,
            'Contact',
            _contactController,
            suffixIcon: IconButton(
              icon: const Icon(Icons.contacts),
              onPressed: _selectContact,
            ),
          ),
          const SizedBox(height: 16),
          buildTextField(
            context,
            'Location',
            _locationController,
            suffixIcon: IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _pickLocation,
            ),
          ),
          const SizedBox(height: 16),
          buildTextField(
            context,
            'Note',
            _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: buildTimeInputField(
                  context: context,
                  controller: _startTimeController,
                  label: 'Start Time',
                  initialTime: _startTime,
                  onTimeSelected: (time) {
                    setState(() {
                      _startTime = time;
                      _startTimeController.text = _formatTimeOfDay(time);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildTimeInputField(
                  context: context,
                  controller: _endTimeController,
                  label: 'End Time',
                  initialTime: _endTime,
                  onTimeSelected: (time) {
                    setState(() {
                      _endTime = time;
                      _endTimeController.text = _formatTimeOfDay(time);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildRecurrenceSelector(
            context: context,
            recurrenceType: _recurrenceType,
            onTypeChanged: (val) {
              if (val != null) {
                setState(() {
                  _recurrenceType = val;
                });
              }
            },
            recurrenceInterval: _recurrenceInterval,
            onIntervalChanged: (val) {
              setState(() {
                _recurrenceInterval = int.tryParse(val) ?? 1;
              });
            },
            recurrenceEndDate: _recurrenceEndDate,
            onEndDateSelected: (date) {
              setState(() {
                _recurrenceEndDate = date;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedSubject == 'Order Time' ||
              _selectedSubject == 'Subscription' ||
              _selectedSubject == 'To Do List' ||
              _selectedSubject == 'Shopping List')
            buildItemListField(
              context: context,
              items: _items,
              hasCheckbox: _selectedSubject == 'To Do List' || _selectedSubject == 'Shopping List',
              onAddItem: _addItem,
              onDeleteItem: (index) {
                setState(() {
                  _items.removeAt(index);
                });
              },
              totalPrice: totalPrice,
            ),
          const SizedBox(height: 16),
          buildColorButton(_showColorPickerDialog, _selectedColor),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    _contactController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    for (var item in _items) {
      item['name']?.dispose();
      item['price']?.dispose();
    }
    super.dispose();
  }
}