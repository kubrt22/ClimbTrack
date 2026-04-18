import 'dart:developer';

import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/routes/route_select.dart';

class SessionAddPage extends ConsumerStatefulWidget {
  const SessionAddPage({super.key, this.initialSession});

  final SessionModel? initialSession;

  @override
  ConsumerState<SessionAddPage> createState() => _SessionAddPageState();
}

class _SessionAddPageState extends ConsumerState<SessionAddPage> {
  String _title = '';
  String _location = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedDuration;
  String _notes = '';
  List<String> _selectedRouteIds = [];
  final TextEditingController _locationController = TextEditingController();

  void _dismissActiveFocus() {
    final focused = FocusManager.instance.primaryFocus;
    if (focused != null && focused.hasFocus) {
      focused.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();

    final initialSession = widget.initialSession;
    if (initialSession != null) {
      _title = initialSession.title;
      _location = initialSession.location;
      _locationController.text = initialSession.location;
      _selectedDate = initialSession.date;
      _selectedDuration = initialSession.duration;
      _notes = initialSession.notes;
      _selectedRouteIds = List.from(initialSession.routeIds);
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

  void _saveSession(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      log("Form is not valid!");
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    final initialSession = widget.initialSession;
    final isEditing = initialSession != null;
    final session = SessionModel(
      id: isEditing ? initialSession.id : '',
      title: _title,
      location: _location,
      date: _selectedDate,
      duration: _selectedDuration,
      routeIds: _selectedRouteIds,
      notes: _notes,
      createdAt: isEditing ? initialSession.createdAt : DateTime.now(),
    );
    if (isEditing) {
      firestore.updateSession(user.uid, session);
    } else {
      firestore.addSession(user.uid, session);
    }
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

  Future<void> _selectDuration() async {
    final TimeOfDay? pickedDuration = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 1, minute: 30),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    setState(() {
      _selectedDuration = pickedDuration;
    });
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);
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
    final recentLocations = sessionsAsync.maybeWhen(
      data: (sessions) {
        final uniqueKeys = <String>{};
        final values = <String>[];
        for (final session in sessions) {
          final location = session.location.trim();
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
          widget.initialSession == null ? 'Přidat session' : 'Upravit session',
        ),
        actions: [
          IconButton(
            onPressed: () => _saveSession(context),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              TextFormField(
                initialValue: _title,
                onChanged: (value) => _title = value,
                decoration: InputDecoration(
                  labelText: 'Název session',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zadejte název session';
                  }
                  return null;
                },
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
                      trailingIcon: const Icon(Icons.keyboard_arrow_down_sharp),
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
                onPressed: _selectDuration,
                child: Text(
                  'Délka: ${_selectedDuration == null ? 'Nezvoleno' : '${_selectedDuration!.hour}h ${_selectedDuration!.minute}min'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
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

              Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cesty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _selectedRouteIds.length.toString(),
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),

              if (_selectedRouteIds.isNotEmpty) _buildSelectedRoutes(),

              FilledButton(
                onPressed: () async {
                  _dismissActiveFocus();

                  final selected = await Navigator.push<List<String>>(
                    ref.context,
                    MaterialPageRoute(
                      builder: (context) => RouteSelectPage(
                        initialSelected: _selectedRouteIds.toSet(),
                      ),
                    ),
                  );
                  if (!mounted) return;

                  _dismissActiveFocus();

                  if (selected != null) {
                    setState(() {
                      _selectedRouteIds = selected;
                    });
                  }
                },
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 56),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),

                child: const Text(
                  'Přidat cestu',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRoutes() {
    final routesAsync = ref.watch(sessionRoutesProvider(_selectedRouteIds));

    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (routes) => ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final r = routes[index];
          return Dismissible(
            key: ValueKey(r.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),

              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(8),
              ),

              child: const Icon(Icons.delete),
            ),
            onDismissed: (direction) => setState(() {
              _selectedRouteIds = _selectedRouteIds
                  .where((id) => id != r.id)
                  .toList();
            }),
            child: IgnorePointer(
              child: RouteListTile(
                id: r.id,
                title: r.title,
                location: r.location,
                date: r.date,
                climbType: r.climbType,
                climbStyle: r.climbStyle,
                difficulty: r.difficulty,
                color: r.routeColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
