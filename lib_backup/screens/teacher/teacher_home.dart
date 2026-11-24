import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'course_detail.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('courses')
          .select()
          .eq('teacher_id', _db.auth.currentUser!.id)
          .order('created_at');
      _courses = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _msg('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _addCourse() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final dept = TextEditingController();
    final sem = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Naya Course'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: code,
                decoration:
                    const InputDecoration(labelText: 'Course Code (CS101)')),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Course Name')),
            TextField(
                controller: dept,
                decoration: const InputDecoration(labelText: 'Department')),
            TextField(
                controller: sem,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Semester')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (ok != true) return;
    if (code.text.trim().isEmpty || name.text.trim().isEmpty) {
      _msg('Code aur name zaroori hain');
      return;
    }
    try {
      await _db.from('courses').insert({
        'code': code.text.trim(),
        'name': name.text.trim(),
        'department': dept.text.trim(),
        'semester': int.tryParse(sem.text.trim()),
        'teacher_id': _db.auth.currentUser!.id,
      });
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meri Courses'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _db.auth.signOut()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCourse,
        icon: const Icon(Icons.add),
        label: const Text('Course'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child:
                      Text('Abhi koi course nahi. Neeche + Course dabayein.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final c = _courses[i];
                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.menu_book, color: Colors.indigo),
                        title: Text('${c['code']}  ${c['name']}'),
                        subtitle: Text(
                            '${c['department'] ?? ''}  Sem ${c['semester'] ?? '-'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CourseDetail(course: c)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
