import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan_screen.dart';
import 'my_report.dart';
import 'my_history.dart';

class StudentHome extends StatefulWidget {
  final Map<String, dynamic> profile;
  const StudentHome({super.key, required this.profile});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ScanScreen(),
      const MyReport(),
      const MyHistory(),
      _ProfileTab(profile: widget.profile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileTab({required this.profile});

  Widget _row(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value == null || value.isEmpty ? '-' : value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SizedBox(height: 12),
        const Center(
          child: CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        ),
        const SizedBox(height: 16),
        _row(Icons.badge, 'Student ID', profile['student_id']),
        _row(Icons.person, 'Naam', profile['full_name']),
        _row(Icons.email, 'Email', profile['email']),
        _row(Icons.school, 'Department', profile['department']),
        _row(Icons.numbers, 'Semester', profile['semester']?.toString()),
      ],
    );
  }
}
