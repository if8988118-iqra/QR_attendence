import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyReport extends StatefulWidget {
  const MyReport({super.key});

  @override
  State<MyReport> createState() => _MyReportState();
}

class _MyReportState extends State<MyReport> {
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
      final data = await _db.rpc('my_report');
      _rows = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: _rows.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('Aap kisi course mein enroll nahi hain')),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                final pct = (r['percentage'] as num).toDouble();
                final low = pct < 75;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r['course_code']}  ${r['course_name']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          color: low ? Colors.red : Colors.green,
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Total: ${r['total_classes']}   Attended: ${r['attended']}   Missed: ${r['missed']}'),
                        Text(
                          '${pct.toStringAsFixed(1)}%${low ? '  (Low attendance)' : ''}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: low ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
