import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  ApiClient.init();

  // Paint immediately. The native launch screen is torn down as soon as the
  // platform view controller loads, not when Flutter first paints, so awaiting
  // the keychain read here would leave the window empty for the duration of it.
  runApp(const LetsKonnectApp());
}

class LetsKonnectApp extends StatelessWidget {
  const LetsKonnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiClient.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'StallConnect',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14B8A6),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: Color(0xFF14B8A6), width: 2),
          ),
          labelStyle:
          const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ),
      home: const _SessionGate(),
    );
  }
}

/// Resolves the stored session, showing a pixel-match of the native launch
/// screen until it does. Because it is identical to what iOS/Android already
/// had on screen, the handover reads as one continuous splash rather than a
/// second one.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final isLoggedIn = await ApiClient.getToken() != null;
    if (mounted) setState(() => _isLoggedIn = isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _isLoggedIn;
    if (isLoggedIn == null) return const _LaunchView();
    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}

/// Mirrors ios/Runner/Base.lproj/LaunchScreen.storyboard and
/// android/app/src/main/res/drawable/launch_background.xml: the brand teal with
/// the light logo mark centred at its native 99x120 size. Keep the three in
/// sync — any difference here shows up as a visible jump on startup.
class _LaunchView extends StatelessWidget {
  const _LaunchView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF14B8A6),
      child: Center(
        child: Image(
          image: AssetImage('assets/images/logo_mark_light.png'),
          width: 99,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}