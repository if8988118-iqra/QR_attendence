import 'package:qr_attendance/ui.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryTab extends StatefulWidget {
  final String courseId;
  const HistoryTab({super.key, required this.courseId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
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
          .rpc('course_sessions', params: {'p_course_id': widget.courseId});
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

  // Bina QR ke manual session (phone kharab ho ya QR na chale)
  Future<void> _manualSession() async {
    try {
      final id = await _db.rpc('start_session', params: {
        'p_course_id': widget.courseId,
        'p_minutes': 1,
      });
      await _db.rpc('end_session', params: {'p_session_id': id});
      await _load();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                RosterScreen(sessionId: id as String, title: 'Manual session')),
      ).then((_) => _load());
    } catch (e) {
      _msg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _manualSession,
        icon: const Icon(Icons.edit_note),
        label: const Text('Manual session'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _rows.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Abhi koi session nahi')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: _rows.length,
                      itemBuilder: (_, i) {
                        final r = _rows[i];
                        final t = DateTime.parse(r['started_at']).toLocal();
                        final title =
                            DateFormat('dd MMM yyyy, hh:mm a').format(t);
                        return ListTile(
                          leading: Icon(r['is_active'] == true
                              ? Icons.radio_button_checked
                              : Icons.history),
                          title: Text(title),
                          subtitle: Text(
                              'Present: ${r['present_count']} / ${r['enrolled_count']}'
                              '${r['is_active'] == true ? '   (chal raha hai)' : ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RosterScreen(
                                    sessionId: r['session_id'], title: title)),
                          ).then((_) => _load()),
                        );
                      },
                    ),
            ),
    );
  }
}

// Ek session ke saare students, status badalne ke liye
class RosterScreen extends StatefulWidget {
  final String sessionId;
  final String title;
  const RosterScreen({super.key, required this.sessionId, required this.title});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
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
          .rpc('session_roster', params: {'p_session_id': widget.sessionId});
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

  Future<void> _set(String studentId, String status) async {
    try {
      await _db.rpc('set_manual_attendance', params: {
        'p_session_id': widget.sessionId,
        'p_student': studentId,
        'p_status': status,
      });
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Color _color(String? s) {
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text('Is course mein koi student enroll nahi'))
              : ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (_, i) {
                    final r = _rows[i];
                    final status = (r['status'] ?? 'absent') as String;
                    return ListTile(
                      title: Text('${r['full_name']}'),
                      subtitle:
                          Text('${r['reg_no'] ?? '-'}   ${r['method'] ?? ''}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (s) => _set(r['student_uuid'], s),
                        itemBuilder: (_) => [
                          'present',
                          'late',
                          'absent',
                          'excused'
                        ]
                            .map((s) => PopupMenuItem(value: s, child: Text(s)))
                            .toList(),
                        child: Chip(
                          label: Text(status,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          backgroundColor: _color(r['status']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
