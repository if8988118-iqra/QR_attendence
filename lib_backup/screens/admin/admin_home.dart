import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'users_tab.dart';
import 'registry_tab.dart';
import 'courses_tab.dart';
import 'attendance_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [UsersTab(), RegistryTab(), CoursesTab(), AttendanceTab()];
    const titles = [
      'Users',
      'Student Registry',
      'Courses',
      'Attendance Records'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin: ${titles[_index]}'),
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
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.how_to_reg), label: 'Registry'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(
              icon: Icon(Icons.fact_check), label: 'Attendance'),
        ],
      ),
    );
  }
}
