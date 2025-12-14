import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../screens/add_edit_task_screen.dart';
import '../screens/completed_screen.dart';
import '../models/task_model.dart';
import 'settings_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

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

    final today = tasks.where((t) =>
    t.dueDate.year == now.year &&
        t.dueDate.month == now.month &&
        t.dueDate.day == now.day).toList();

    final completed = tasks.where((t) => t.isCompleted).toList();
    final repeated = tasks.where((t) => t.repeatType != 'none').toList();

    final lists = [
      _buildList(today, provider, '🎯 No tasks for today.'),
      _buildList(tasks, provider, '📋 No tasks added yet.'),
      CompletedScreen(tasks: completed),
      _buildList(repeated, provider, '🔁 No repeated tasks.'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 5,
        title: const Text(
          '✨ Task Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFF06292)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: lists[_index],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFAB47BC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Task",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFF8E24AA),
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.background,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'All'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Completed'),
          BottomNavigationBarItem(
              icon: Icon(Icons.repeat), label: 'Repeated'),
        ],
      ),
    );

  }

  Widget _buildList(List<TaskModel> list, TaskProvider provider, String emptyMsg) {
    if (list.isEmpty) {
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
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final t = list[i];
          return TaskTile(
            task: t,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTaskScreen(editing: t),
              ),
            ),
            onDelete: () => provider.deleteTask(t),
            onToggleComplete: () => provider.toggleTaskCompletion(t),
          );
        },
      ),
    );
  }
}
