import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistryTab extends StatefulWidget {
  const RegistryTab({super.key});

  @override
  State<RegistryTab> createState() => _RegistryTabState();
}

class _RegistryTabState extends State<RegistryTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db.from('student_registry').select().order('reg_no');
      _all = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _msg('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _toggleFee(Map<String, dynamic> r, bool v) async {
    try {
      await _db
          .from('student_registry')
          .update({'fee_paid': v}).eq('reg_no', r['reg_no']);
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    try {
      await _db.from('student_registry').delete().eq('reg_no', r['reg_no']);
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _add() async {
    final reg = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final dept = TextEditingController();
    final sem = TextEditingController();
    bool fee = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Student add karein'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: reg,
                  decoration: const InputDecoration(labelText: 'Roll No')),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Naam')),
              TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: dept,
                  decoration: const InputDecoration(labelText: 'Department')),
              TextField(
                  controller: sem,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Semester')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fee jama hai'),
                value: fee,
                onChanged: (v) => setS(() => fee = v),
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
    if (reg.text.trim().isEmpty ||
        name.text.trim().isEmpty ||
        dept.text.trim().isEmpty ||
        int.tryParse(sem.text.trim()) == null) {
      _msg('Roll No, naam, department aur semester zaroori hain');
      return;
    }
    try {
      await _db.from('student_registry').upsert({
        'reg_no': reg.text.trim(),
        'full_name': name.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'department': dept.text.trim(),
        'semester': int.parse(sem.text.trim()),
        'fee_paid': fee,
      }, onConflict: 'reg_no');
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  // CSV paste: reg_no,full_name,email,department,semester,fee_paid
  Future<void> _importCsv() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV paste karein'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Har line: reg_no,naam,email,department,semester,fee_paid(true/false)',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
                controller: c,
                maxLines: 10,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok != true) return;

    final rows = <Map<String, dynamic>>[];
    for (final line in c.text.split('\n')) {
      final p = line.split(',').map((e) => e.trim()).toList();
      if (p.length < 6) continue;
      if (p[0].toLowerCase() == 'reg_no') continue; // header
      final sem = int.tryParse(p[4]);
      if (p[0].isEmpty || p[1].isEmpty || p[3].isEmpty || sem == null) continue;
      rows.add({
        'reg_no': p[0],
        'full_name': p[1],
        'email': p[2].isEmpty ? null : p[2],
        'department': p[3],
        'semester': sem,
        'fee_paid': ['true', '1', 'yes', 'paid'].contains(p[5].toLowerCase()),
      });
    }
    if (rows.isEmpty) {
      _msg('Koi sahi line nahi mili');
      return;
    }
    try {
      await _db.from('student_registry').upsert(rows, onConflict: 'reg_no');
      _msg('${rows.length} students import ho gaye');
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _search.toLowerCase();
    final list = _all.where((r) {
      if (s.isEmpty) return true;
      return (r['reg_no'] ?? '').toString().toLowerCase().contains(s) ||
          (r['full_name'] ?? '').toString().toLowerCase().contains(s);
    }).toList();
    final paid = _all.where((r) => r['fee_paid'] == true).length;

    return Scaffold(
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(
          heroTag: 'csv',
          onPressed: _importCsv,
          child: const Icon(Icons.upload_file),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'add',
          onPressed: _add,
          icon: const Icon(Icons.person_add),
          label: const Text('Student'),
        ),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Roll No ya naam search karein',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Total ${_all.length}   Fee jama: $paid   Baqi: ${_all.length - paid}'),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 150),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final r = list[i];
                      return ListTile(
                        title: Text('${r['full_name']}  (${r['reg_no']})'),
                        subtitle: Text(
                            '${r['department']}  Sem ${r['semester']}\n${r['email'] ?? ''}'),
                        isThreeLine: true,
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          Switch(
                              value: r['fee_paid'] == true,
                              onChanged: (v) => _toggleFee(r, v)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(r),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}
