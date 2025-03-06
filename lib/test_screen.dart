import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/user_model.dart';
import 'models/hydration_log_model.dart';

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final dbHelper = DatabaseHelper();
  List<User> users = [];
  List<HydrationLog> logs = [];
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query('users');
    setState(() {
      users = result.map((e) => User.fromMap(e)).toList();
      if (users.isNotEmpty) selectedUserId = users.first.id;
    });
  }

  Future<void> _insertUser() async {
    await dbHelper.insertUser(User(name: "User ${users.length + 1}"));
    _loadUsers();
  }

  Future<void> _insertHydrationLog() async {
    if (selectedUserId == null) return;
    HydrationLog log = HydrationLog(
      userId: selectedUserId!,
      amount: 250.0,
      timestamp: DateTime.now().toIso8601String(),
    );
    await dbHelper.insertHydrationLog(log);
    _loadHydrationLogs();
  }

  Future<void> _loadHydrationLogs() async {
    if (selectedUserId == null) return;
    List<HydrationLog> logsList =
        await dbHelper.getHydrationLogs(selectedUserId!);
    setState(() {
      logs = logsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Test Hydration Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Users:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            users.isEmpty
                ? Text("No users found")
                : DropdownButton<int>(
                    value: selectedUserId,
                    onChanged: (value) {
                      setState(() {
                        selectedUserId = value;
                      });
                      _loadHydrationLogs();
                    },
                    items: users.map((user) {
                      return DropdownMenuItem<int>(
                        value: user.id,
                        child: Text(user.name),
                      );
                    }).toList(),
                  ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _insertUser, child: Text("Add User")),
            SizedBox(height: 20),
            Text("Hydration Logs:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            logs.isEmpty
                ? Text("No logs found")
                : Expanded(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text("${logs[index].amount} ml"),
                          subtitle: Text(logs[index].timestamp),
                        );
                      },
                    ),
                  ),
            SizedBox(height: 10),
            ElevatedButton(
                onPressed: _insertHydrationLog,
                child: Text("Add Hydration Log")),
          ],
        ),
      ),
    );
  }
}
