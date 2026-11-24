import 'package:qr_attendance/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_attendance/config.dart';
import 'package:qr_attendance/screens/auth/login_screen.dart';
import 'package:qr_attendance/screens/home_router.dart';
import 'package:qr_attendance/theme/app_theme.dart';
import 'package:qr_attendance/theme/theme_settings_screen.dart';

final supabase = Supabase.instance.client;
final navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  await themeCtrl.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeCtrl,
      builder: (context, _) {
        return MaterialApp(
          title: 'QR Attendance',
          navigatorKey: navKey,
          debugShowCheckedModeBanner: false,
          theme: themeCtrl.themeData,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final cs = Theme.of(context).colorScheme;
            return MediaQuery(
              data: mq.copyWith(
                  textScaler: TextScaler.linear(themeCtrl.fontScale)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  Positioned(
                    left: 6,
                    bottom: 100,
                    child: Material(
                      color: cs.primary.withAlpha(215),
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => navKey.currentState!.push(
                          MaterialPageRoute(
                              builder: (_) => const ThemeSettingsScreen()),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(9),
                          child: Icon(Icons.palette,
                              size: 22, color: cs.onPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          home: StreamBuilder<AuthState>(
            stream: supabase.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final session = supabase.auth.currentSession;
              if (session == null) return const LoginScreen();
              return const HomeRouter();
            },
          ),
        );
      },
    );
  }
}
