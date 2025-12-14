import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';
import '../screens/view_task_screen.dart';

class CompletedScreen extends StatelessWidget {
  final List<TaskModel> tasks;
  const CompletedScreen({required this.tasks, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    // Only show completed tasks
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    if (completedTasks.isEmpty) {
      return const Center(
        child: Text(
          'No completed tasks yet.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedTasks.length,
        itemBuilder: (ctx, i) {
          final t = completedTasks[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Action Buttons
                  Row(
                    children: [
                      const Icon(Icons.task_alt, color: Color(0xFF8E24AA), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'View Task',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ViewTaskScreen(task: t)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Edit Task',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddEditTaskScreen(editing: t)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Task',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text('Are you sure you want to delete this task?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) provider.deleteTask(t);
                        },
                      ),
                    ],
                  ),

                  // Description
                  if ((t.description?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 6),
                    Text(
                      t.description ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Due Date
                  Row(
                    children: [
                      const Icon(Icons.today, size: 16, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        t.dueDate != null
                            ? 'Due: ${DateFormat('MMM d, yyyy – hh:mm a').format(t.dueDate!)}'
                            : 'No due date set',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Progress
                  const LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.grey,
                    color: Colors.green,
                    minHeight: 5,
                  ),
                  const SizedBox(height: 4),
                  const Text('100%', style: TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 10),

                  // Checkbox only, no text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Checkbox(
                      value: t.isCompleted,
                      onChanged: (val) {
                        provider.toggleTaskCompletion(t);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task marked as incomplete'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
