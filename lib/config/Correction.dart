import 'package:flutter/material.dart';

class CorrectLabelDialog extends StatefulWidget {
  @override
  _CorrectLabelDialogState createState() => _CorrectLabelDialogState();
}

class _CorrectLabelDialogState extends State<CorrectLabelDialog> {
  String? _selectedLabel;

  final List<String> labels = [
    'Cardboard',
    'Glass',
    'Metal',
    'Paper',
    'Plastic',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select the Correct Label'),
      content: DropdownButton<String>(
        isExpanded: true,
        hint: Text("Choose category"),
        value: _selectedLabel,
        onChanged: (value) {
          setState(() {
            _selectedLabel = value;
          });
        },
        items: labels.map((label) {
          return DropdownMenuItem(value: label, child: Text(label));
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // cancel
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedLabel != null
              ? () => Navigator.pop(context, _selectedLabel)
              : null,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
