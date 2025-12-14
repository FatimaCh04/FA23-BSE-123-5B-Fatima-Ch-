import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';
import '../screens/completed_screen.dart';
import '../models/task_model.dart';
import 'settings_screen.dart';
import 'view_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String _searchQuery = '';
  String _sortOption = 'Date'; // Default sort

  @override
  void initState() {
    super.initState();
    Provider.of<TaskProvider>(context, listen: false).loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final tasks = provider.tasks;
    final now = DateTime.now();

    final today = tasks
        .where((t) =>
    t.dueDate.year == now.year &&
        t.dueDate.month == now.month &&
        t.dueDate.day == now.day)
        .toList();

    final completed = tasks.where((t) => t.isCompleted).toList();
    final repeated = tasks.where((t) => t.repeatType != 'none').toList();

    final totalTasks = tasks.length;
    final completedCount = completed.length;
    final progress = totalTasks == 0 ? 0.0 : completedCount / totalTasks;

    final lists = [
      _buildList(today, provider, '🎯 No tasks for today.'),
      _buildList(tasks, provider, '📋 No tasks added yet.'),
      _buildList(completed, provider, '✅ No completed tasks yet.'),
      _buildList(repeated, provider, '🔁 No repeated tasks.'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundImage: AssetImage('assets/images/profile.jpg'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "✨ Task Manager",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(now),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round,
                          color: Colors.white,
                        ),
                        onPressed: () => provider.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (totalTasks > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Completed: $completedCount / $totalTasks  (${(progress * 100).toStringAsFixed(0)}%)",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "No tasks yet. Add your first one!",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search tasks...",
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[200],
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.purple),
                  onSelected: (value) => setState(() => _sortOption = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
                    PopupMenuItem(value: 'Progress', child: Text('Sort by Progress')),
                    PopupMenuItem(value: 'Status', child: Text('Sort by Status')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: lists[_index],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFAB47BC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF8E24AA),
            unselectedItemColor: Colors.grey,
            backgroundColor: Theme.of(context).colorScheme.surface,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'All'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle_outline), label: 'Completed'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.repeat), label: 'Repeated'),
            ],
          ),
        ),
      ),
    );
  }

  // --- Task List Builder with View/Edit/Delete icons ---
  Widget _buildList(List<TaskModel> list, TaskProvider provider, String emptyMsg) {
    var filteredList = list
        .where((t) =>
    t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Sorting
    if (_sortOption == 'Date') {
      filteredList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortOption == 'Progress') {
      filteredList.sort((a, b) => a.progress.compareTo(b.progress));
    } else if (_sortOption == 'Status') {
      filteredList.sort((a, b) => a.isCompleted ? 1 : -1);
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (ctx, i) {
          final t = filteredList[i];
          final taskProgress = t.isCompleted ? 1.0 : t.progress ?? 0.0;
          final percentage = (taskProgress * 100).toStringAsFixed(0);

          Color progressColor;
          if (taskProgress < 0.15) {
            progressColor = Colors.red;
          } else if (taskProgress < 0.30) {
            progressColor = Colors.yellow;
          } else if (taskProgress < 0.50) {
            progressColor = Colors.orange;
          } else if (taskProgress < 0.80) {
            progressColor = Colors.deepPurpleAccent;
          } else {
            progressColor = Colors.purple;
          }

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
                  Row(
                    children: [
                      const Icon(Icons.task_alt, color: Color(0xFF8E24AA), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: t.isCompleted ? TextDecoration.lineThrough : null,
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
                        onPressed: () => provider.deleteTask(t),
                      ),
                    ],
                  ),
                  if ((t.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      t.description ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: t.isCompleted ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.today, size: 16, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM d, yyyy – hh:mm a').format(t.dueDate)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: taskProgress,
                    backgroundColor: Colors.grey[200],
                    color: t.isCompleted ? Colors.green : progressColor,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: t.isCompleted,
                        onChanged: (_) => provider.toggleTaskCompletion(t),
                        activeColor: const Color(0xFF8E24AA),
                      ),
                      const SizedBox(width: 6),
                      const Text('Mark as Completed', style: TextStyle(fontSize: 14)),
                    ],
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
