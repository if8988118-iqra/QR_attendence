import 'package:qr_attendance/ui.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _courses = [];
  String? _courseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c =
          await _db.from('courses').select('id, code, name').order('code');
      _courses = List<Map<String, dynamic>>.from(c);
    } catch (_) {}
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var q = _db.from('attendance').select(
          'id, status, method, marked_at, profiles(full_name, student_id), courses(code, name)');
      if (_courseId != null) q = q.eq('course_id', _courseId!);
      final data = await q.order('marked_at', ascending: false).limit(200);
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

  Future<void> _setStatus(String id, String status) async {
    try {
      await _db
          .from('attendance')
          .update({'status': status, 'method': 'manual'}).eq('id', id);
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String?>(
          value: _courseId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Course filter',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('Saare courses')),
            ..._courses.map((c) => DropdownMenuItem<String?>(
                  value: c['id'],
                  child: Text('${c['code']}  ${c['name']}'),
                )),
          ],
          onChanged: (v) {
            _courseId = v;
            _load();
          },
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _rows.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Koi attendance record nahi')),
                      ])
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (_, i) {
                          final r = _rows[i];
                          final p = r['profiles'] ?? {};
                          final c = r['courses'] ?? {};
                          final t = DateTime.parse(r['marked_at']).toLocal();
                          return ListTile(
                            title: Text(
                                '${p['full_name'] ?? ''}  (${p['student_id'] ?? '-'})'),
                            subtitle: Text(
                                '${c['code'] ?? ''}   ${DateFormat('dd MMM yyyy, hh:mm a').format(t)}   [${r['method']}]'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (s) => _setStatus(r['id'], s),
                              itemBuilder: (_) => [
                                'present',
                                'late',
                                'absent',
                                'excused'
                              ]
                                  .map((s) =>
                                      PopupMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              child: Chip(
                                label: Text(r['status'],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                backgroundColor: _color(r['status']),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }
}
