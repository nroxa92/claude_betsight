import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/accumulators_provider.dart';
import 'models/analysis_provider.dart';
import 'models/bets_provider.dart';
import 'models/intelligence_provider.dart';
import 'models/matches_provider.dart';
import 'models/navigation_controller.dart';
import 'models/telegram_provider.dart';
import 'models/tier_provider.dart';
import 'services/ball_dont_lie_service.dart';
import 'services/football_data_service.dart';
import 'services/intelligence_aggregator.dart';
import 'services/notifications_service.dart';
import 'services/reddit_monitor.dart';
import 'widgets/tier_mode_selector.dart';
import 'screens/analysis_screen.dart';
import 'screens/bets_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.init();
    final cleanup = await StorageService.runScheduledCleanup();
    debugPrint('Scheduled cleanup: $cleanup');
  } catch (e) {
    debugPrint('StorageService init/cleanup failed: $e');
  }
  try {
    await NotificationsService.init();
    await NotificationsService.requestPermissions();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TierProvider()),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => BetsProvider()),
        ChangeNotifierProvider(create: (_) => AccumulatorsProvider()),
        ChangeNotifierProvider(create: (_) => TelegramProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final provider = IntelligenceProvider();
            final footballKey = StorageService.getFootballDataApiKey();
            final footballService =
                (footballKey != null && footballKey.isNotEmpty)
                    ? (FootballDataService()..setApiKey(footballKey))
                    : null;
            final aggregator = IntelligenceAggregator(
              footballService: footballService,
              nbaService: BallDontLieService(),
              redditMonitor: RedditMonitor(),
              telegramProvider: context.read<TelegramProvider>(),
            );
            provider.wireAggregator(aggregator);
            return provider;
          },
        ),
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
          body: Column(
            children: [
              const SafeArea(
                bottom: false,
                child: TierModeSelector(),
              ),
              Expanded(
                child: IndexedStack(
                  index: nav.currentIndex,
                  children: const [
                    MatchesScreen(),
                    AnalysisScreen(),
                    BetsScreen(),
                    SettingsScreen(),
                  ],
                ),
              ),
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
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Bets',
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
