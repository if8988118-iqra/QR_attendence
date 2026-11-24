import 'package:qr_attendance/ui.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHistory extends StatefulWidget {
  const MyHistory({super.key});

  @override
  State<MyHistory> createState() => _MyHistoryState();
}

class _MyHistoryState extends State<MyHistory> {
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
          .from('attendance')
          .select('status, method, marked_at, courses(code, name)')
          .eq('student_id', _db.auth.currentUser!.id)
          .order('marked_at', ascending: false)
          .limit(200);
      _rows = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: _rows.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Abhi koi attendance record nahi')),
            ])
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                final c = r['courses'] ?? {};
                final t = DateTime.parse(r['marked_at']).toLocal();
                return ListTile(
                  title: Text('${c['code'] ?? ''}  ${c['name'] ?? ''}'),
                  subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(t)),
                  trailing: Chip(
                    label: Text(r['status'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: _color(r['status']),
                  ),
                );
              },
            ),
    );
  }
}
