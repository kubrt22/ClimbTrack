import 'dart:developer';

import 'package:climb_track/models/session_model.dart';
import 'package:climb_track/UI/widgets/route_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climb_track/provider/auth_provider.dart';
import 'package:climb_track/provider/firebase_provider.dart';
import 'package:climb_track/UI/routes/route_select.dart';

class SessionAddPage extends ConsumerStatefulWidget {
  const SessionAddPage({super.key});

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

  void _saveSession(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      log("Form is not valid!");
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    final session = SessionModel(
      id: '',
      title: _title,
      location: _location,
      date: _selectedDate,
      duration: _selectedDuration,
      routeIds: _selectedRouteIds,
      notes: _notes,
      createdAt: DateTime.now(),
    );
    firestore.addSession(user.uid, session);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přidat session'),
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
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              TextFormField(
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
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),

              if (_selectedRouteIds.isNotEmpty) _buildSelectedRoutes(),

              FilledButton(
                onPressed: () async {
                  final selected = await Navigator.push<List<String>>(
                    ref.context,
                    MaterialPageRoute(
                      builder: (context) => RouteSelectPage(
                        initialSelected: _selectedRouteIds.toSet(),
                      ),
                    ),
                  );
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
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),

              child: const Icon(Icons.delete, color: Colors.white),
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
