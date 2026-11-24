import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'history_tab.dart';
import 'session_screen.dart';

class CourseDetail extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseDetail({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${course['code']} - ${course['name']}'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.people), text: 'Students'),
            Tab(icon: Icon(Icons.qr_code), text: 'Attendance'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Report'),
          ]),
        ),
        body: TabBarView(children: [
          _StudentsTab(courseId: course['id']),
          _AttendanceTab(courseId: course['id']),
          HistoryTab(courseId: course['id']),
          _ReportTab(courseId: course['id']),
        ]),
      ),
    );
  }
}

// ---------------- STUDENTS TAB ----------------
class _StudentsTab extends StatefulWidget {
  final String courseId;
  const _StudentsTab({required this.courseId});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
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
          .from('enrollments')
          .select('student_id, profiles(full_name, student_id, email)')
          .eq('course_id', widget.courseId);
      _students = List<Map<String, dynamic>>.from(data);
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
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Student add karein'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Roll No ya Email'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    try {
      await _db.rpc('enroll_student', params: {
        'p_course_id': widget.courseId,
        'p_identifier': c.text.trim(),
      });
      _msg('Student add ho gaya');
      _load();
    } catch (e) {
      _msg('Student nahi mila ya error: $e');
    }
  }

  Future<void> _remove(String studentId) async {
    try {
      await _db
          .from('enrollments')
          .delete()
          .eq('course_id', widget.courseId)
          .eq('student_id', studentId);
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
        icon: const Icon(Icons.person_add),
        label: const Text('Student'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('Koi student enroll nahi'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final p = _students[i]['profiles'] ?? {};
                    return ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(p['full_name'] ?? ''),
                      subtitle:
                          Text('${p['student_id'] ?? ''}  ${p['email'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _remove(_students[i]['student_id']),
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------- ATTENDANCE TAB ----------------
class _AttendanceTab extends StatelessWidget {
  final String courseId;
  const _AttendanceTab({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 90, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text('Attendance session shuru karein',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SessionScreen(courseId: courseId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- REPORT TAB ----------------
class _ReportTab extends StatefulWidget {
  final String courseId;
  const _ReportTab({required this.courseId});

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
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
          .rpc('course_report', params: {'p_course_id': widget.courseId});
      _rows = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _msg('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _q(dynamic v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';

  Future<void> _export() async {
    final b =
        StringBuffer('Reg No,Name,Total Classes,Attended,Missed,Percentage\n');
    for (final r in _rows) {
      b.writeln([
        r['reg_no'],
        r['full_name'],
        r['total_classes'],
        r['attended'],
        r['missed'],
        r['percentage']
      ].map(_q).join(','));
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    _msg('Report copy ho gayi. Excel / Google Sheets mein paste karein');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _rows.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _export,
              icon: const Icon(Icons.copy),
              label: const Text('Export CSV'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Abhi koi data nahi')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: _rows.length,
                      itemBuilder: (_, i) {
                        final r = _rows[i];
                        final pct = (r['percentage'] as num).toDouble();
                        return ListTile(
                          title:
                              Text('${r['full_name']}  (${r['reg_no'] ?? ''})'),
                          subtitle: Text(
                              'Total: ${r['total_classes']}   Present: ${r['attended']}   Missed: ${r['missed']}'),
                          trailing: Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: pct < 75 ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
