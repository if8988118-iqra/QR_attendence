import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _regNo = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    final reg = _regNo.text.trim();
    final email = _email.text.trim();
    if (reg.isEmpty || email.isEmpty || _password.text.length < 6) {
      _msg('Roll No, Email aur kam az kam 6 harf ka password zaroori hai');
      return;
    }
    setState(() => _loading = true);
    final db = Supabase.instance.client;
    try {
      // Pehle registry check (fee jama hai ya nahi, wagaira)
      final check = await db.rpc('check_registration', params: {
        'p_reg': reg,
        'p_email': email,
      });
      if (check != 'OK') {
        _msg(check.toString());
      } else {
        await db.auth.signUp(
          email: email,
          password: _password.text,
          data: {'student_id': reg},
        );
        _msg('Account ban gaya. Ab login karein');
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg('Kuch masla aa gaya: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Signup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Text(
                  'Sirf wo students account bana sakte hain jin ki fee jama hai aur jo university list mein hain.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _field(_regNo, 'Registration / Roll No', Icons.badge),
                _field(_email, 'Email', Icons.email,
                    type: TextInputType.emailAddress),
                _field(_password, 'Password', Icons.lock, obscure: true),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Account banayein'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
