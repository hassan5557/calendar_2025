import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

bool isDarkTheme(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

// Core Form Components
Widget buildTextField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  int maxLines = 1,
  Widget? suffixIcon,
}) {
  final textColor = isDarkTheme(context) ? Colors.white : Colors.black;
  final borderColor = isDarkTheme(context) ? Colors.grey : Colors.grey[300]!;
  
  return TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textColor),
      ),
    ),
    style: TextStyle(color: textColor),
    cursorColor: textColor,
  );
}

// Time Picker Components
Widget buildTimeInputField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onTimeSelected,
}) {
  return buildTextField(
    context,
    label,
    controller,
    suffixIcon: IconButton(
      icon: const Icon(Icons.access_time),
      onPressed: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (time != null) onTimeSelected(time);
      },
    ),
  );
}

// Item List Components
Widget buildItemListField({
  required BuildContext context,
  required List<Map<String, dynamic>> items,
  required bool hasCheckbox,
  required VoidCallback onAddItem,
  required Function(int) onDeleteItem,
  required double totalPrice,
}) {
  final textColor = isDarkTheme(context) ? Colors.white : Colors.black;
  
  return Column(
    children: [
      ...List.generate(items.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (hasCheckbox)
                Checkbox(
                  value: items[index]['done'] ?? false,
                  onChanged: (val) => items[index]['done'] = val,
                ),
              Expanded(
                child: buildTextField(
                  context,
                  'Item Name',
                  items[index]['name'],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: buildTextField(
                  context,
                  'Price',
                  items[index]['price'],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDeleteItem(index),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 16),
      Row(
        children: [
          TextButton.icon(
            icon: Icon(Icons.add, color: textColor),
            label: Text('Add Item', style: TextStyle(color: textColor)),
            onPressed: onAddItem,
          ),
          const Spacer(),
          Text(
            "Total: \$${totalPrice.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    ],
  );
}

// Recurrence Components
Widget buildRecurrenceSelector({
  required BuildContext context,
  required String recurrenceType,
  required ValueChanged<String?> onTypeChanged,
  required int recurrenceInterval,
  required ValueChanged<String> onIntervalChanged,
  required DateTime? recurrenceEndDate,
  required Function(DateTime) onEndDateSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Recurrence Pattern', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: recurrenceType,
        items: const [
          DropdownMenuItem(value: 'one-time', child: Text('One-time event')),
          DropdownMenuItem(value: 'daily', child: Text('Daily')),
          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
        ],
        onChanged: onTypeChanged,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      if (recurrenceType != 'one-time') ...[
        const SizedBox(height: 16),
        TextFormField(
          initialValue: recurrenceInterval.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Repeat every',
            suffixText: _getIntervalSuffix(recurrenceType, recurrenceInterval),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onIntervalChanged,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: recurrenceEndDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 5),
            );
            if (pickedDate != null) {
              onEndDateSelected(pickedDate);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Ends on',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recurrenceEndDate != null
                      ? DateFormat('EEEE, M/d/y').format(recurrenceEndDate!)
                      : 'Select end date',
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

String _getIntervalSuffix(String type, int interval) {
  switch (type) {
    case 'daily': return interval == 1 ? 'day' : 'days';
    case 'weekly': return interval == 1 ? 'week' : 'weeks';
    case 'monthly': return interval == 1 ? 'month' : 'months';
    case 'yearly': return interval == 1 ? 'year' : 'years';
    default: return '';
  }
}

// Dialog Structure Components
Widget buildEventDialog({
  required BuildContext context,
  required bool isEditing,
  required Widget child,
  required VoidCallback onDelete,
  required VoidCallback onCancel,
  required VoidCallback onSave,
}) {
  return Dialog(
    backgroundColor: isDarkTheme(context) ? Colors.grey[900] : Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              isEditing ? 'Edit Event' : 'Add Event',
              style: TextStyle(
                fontSize: 20,
                color: isDarkTheme(context) ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isEditing)
                  TextButton(
                    onPressed: onDelete,
                    child: const Text("Delete"),
                  ),
                TextButton(
                  onPressed: onCancel,
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: onSave,
                  child: const Text("Save"),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Color Picker Components
void showColorPickerDialog(
  BuildContext context,
  Color selectedColor,
  ValueChanged<Color> onColorPicked,
) {
  final List<Color> colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.brown,
    Colors.grey,
  ];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: isDarkTheme(context) ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Pick a Color",
        style: TextStyle(color: isDarkTheme(context) ? Colors.white : Colors.black),
      ),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: colorOptions
            .map((color) => GestureDetector(
                  onTap: () {
                    onColorPicked(color);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 20,
                    child: selectedColor == color 
                        ? const Icon(Icons.check, color: Colors.white) 
                        : null,
                  ),
                ))
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: isDarkTheme(context) ? Colors.white : Colors.black),
          ),
        ),
      ],
    ),
  );
}

Widget buildColorButton(VoidCallback onPressed, Color selectedColor) {
  return TextButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.color_lens, color: Colors.white),
    label: const Text("Choose Color", style: TextStyle(color: Colors.white)),
    style: TextButton.styleFrom(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white),
      ),
    ),
  );
}

// Map Picker Screen
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLatLng;
  String _address = 'Tap on the map to select a location';

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(33.8938, 35.5018),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              onTap: _onTap,
              markers: _pickedLatLng != null
                  ? {
                      Marker(
                        markerId: const MarkerId('picked'),
                        position: _pickedLatLng!,
                      )
                    }
                  : {},
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text(
              _address,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTap(LatLng latLng) async {
    setState(() {
      _pickedLatLng = latLng;
      _address = 'Loading address...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Error loading address';
      });
    }
  }

  void _onConfirm() {
    if (_pickedLatLng != null && _address.isNotEmpty) {
      Navigator.pop(context, _address);
    }
  }
}