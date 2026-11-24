import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher/teacher_home.dart';
import 'student/student_home.dart';
import 'admin/admin_home.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', _db.auth.currentUser!.id)
          .single();
      if (mounted) setState(() => _profile = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Error: $_error'),
            TextButton(
                onPressed: () => _db.auth.signOut(),
                child: const Text('Logout')),
          ]),
        ),
      );
    }
    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _profile!['role'];
    if (role == 'admin') return const AdminHome();
    if (role == 'teacher') return const TeacherHome();
    if (role == 'student') return StudentHome(profile: _profile!);
    final name = _profile!['full_name'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${role.toString().toUpperCase()} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _db.auth.signOut(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              role == 'admin'
                  ? Icons.admin_panel_settings
                  : role == 'teacher'
                      ? Icons.co_present
                      : Icons.school,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text('Welcome $name', style: const TextStyle(fontSize: 22)),
            Text('Role: $role'),
            const SizedBox(height: 8),
            const Text('Is screen ka asli content Step 5/6 mein aayega'),
          ],
        ),
      ),
    );
  }
}
