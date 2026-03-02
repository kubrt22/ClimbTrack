import 'dart:developer';

import 'package:climb_track/models/route_model.dart';
import 'package:flutter/material.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';

class RouteAddPage extends ConsumerStatefulWidget {
  const RouteAddPage({super.key});

  @override
  ConsumerState<RouteAddPage> createState() => _RouteAddPageState();
}

class _RouteAddPageState extends ConsumerState<RouteAddPage> {
  String _title = '';
  String _location = '';
  DifficultyType? _selectedType = DifficultyType.V_Scale;
  String _selectedValue = difficultyValues[DifficultyType.V_Scale]!.first;
  Color _selectedColor = Colors.black;
  DateTime _selectedDate = DateTime.now();
  ClimbType? _selectedClimbType;
  Set<ClimbStyle> _selectedClimbStyle = {};

  void _saveRoute(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      log("Form is not valid!");
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    final route = RouteModel(
      id: '',
      title: _title,
      location: _location,
      date: _selectedDate,
      climbType: _selectedClimbType ?? ClimbType.Boulder,
      climbStyle: _selectedClimbStyle.singleOrNull,
      difficulty: Difficulty(_selectedType!, _selectedValue),
      routeColor: _selectedColor,
      createdAt: DateTime.now(),
    );
    firestore.addRoute(user.uid, route);
    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    setState(() {
      _selectedDate = pickedDate ?? _selectedDate;
    });
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat cestu'),
        actions: [
          IconButton(
            onPressed: () => _saveRoute(context),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              TextFormField(
                onChanged: (value) => _title = value,
                decoration: InputDecoration(
                  labelText: 'Název cesty',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zadejte název cesty';
                  }
                  return null;
                },
              ),
              TextFormField(
                onChanged: (value) => _location = value,
                decoration: InputDecoration(
                  labelText: 'Místo',
                  border: OutlineInputBorder(),
                ),
              ),

              OutlinedButton(
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 56),
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  alignment: Alignment.centerLeft,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                onPressed: _selectDate,
                child: Text(
                  'Datum: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              DropdownButtonFormField<DifficultyType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Typ obtížnosti',
                  border: OutlineInputBorder(),
                ),
                items: DifficultyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(Difficulty(type, '').typeName),
                  );
                }).toList(),
                onChanged: (type) {
                  if (_selectedType == type) return;
                  setState(() {
                    _selectedType = type!;
                    _selectedValue = difficultyValues[type]!.first;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _selectedValue,
                decoration: InputDecoration(
                  labelText: 'Obtížnost',
                  border: OutlineInputBorder(),
                ),
                items: difficultyValues[_selectedType]!.map((value) {
                  return DropdownMenuItem(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedValue = value!;
                  });
                },
              ),

              TextFormField(
                initialValue: _selectedColor
                    .toARGB32()
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .toUpperCase(),
                onChanged: (value) {
                  try {
                    setState(() {
                      _selectedColor = Color(int.parse(value, radix: 16));
                    });
                  } catch (e) {
                    // Ignore invalid input
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Barva',
                  border: OutlineInputBorder(),
                  prefix: Text('#'),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
                ),
              ),
              DropdownButtonFormField(
                validator: (value) {
                  if (value == null) {
                    return 'Vyberte typ cesty';
                  }
                  return null;
                },
                initialValue: _selectedClimbType,
                decoration: InputDecoration(
                  labelText: 'Typ cesty',
                  border: OutlineInputBorder(),
                ),
                items: ClimbType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClimbType = value;
                  });
                },
              ),
              SegmentedButton(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                emptySelectionAllowed: true,
                segments: ClimbStyle.values.map((style) {
                  return ButtonSegment(value: style, label: Text(style.name));
                }).toList(),
                selected: _selectedClimbStyle,
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedClimbStyle = value;
                  });
                },
                multiSelectionEnabled: false,
              ),

              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Poznámky',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
