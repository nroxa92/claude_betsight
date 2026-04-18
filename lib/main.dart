import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/analysis_provider.dart';
import 'models/matches_provider.dart';
import 'models/navigation_controller.dart';
import 'screens/analysis_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('StorageService init failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const BetSightApp(),
    ),
  );
}

class BetSightApp extends StatelessWidget {
  const BetSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BetSight',
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, nav, child) {
        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: const [
              MatchesScreen(),
              AnalysisScreen(),
              SettingsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: nav.currentIndex,
            onTap: nav.setTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.scoreboard_outlined),
                activeIcon: Icon(Icons.scoreboard),
                label: 'Matches',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'Analysis',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
