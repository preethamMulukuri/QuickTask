import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _dueDate;
  List<ParseObject> _tasks = [];
  ParseUser? _currentUser;
  int? _editTaskIndex; // Track the index of the task being edited

  @override
  void initState() {
    super.initState();
    // _fetchCurrentUser();
    // _fetchTasks();
    _initializeUserAndTasks();
  }

  Future<void> _initializeUserAndTasks() async {
    await _fetchCurrentUser();
    if (_currentUser != null) {
      await _fetchTasks();
    }
  }
  
  Future<void> _fetchCurrentUser() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    setState(() {
      _currentUser = user;
    });
  }

  // Future<void> _fetchTasks() async {
  //   final query = QueryBuilder<ParseObject>(ParseObject('Tasks'))
  //     ..whereEqualTo('user', _currentUser);

  //   final response = await query.query();

  //   if (response.success && response.results != null) {
  //     setState(() {
  //       _tasks = response.results as List<ParseObject>;
  //     });
  //   }
  // }

  Future<void> _fetchTasks() async {
    if (_currentUser == null) return;

    final query = QueryBuilder<ParseObject>(ParseObject('Tasks'))
      ..whereEqualTo('user', _currentUser);

    final response = await query.query();

    if (response.success && response.results != null) {
      setState(() {
        _tasks = response.results as List<ParseObject>;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch tasks: ${response.error?.message}')),
      );
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    ParseObject task;

    if (_editTaskIndex == null) {
      // Adding a new task
      task = ParseObject('Tasks')
        ..set('user', _currentUser)
        ..set('isCompleted', false);
    } else {
      // Editing an existing task
      task = _tasks[_editTaskIndex!];
    }

    task
      ..set('title', _titleController.text)
      ..set('dueDate', _dueDate);

    final response = await task.save();

    if (response.success) {
      setState(() {
        _editTaskIndex = null;
        _titleController.clear();
        _dueDate = null;
      });
      await _fetchTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editTaskIndex == null
              ? 'Task added successfully'
              : 'Task updated successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save task: ${response.error?.message}')),
      );
    }
  }

  Future<void> _deleteTask(ParseObject task) async {
    final response = await task.delete();

    if (response.success) {
      // await _fetchTasks();
      setState(() {
        _tasks.remove(task);
      });
      if(_tasks.isEmpty) {
        _fetchTasks();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: ${response.error?.message}')),
      );
    }
  }

  Future<void> _toggleTaskStatus(ParseObject task) async {
    task.set('isCompleted', !(task.get<bool>('isCompleted') ?? false));

    final response = await task.save();

    if (response.success) {
      await _fetchTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task status: ${response.error?.message}')),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        // Set time to midnight (start of day)
        _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
        // _dueDate = pickedDate.toUtc();
        // print(_dueDate);
      });
    }
  }

  Future<void> _logout() async {
    final response = await _currentUser?.logout();
    if (response?.success ?? false) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${response?.error?.message}')),
      );
    }
  }

  void _editTask(int index) {
    final task = _tasks[index];
    setState(() {
      _editTaskIndex = index;
      _titleController.text = task.get<String>('title') ?? '';
      _dueDate = task.get<DateTime>('dueDate')?.toLocal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Management'),
        actions: [
          ElevatedButton(
              onPressed: _logout,
              child: Text('Logout'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Task Title'),
                ),
                TextField(
                  controller: TextEditingController(
                    text: _dueDate != null
                        ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                        : '',
                  ),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: _pickDueDate,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _saveTask,
                  child: Text(_editTaskIndex == null ? 'Add Task' : 'Update Task'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final dueDate = task.get<DateTime>('dueDate')?.toLocal();

                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(task.get<String>('title') ?? ''),
                    subtitle: Text(
                      'Due: ${dueDate?.year}-${dueDate?.month.toString().padLeft(2, '0')}-${dueDate?.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            task.get<bool>('isCompleted') == true
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: task.get<bool>('isCompleted') == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () => _toggleTaskStatus(task),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTask(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(task),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
