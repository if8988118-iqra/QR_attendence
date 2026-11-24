import 'package:device_info_plus/device_info_plus.dart';
import 'package:qr_attendance/ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _db = Supabase.instance.client;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _busy = false;
  String? _message;
  bool? _success;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _deviceId() async {
    final info = DeviceInfoPlugin();
    try {
      final a = await info.androidInfo;
      return a.id;
    } catch (_) {}
    try {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'unknown-ios';
    } catch (_) {}
    try {
      final w = await info.webBrowserInfo;
      return '${w.browserName}-${w.userAgent.hashCode}';
    } catch (_) {}
    return 'unknown';
  }

  Future<Position?> _location() async {
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final code =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null) return;

    setState(() {
      _busy = true;
      _message = 'Checking...';
      _success = null;
    });

    try {
      final pos = await _location();
      final dev = await _deviceId();
      final res = await _db.rpc('mark_attendance', params: {
        'p_qr': code,
        'p_lat': pos?.latitude,
        'p_lng': pos?.longitude,
        'p_device_id': dev,
      });
      final ok = res['ok'] == true;
      if (!mounted) return;
      setState(() {
        _success = ok;
        _message = res['message']?.toString() ?? (ok ? 'Done' : 'Failed');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = 'Error: $e';
      });
    }

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _busy = false;
        _message = null;
        _success = null;
      });
    }
  }

  Widget _cameraError(MobileScannerException error) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Camera could not start\n(${error.errorCode.name})\n\n'
            'Allow camera permission in your phone Settings.\n'
            'The camera does not work in the FlutLab preview. '
            'Install the APK on a real phone.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _controller.start(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => _cameraError(error),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Scan the teacher's QR code",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.flashlight_on),
                onPressed: () => _controller.toggleTorch(),
              ),
              IconButton(
                color: Colors.white,
                icon: const Icon(Icons.cameraswitch),
                onPressed: () => _controller.switchCamera(),
              ),
            ],
          ),
        ),
        if (_message != null)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _success == null
                    ? Colors.blueGrey
                    : _success!
                        ? Colors.green
                        : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
      ],
    );
  }
}
