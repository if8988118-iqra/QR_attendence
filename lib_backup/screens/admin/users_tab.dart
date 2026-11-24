import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
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

  List<Map<String, dynamic>> get _shown {
    final s = _search.toLowerCase();
    return _all.where((u) {
      if (_filter != 'all' && u['role'] != _filter) return false;
      if (s.isEmpty) return true;
      return (u['full_name'] ?? '').toString().toLowerCase().contains(s) ||
          (u['email'] ?? '').toString().toLowerCase().contains(s) ||
          (u['student_id'] ?? '').toString().toLowerCase().contains(s);
    }).toList();
  }

  Color _roleColor(String r) => r == 'admin'
      ? Colors.red
      : (r == 'teacher' ? Colors.orange : Colors.indigo);

  // ---------- ACTIONS ----------
  void _openActions(Map<String, dynamic> u) {
    final isMe = u['id'] == _db.auth.currentUser!.id;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            title: Text(u['full_name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${u['email']}  (${u['role']})'),
          ),
          const Divider(height: 1),
          if (!isMe)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Role badlein'),
              onTap: () {
                Navigator.pop(context);
                _changeRole(u);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Info edit karein'),
            onTap: () {
              Navigator.pop(context);
              _edit(u);
            },
          ),
          if (u['role'] == 'student')
            ListTile(
              leading: const Icon(Icons.phonelink_erase),
              title: Text(u['device_id'] == null
                  ? 'Device: abhi koi registered nahi'
                  : 'Device reset karein'),
              enabled: u['device_id'] != null,
              onTap: () {
                Navigator.pop(context);
                _resetDevice(u);
              },
            ),
          if (!isMe)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Account delete karein',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _delete(u);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _changeRole(Map<String, dynamic> u) async {
    final role = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Naya role chunein'),
        children: ['student', 'teacher', 'admin']
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, r),
                  child: Text(r.toUpperCase()),
                ))
            .toList(),
      ),
    );
    if (role == null || role == u['role']) return;
    try {
      await _db.from('profiles').update({'role': role}).eq('id', u['id']);
      _msg('Role badal gaya');
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _edit(Map<String, dynamic> u) async {
    final name = TextEditingController(text: u['full_name'] ?? '');
    final reg = TextEditingController(text: u['student_id'] ?? '');
    final dept = TextEditingController(text: u['department'] ?? '');
    final sem = TextEditingController(text: u['semester']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info edit'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Naam')),
            TextField(
                controller: reg,
                decoration:
                    const InputDecoration(labelText: 'Student ID / Roll No')),
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
    try {
      await _db.from('profiles').update({
        'full_name': name.text.trim(),
        'student_id': reg.text.trim().isEmpty ? null : reg.text.trim(),
        'department': dept.text.trim(),
        'semester': int.tryParse(sem.text.trim()),
      }).eq('id', u['id']);
      _msg('Save ho gaya');
      _load();
    } catch (e) {
      _msg('Error (shayad ye Student ID pehle se kisi aur ke paas hai): $e');
    }
  }

  Future<void> _resetDevice(Map<String, dynamic> u) async {
    try {
      await _db.from('profiles').update({'device_id': null}).eq('id', u['id']);
      _msg(
          'Device reset ho gaya. Student agli scan par naya device register karega');
      _load();
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete karein?'),
        content: Text(
            '${u['full_name']} ka account aur uski saari attendance hamesha ke liye delete ho jayegi.'),
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
      await _db.rpc('admin_delete_user', params: {'p_user': u['id']});
      _msg('Delete ho gaya');
      _load();
    } catch (e) {
      _msg(
          'Delete nahi hua. Agar teacher hai to pehle uske courses delete karein ya kisi aur ko dein. $e');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final list = _shown;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Naam, email ya roll no search karein',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: ['all', 'student', 'teacher', 'admin']
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ))
              .toList(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${list.length} users')),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(u['role']),
                        child: Icon(
                          u['role'] == 'admin'
                              ? Icons.admin_panel_settings
                              : u['role'] == 'teacher'
                                  ? Icons.co_present
                                  : Icons.school,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(u['full_name'] == null || u['full_name'] == ''
                          ? '(naam nahi)'
                          : u['full_name']),
                      subtitle: Text(
                          '${u['email']}\n${u['role']}  ${u['student_id'] ?? ''}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _openActions(u),
                    );
                  },
                ),
              ),
      ),
    ]);
  }
}
