import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../teacher/course_detail.dart';

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
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
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false);
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

  Future<void> _add() async {
    List<Map<String, dynamic>> teachers = [];
    try {
      final t = await _db
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'teacher');
      teachers = List<Map<String, dynamic>>.from(t);
    } catch (e) {
      _msg('Error: $e');
      return;
    }
    if (teachers.isEmpty) {
      _msg('Pehle kam az kam ek teacher banayein (Users tab se role badlein)');
      return;
    }

    final code = TextEditingController();
    final name = TextEditingController();
    final dept = TextEditingController();
    final sem = TextEditingController();
    String teacherId = teachers.first['id'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Naya Course'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Course Code')),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: teacherId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Teacher'),
                items: teachers
                    .map((t) => DropdownMenuItem<String>(
                          value: t['id'],
                          child: Text(
                              '${t['full_name'] == '' ? t['email'] : t['full_name']}'),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => teacherId = v!),
              ),
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
        'teacher_id': teacherId,
      });
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Course delete karein?'),
        content: Text(
            '${c['code']} ki enrollments aur saari attendance bhi delete ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('courses').delete().eq('id', c['id']);
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Course'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _courses.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Koi course nahi')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: _courses.length,
                      itemBuilder: (_, i) {
                        final c = _courses[i];
                        final teacher = c['profiles']?['full_name'] ?? '-';
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.menu_book,
                                color: Colors.indigo),
                            title: Text('${c['code']}  ${c['name']}'),
                            subtitle: Text(
                                'Teacher: $teacher\n${c['department'] ?? ''}  Sem ${c['semester'] ?? '-'}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _delete(c),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CourseDetail(course: c)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
