import 'dart:developer';

import 'package:climb_track/models/route_model.dart';
import 'package:flutter/material.dart';
import 'package:climb_track/services/global_things.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class RouteAddPage extends ConsumerStatefulWidget {
  const RouteAddPage({super.key, this.initialRoute});

  final RouteModel? initialRoute;

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
  String _notes = '';
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final initialRoute = widget.initialRoute;
    if (initialRoute != null) {
      _title = initialRoute.title;
      _location = initialRoute.location;
      _locationController.text = initialRoute.location;
      _selectedType = initialRoute.difficulty.type;
      _selectedValue = initialRoute.difficulty.value;
      _selectedColor = initialRoute.routeColor;
      _selectedDate = initialRoute.date;
      _selectedClimbType = initialRoute.climbType;
      _selectedClimbStyle = initialRoute.climbStyle == null
          ? {}
          : {initialRoute.climbStyle!};
      _notes = initialRoute.notes;
    }

    _locationController.addListener(() {
      _location = _locationController.text.trim();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _saveRoute(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      log("Form is not valid!");
      return;
    }

    if (_selectedClimbType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vyberte typ cesty')));
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    final initialRoute = widget.initialRoute;
    final isEditing = initialRoute != null;
    final route = RouteModel(
      id: isEditing ? initialRoute.id : '',
      title: _title,
      location: _location,
      date: _selectedDate,
      climbType: _selectedClimbType!,
      climbStyle: _selectedClimbStyle.singleOrNull,
      difficulty: Difficulty(_selectedType!, _selectedValue),
      routeColor: _selectedColor,
      createdAt: isEditing ? initialRoute.createdAt : DateTime.now(),
      notes: _notes,
    );
    if (isEditing) {
      firestore.updateRoute(user.uid, route);
    } else {
      firestore.addRoute(user.uid, route);
    }
    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    _clearFocus();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    setState(() {
      _selectedDate = pickedDate ?? _selectedDate;
    });

    _clearFocus();
  }

  Future<void> _selectColor() async {
    _clearFocus();

    Color tempColor = _selectedColor;
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Vyberte barvu'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (color) {
                    setDialogState(() {
                      tempColor = color;
                    });
                  },
                  enableAlpha: false,
                  displayThumbColor: true,
                  pickerAreaBorderRadius: BorderRadius.all(Radius.circular(4)),
                  labelTypes: [],
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zrušit'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, tempColor),
                  child: const Text('Vybrat'),
                ),
              ],
            );
          },
        );
      },
    );

    if (pickedColor == null) return;
    setState(() {
      _selectedColor = pickedColor;
    });

    _clearFocus();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dropdownFieldTheme = Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
    final dropdownMenuStyle = MenuStyle(
      maximumSize: const WidgetStatePropertyAll(Size.fromHeight(280)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );
    final recentLocations = routesAsync.maybeWhen(
      data: (routes) {
        final uniqueKeys = <String>{};
        final values = <String>[];
        for (final route in routes) {
          final location = route.location.trim();
          if (location.isEmpty) continue;
          final key = location.toLowerCase();
          if (uniqueKeys.add(key)) {
            values.add(location);
          }
          if (values.length >= 8) break;
        }
        return values;
      },
      orElse: () => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRoute == null ? 'Přidat cestu' : 'Upravit cestu',
        ),
        actions: [
          IconButton(
            onPressed: () => _saveRoute(context),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _title,
                        onChanged: (value) => _title = value,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Název cesty',
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Zadejte název cesty';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: _selectColor,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Theme(
                      data: dropdownFieldTheme,
                      child: DropdownMenu<String>(
                        width: constraints.maxWidth,
                        controller: _locationController,
                        requestFocusOnTap: true,
                        enableFilter: true,
                        enableSearch: true,
                        label: const Text('Místo'),
                        hintText: recentLocations.isEmpty
                            ? 'Zadejte místo'
                            : 'Vyberte poslední nebo napište nové',
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                        menuStyle: dropdownMenuStyle,
                        trailingIcon: const Icon(
                          Icons.keyboard_arrow_down_sharp,
                        ),
                        selectedTrailingIcon: const Icon(
                          Icons.keyboard_arrow_up_sharp,
                        ),
                        dropdownMenuEntries: recentLocations
                            .map(
                              (location) => DropdownMenuEntry(
                                value: location,
                                label: location,
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          if (value == null) return;
                          _locationController.value = TextEditingValue(
                            text: value,
                            selection: TextSelection.collapsed(
                              offset: value.length,
                            ),
                          );
                          _location = value;
                        },
                      ),
                    );
                  },
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Theme(
                            data: dropdownFieldTheme,
                            child: DropdownMenu<DifficultyType>(
                              width: constraints.maxWidth,
                              initialSelection: _selectedType,
                              label: const Text('Typ obtížnosti'),
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                              menuStyle: dropdownMenuStyle,
                              trailingIcon: const Icon(
                                Icons.keyboard_arrow_down_sharp,
                              ),
                              selectedTrailingIcon: const Icon(
                                Icons.keyboard_arrow_up_sharp,
                              ),
                              dropdownMenuEntries: DifficultyType.values.map((
                                type,
                              ) {
                                return DropdownMenuEntry(
                                  value: type,
                                  label: Difficulty(type, '').typeName,
                                );
                              }).toList(),
                              onSelected: (type) {
                                if (type == null || _selectedType == type) {
                                  return;
                                }
                                setState(() {
                                  _selectedType = type;
                                  _selectedValue =
                                      difficultyValues[type]!.first;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Theme(
                            data: dropdownFieldTheme,
                            child: DropdownMenu<String>(
                              key: ValueKey(_selectedType),
                              width: constraints.maxWidth,
                              initialSelection: _selectedValue,
                              label: const Text('Obtížnost'),
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                              menuStyle: dropdownMenuStyle,
                              trailingIcon: const Icon(
                                Icons.keyboard_arrow_down_sharp,
                              ),
                              selectedTrailingIcon: const Icon(
                                Icons.keyboard_arrow_up_sharp,
                              ),
                              dropdownMenuEntries:
                                  difficultyValues[_selectedType]!
                                      .map(
                                        (value) => DropdownMenuEntry(
                                          value: value,
                                          label: value,
                                        ),
                                      )
                                      .toList(),
                              onSelected: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedValue = value;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Theme(
                      data: dropdownFieldTheme,
                      child: DropdownMenu<ClimbType>(
                        width: constraints.maxWidth,
                        initialSelection: _selectedClimbType,
                        label: const Text('Typ cesty'),
                        textStyle: Theme.of(context).textTheme.bodyLarge,
                        menuStyle: dropdownMenuStyle,
                        trailingIcon: const Icon(
                          Icons.keyboard_arrow_down_sharp,
                        ),
                        selectedTrailingIcon: const Icon(
                          Icons.keyboard_arrow_up_sharp,
                        ),
                        dropdownMenuEntries: ClimbType.values
                            .map(
                              (type) => DropdownMenuEntry(
                                value: type,
                                label: type.name,
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          setState(() {
                            _selectedClimbType = value;
                          });
                        },
                      ),
                    );
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
                  initialValue: _notes,
                  onChanged: (value) => _notes = value,
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
      ),
    );
  }
}
