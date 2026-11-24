import 'dart:async';
import 'package:qr_attendance/ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionScreen extends StatefulWidget {
  final String courseId;
  const SessionScreen({super.key, required this.courseId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _db = Supabase.instance.client;
  String? _sessionId;
  String? _qr;
  String _status = 'Session shuru ho raha hai...';
  int _count = 0;
  bool _useLocation = true;
  bool _started = false;
  Timer? _qrTimer;
  Timer? _countTimer;
  int _minutes = 10;

  @override
  void dispose() {
    _qrTimer?.cancel();
    _countTimer?.cancel();
    super.dispose();
  }

  Future<Position?> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _start() async {
    setState(() {
      _started = true;
      _status = 'Location le rahe hain...';
    });

    Position? pos;
    if (_useLocation) {
      pos = await _getLocation();
      if (pos == null) {
        setState(() {
          _started = false;
          _status =
              'Location nahi mili. Location OFF karke session shuru karein ya permission dein.';
        });
        return;
      }
    }

    try {
      final id = await _db.rpc('start_session', params: {
        'p_course_id': widget.courseId,
        'p_minutes': _minutes,
        'p_lat': pos?.latitude,
        'p_lng': pos?.longitude,
        'p_radius': 100,
      });
      _sessionId = id as String;
      await _refreshQr();
      _qrTimer =
          Timer.periodic(const Duration(seconds: 10), (_) => _refreshQr());
      _countTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => _loadCount());
      setState(() => _status = 'Session chal raha hai');
    } catch (e) {
      setState(() {
        _started = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _refreshQr() async {
    if (_sessionId == null) return;
    try {
      final t =
          await _db.rpc('get_qr_token', params: {'p_session_id': _sessionId});
      if (mounted) setState(() => _qr = t as String);
    } catch (_) {
      _qrTimer?.cancel();
      if (mounted)
        setState(() {
          _qr = null;
          _status = 'Session khatam ho gaya';
        });
    }
  }

  Future<void> _loadCount() async {
    if (_sessionId == null) return;
    try {
      final data = await _db
          .from('attendance')
          .select('id')
          .eq('session_id', _sessionId!);
      if (mounted) setState(() => _count = (data as List).length);
    } catch (_) {}
  }

  Future<void> _end() async {
    if (_sessionId != null) {
      await _db.rpc('end_session', params: {'p_session_id': _sessionId});
    }
    _qrTimer?.cancel();
    _countTimer?.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Session')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: !_started ? _setup() : _running(),
        ),
      ),
    );
  }

  Widget _setup() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_status, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      DropdownButton<int>(
        value: _minutes,
        items: [5, 10, 15, 30, 60]
            .map((m) =>
                DropdownMenuItem(value: m, child: Text('Session $m minute')))
            .toList(),
        onChanged: (v) => setState(() => _minutes = v!),
      ),
      SwitchListTile(
        title: const Text('Location check (100m)'),
        subtitle: const Text('Sirf class ke andar wale students'),
        value: _useLocation,
        onChanged: (v) => setState(() => _useLocation = v),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
        onPressed: _start,
      ),
    ]);
  }

  Widget _running() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_status, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 16),
      if (_qr != null)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: QrImageView(data: _qr!, size: 260),
        )
      else
        const SizedBox(
            height: 260, child: Center(child: CircularProgressIndicator())),
      const SizedBox(height: 12),
      const Text('QR har 10 second baad badalta hai'),
      const SizedBox(height: 12),
      Text('Present students: $_count',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
        icon: const Icon(Icons.stop),
        label: const Text('End Session'),
        onPressed: _end,
      ),
    ]);
  }
}
