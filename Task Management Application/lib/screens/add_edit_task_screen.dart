import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/helpers.dart';
import 'package:task_manager_app/models/subtask_model.dart';
class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? editing;
  const AddEditTaskScreen({this.editing, Key? key}) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  DateTime _due = DateTime.now().add(const Duration(hours: 1));
  String _repeatType = 'none';
  List<int> _repeatDays = [];
  List<Subtask> _subtasks = [];
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.editing?.title ?? '');
    _desc = TextEditingController(text: widget.editing?.description ?? '');
    if (widget.editing != null) {
      _due = widget.editing!.dueDate;
      _repeatType = widget.editing!.repeatType;
      _repeatDays = widget.editing!.repeatDays != null
          ? widget.editing!.repeatDays!.map((d) => _stringToWeekday(d)).toList()
          : [];
      _subtasks = widget.editing!.subtasks;
      _notify = widget.editing!.notificationId.isNotEmpty;
    }
  }

  int _stringToWeekday(String day) {
    switch (day) {
      case 'Mon':
        return 1;
      case 'Tue':
        return 2;
      case 'Wed':
        return 3;
      case 'Thu':
        return 4;
      case 'Fri':
        return 5;
      case 'Sat':
        return 6;
      case 'Sun':
        return 7;
      default:
        return 1;
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (time == null) return;

    setState(() => _due = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addSubtask() {
    setState(() => _subtasks.add(Subtask(title: 'New Subtask', done: false)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TaskProvider>(context, listen: false);

    final progress = _subtasks.isEmpty
        ? 0.0
        : (_subtasks.where((s) => s.done).length / _subtasks.length);

    // Convert repeatDays int -> string abbreviation
    List<String> repeatDaysStr =
    _repeatDays.map((d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1]).toList();

    final task = TaskModel(
      id: widget.editing?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      dueDate: _due,
      isCompleted: widget.editing?.isCompleted ?? false,
      repeatType: _repeatType,
      repeatDays: repeatDaysStr,
      subtasks: _subtasks,
      progress: progress,
      notificationId: widget.editing?.notificationId ?? '',
    );

    if (widget.editing == null) {
      await provider.addTask(task, scheduleNotification: _notify);
    } else {
      await provider.updateTask(task, scheduleNotification: _notify);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007BFF), Color(0xFF00BCD4)],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Due: ${formatDate(_due)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _repeatType,
                items: ['none', 'daily', 'weekly', 'custom']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _repeatType = v ?? 'none'),
                decoration: const InputDecoration(labelText: 'Repeat'),
              ),
              if (_repeatType == 'custom')
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
                    final sel = _repeatDays.contains(i + 1);
                    return ChoiceChip(
                      label: Text(label),
                      selected: sel,
                      onSelected: (s) {
                        setState(() {
                          if (s) _repeatDays.add(i + 1);
                          else _repeatDays.remove(i + 1);
                        });
                      },
                    );
                  }),
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Set Notification'),
                value: _notify,
                onChanged: (val) => setState(() => _notify = val),
                secondary: const Icon(Icons.notifications_active),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subtask'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              ..._subtasks.asMap().entries.map((e) {
                final idx = e.key;
                final s = e.value;
                return ListTile(
                  leading: Checkbox(
                    value: s.done,
                    onChanged: (v) {
                      setState(() => _subtasks[idx].done = v ?? false);
                    },
                  ),
                  title: TextFormField(
                    initialValue: s.title,
                    onChanged: (val) => _subtasks[idx].title = val,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _subtasks.removeAt(idx)),
                  ),
                );
              }).toList(),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
