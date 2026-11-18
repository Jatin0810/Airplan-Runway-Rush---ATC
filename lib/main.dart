import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation on mobile devices
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Transparent edge-to-edge system navigation on Android
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(const IndianAtcApp());
}

class IndianAtcApp extends StatefulWidget {
  const IndianAtcApp({super.key});

  @override
  State<IndianAtcApp> createState() => _IndianAtcAppState();
}

class _IndianAtcAppState extends State<IndianAtcApp> {
  final RadarThemeController _themeController = RadarThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RadarThemeScope(
      controller: _themeController,
      child: Builder(
        builder: (context) {
          final theme = RadarThemeScope.of(context);

          return MaterialApp(
            title: 'Indian ATC – Airport Manager & Radar Simulator',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: theme.airspaceBackground,
              useMaterial3: true,
              fontFamily: 'monospace',
            ),
            // Responsive shell: Fills 100% on mobile; centers with elegant max width on web desktop
            builder: (context, child) {
              return Container(
                color: const Color(0xFF030712), // Deep outer background for desktop web
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: child,
                ),
              );
            },
            home: const MainMenuScreen(),
          );
        },
      ),
    );
  }
}
