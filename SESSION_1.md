# BetSight SESSION 1 — Initial Build

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` u root direktoriju projekta (pravila sesije, redoslijed faza, autonomni režim)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz Fazu 1 → Fazu 5 → Post-Phase bez ikakvog čekanja na developerovu potvrdu.**

**Nakon svake faze obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći
3. Dodaj unos u `WORKLOG.md` s: Phase naziv, Status, Opis, Komande izvršene, Kreirani fajlovi (s kratkim opisom sadržaja), Ažurirani fajlovi, Verifikacija
4. Tek onda prelazi na sljedeću fazu

**Ako naiđeš na problem izvan scope-a trenutne faze:** ne popravljaj ga, zabilježi u sekciju `## Identified Issues` na dnu `WORKLOG.md`-a.

---

## Projektni kontekst

**BetSight** je AI-powered sports betting intelligence platform. Radimo Flutter aplikaciju s tri taba: Matches (meči i kvote iz The Odds API), Analysis (chat s Claude AI uz match context injection), Settings (upravljanje API ključevima). Multi-sport od starta: nogomet, košarka, tenis. Tema je identična CoinSight dark temi.

**Target platforma:** primarno Android, sekundarno Windows (za dev/debug).
**Paket:** `com.betsight` / `betsight`
**Početna verzija:** `1.0.0+1`
**Jezik UI-ja:** engleski
**Licenca:** proprietary (isto kao CoinSight)

---

## FAZA 1 — Scaffold

**Cilj:** Flutter projekt scaffold, pubspec s dependencies, osnovna 3-tab navigacija, tamna tema, stub screens.

### Komande

```bash
flutter --version          # očekuj Flutter 3.41+, Dart 3.11+
flutter create --org com.betsight --project-name betsight .
flutter pub get
```

### Kreiraj direktorije

`lib/screens/`, `lib/widgets/`, `lib/services/`, `lib/models/`, `lib/theme/`

### Kreiraj/Ažuriraj fajlove

**`pubspec.yaml`** — dependencies točno ove verzije (identično CoinSightu):

```yaml
name: betsight
description: "AI-powered sports betting intelligence platform."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.0

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.4.0
  provider: ^6.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  intl: ^0.20.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.0

flutter:
  uses-material-design: true
```

**`lib/theme/app_theme.dart`** — klasa `AppTheme` sa static getterom `darkTheme` koji vraća `ThemeData`:

- `colorScheme`: fromSeed sa primary `#6C63FF`, secondary `#03DAC6`, surface `#1E1E1E`, error `#CF6679`
- `scaffoldBackgroundColor`: `#121212`
- `cardColor`: `#252525`
- dodatne konstante klase: `green = #4CAF50`, `red = #EF5350` (za P/L indikatore u kasnijim fazama)
- `AppBarTheme`: elevation 0, centerTitle true, background surface
- `BottomNavigationBarThemeData`: type fixed, selected primary `#6C63FF`, unselected `Colors.grey[400]`, background surface `#1E1E1E`
- `CardThemeData`: elevation 0, margin `EdgeInsets.symmetric(horizontal:12, vertical:6)`, shape RoundedRectangleBorder(borderRadius 12)
- `InputDecorationTheme`: filled true, fillColor `#252525`, border OutlineInputBorder(borderRadius 12, borderSide none), contentPadding 16
- `ElevatedButtonTheme`: backgroundColor primary, foregroundColor white, shape borderRadius 12, padding symmetric(h:16, v:12)
- `textTheme`: bodyLarge/bodyMedium/titleLarge sa Colors.white i Colors.grey[300]

**`lib/main.dart`:**

- `BetSightApp extends StatelessWidget` → MaterialApp (title "BetSight", theme AppTheme.darkTheme, home MainNavigation, debugShowCheckedModeBanner false)
- `MainNavigation extends StatefulWidget` s `_currentIndex = 0`
- `BottomNavigationBar` s 3 BottomNavigationBarItem:
  - Tab 0: icon `Icons.scoreboard_outlined` / active `Icons.scoreboard`, label "Matches"
  - Tab 1: icon `Icons.auto_awesome_outlined` / active `Icons.auto_awesome`, label "Analysis"
  - Tab 2: icon `Icons.settings_outlined` / active `Icons.settings`, label "Settings"
- Scaffold.body NE smije biti `_screens[_currentIndex]` — mora biti `IndexedStack(index: _currentIndex, children: [MatchesScreen(), AnalysisScreen(), SettingsScreen()])` (state-preserving tab switching — ovo je važno za buduće faze)
- `main()` function: `runApp(const BetSightApp())`

**`lib/screens/matches_screen.dart`** — stub: Scaffold(appBar: AppBar("BetSight"), body: Center(Text("Matches")))

**`lib/screens/analysis_screen.dart`** — stub: isto s "Analysis"

**`lib/screens/settings_screen.dart`** — stub: isto s "Settings"

**`test/widget_test.dart`** — prepraviti iz default counter testa u:

```dart
testWidgets('BetSightApp renders with bottom navigation', (tester) async {
  await tester.pumpWidget(const BetSightApp());
  expect(find.text('Matches'), findsWidgets);
  expect(find.text('Analysis'), findsWidgets);
  expect(find.text('Settings'), findsWidgets);
});
```

### Verifikacija Faze 1

- `flutter analyze` → **0 issues**
- `flutter build windows` → betsight.exe built successfully
- `flutter test` → 1/1 passed

### WORKLOG unos za Fazu 1

Napiši unos u stilu:

```markdown
# BetSight Worklog

## Session 1: YYYY-MM-DD — Initial Build (Faze 1-5)

### Phase 1 — Scaffold
**Status:** Completed

**Opis:** Inicijalni setup Flutter projekta.

**Komande izvršene:** [lista]

**Kreirani fajlovi:** [lista s kratkim opisom svakog fajla — 1-2 rečenice]

**Direktoriji kreirani:** [lista]

**Verifikacija:** flutter analyze 0 issues, flutter build windows uspješan, flutter test 1/1 passed
```

---

## FAZA 2 — The Odds API + Matches Screen

**Cilj:** Integracija The Odds API za multi-sport kvote, funkcionalan Matches screen s Sport filter chip-selektorom, MatchCard widget s kvotama.

### Pristup API-ju

The Odds API v4 base: `https://api.the-odds-api.com/v4`

- `GET /sports` — lista svih sportova (opcionalno za dinamičku listu)
- `GET /sports/{sport_key}/odds?regions=eu&markets=h2h&oddsFormat=decimal&apiKey={KEY}`
- Response header `x-requests-remaining` govori koliko je request-ova ostalo u mjesecu (free tier = 500)

**Default sport keys za MVP:**

- Nogomet: `soccer_epl`, `soccer_uefa_champs_league`
- Košarka: `basketball_nba`
- Tenis: `tennis_atp_singles` (ako API vrati 404 za ovaj ključ, probaj `tennis_atp_us_open` ili dinamički iz `/sports` endpointa — bilježi u Identified Issues ako nema aktivnog ATP turnira)

**Važno:** Korisnik u Fazi 1–3 NEMA API ključ spremljen (Faza 4 dodaje Settings). Dakle u ovoj fazi `OddsApiService` mora gracefully handlati prazan ključ — empty list + poruka "API key not configured". **NE hardkodiraj ključ u kod.** MatchesProvider detektira `hasApiKey == false` i vraća empty state s porukom.

### Kreiraj fajlove

**`lib/models/sport.dart`:**

```dart
enum Sport {
  soccer,
  basketball,
  tennis,
}

extension SportMeta on Sport {
  String get display => switch (this) {
    Sport.soccer => 'Soccer',
    Sport.basketball => 'Basketball',
    Sport.tennis => 'Tennis',
  };
  
  String get icon => switch (this) {
    Sport.soccer => '⚽',
    Sport.basketball => '🏀',
    Sport.tennis => '🎾',
  };
  
  bool get hasDraw => this == Sport.soccer;
  
  List<String> get defaultSportKeys => switch (this) {
    Sport.soccer => ['soccer_epl', 'soccer_uefa_champs_league'],
    Sport.basketball => ['basketball_nba'],
    Sport.tennis => ['tennis_atp_singles'],
  };
  
  static Sport? fromSportKey(String key) {
    if (key.startsWith('soccer_')) return Sport.soccer;
    if (key.startsWith('basketball_')) return Sport.basketball;
    if (key.startsWith('tennis_')) return Sport.tennis;
    return null;
  }
}
```

**`lib/models/odds.dart`:**

```dart
class H2HOdds {
  final double home;
  final double away;
  final double? draw;           // null za basketball i tennis
  final DateTime lastUpdate;
  final String bookmaker;
  
  const H2HOdds({
    required this.home,
    required this.away,
    this.draw,
    required this.lastUpdate,
    required this.bookmaker,
  });
  
  double get impliedHomeProb => 1 / home;
  double get impliedAwayProb => 1 / away;
  double? get impliedDrawProb => draw == null ? null : 1 / draw!;
  
  double get bookmakerMargin {
    final sum = impliedHomeProb + impliedAwayProb + (impliedDrawProb ?? 0);
    return sum - 1;
  }
}
```

**`lib/models/match.dart`:**

Match klasa s poljima: `id` (String), `sport` (Sport), `league` (String human readable, npr. "EPL"), `sportKey` (String API key), `home` (String), `away` (String), `commenceTime` (DateTime), `h2h` (H2HOdds?).

Factory `Match.fromJson(Map<String, dynamic> json, String sportKey)` — parsiraj:

- `id` iz `json['id']`
- `sportKey` iz parametra (jer Odds API vraća `sport_key` po matchu, ali u batch requestu često ne)
- `sport = SportMeta.fromSportKey(sportKey)` (ako null, throw FormatException)
- `league` = human readable mapping (maintain private `_leagueDisplayNames` Map u klasi: `'soccer_epl' → 'EPL'`, `'soccer_uefa_champs_league' → 'Champions League'`, `'basketball_nba' → 'NBA'`, `'tennis_atp_singles' → 'ATP'`)
- `home` iz `json['home_team']`, `away` iz `json['away_team']`
- `commenceTime` iz `DateTime.parse(json['commence_time'])`
- `h2h` — iz prvog bookmaker-a u `json['bookmakers']` koji ima `'h2h'` market. Ako nema, h2h je null. U markets[0].outcomes pronađi home team (name == home → home odds), away team (name == away → away odds), "Draw" (samo soccer → draw odds).

Getter-i: `isLive` (`DateTime.now().isAfter(commenceTime)`), `timeToKickoff` (Duration).

**`lib/services/odds_api_service.dart`:**

```dart
class OddsApiService {
  final http.Client _client;
  String _apiKey = '';
  int? _remainingRequests;
  
  static const _baseUrl = 'https://api.the-odds-api.com/v4';
  static const _timeout = Duration(seconds: 15);
  
  OddsApiService({http.Client? client}) : _client = client ?? http.Client();
  
  bool get hasApiKey => _apiKey.isNotEmpty;
  int? get remainingRequests => _remainingRequests;
  
  void setApiKey(String key) => _apiKey = key;
  
  Future<List<Match>> getMatches({
    required List<String> sportKeys,
    String regions = 'eu',
    List<String> markets = const ['h2h'],
  }) async {
    if (!hasApiKey) {
      throw OddsApiException('API key not configured');
    }
    
    final allMatches = <Match>[];
    for (final sportKey in sportKeys) {
      try {
        final uri = Uri.parse('$_baseUrl/sports/$sportKey/odds').replace(queryParameters: {
          'apiKey': _apiKey,
          'regions': regions,
          'markets': markets.join(','),
          'oddsFormat': 'decimal',
        });
        
        final response = await _client.get(uri).timeout(_timeout);
        
        // Track remaining requests
        final remaining = response.headers['x-requests-remaining'];
        if (remaining != null) _remainingRequests = int.tryParse(remaining);
        
        if (response.statusCode == 401) {
          throw OddsApiException('Invalid API key');
        } else if (response.statusCode == 429) {
          throw OddsApiException('Rate limit exceeded');
        } else if (response.statusCode == 422) {
          // Invalid sport key — bilježi i nastavi
          continue;
        } else if (response.statusCode != 200) {
          continue; // skip this sport but continue others
        }
        
        try {
          final data = json.decode(response.body) as List<dynamic>;
          for (final item in data) {
            try {
              allMatches.add(Match.fromJson(item as Map<String, dynamic>, sportKey));
            } on FormatException {
              continue; // skip malformed match
            }
          }
        } on FormatException {
          continue;
        }
      } on TimeoutException {
        continue; // skip this sport, continue with others
      }
    }
    
    // Sort by commence time
    allMatches.sort((a, b) => a.commenceTime.compareTo(b.commenceTime));
    return allMatches;
  }
  
  void dispose() => _client.close();
}

class OddsApiException implements Exception {
  final String message;
  OddsApiException(this.message);
  @override
  String toString() => 'OddsApiException: $message';
}
```

**`lib/models/matches_provider.dart`:**

MatchesProvider extends ChangeNotifier:

- Polja: `_service` (OddsApiService), `_allMatches` (List<Match>, default []), `_selectedSport` (Sport?, default null = all), `_isLoading` (bool), `_error` (String?)
- Konstruktor prima optional `OddsApiService`
- Getters: `allMatches`, `filteredMatches` (ako `_selectedSport == null` vrati sve, inače filter), `selectedSport`, `isLoading`, `error`, `remainingRequests` (iz servisa), `hasApiKey` (iz servisa)
- `setSelectedSport(Sport?)` — setuje i notifyListeners
- `setApiKey(String)` — prosljeđuje servisu (poziva se iz Faze 4 Settings)
- `fetchMatches()`: isLoading/error pattern, agregira sve defaultSportKeys iz sva 3 sporta, poziva servis, update _allMatches. Catch OddsApiException → seta error, catch generic → "Failed to load matches"
- `clearError()`

**`lib/widgets/odds_widget.dart`:**

OddsWidget (StatelessWidget) prikazuje 2 ili 3 kvote u Row:

- Za soccer (hasDraw=true): tri chipa "Home X.XX" / "Draw X.XX" / "Away X.XX"
- Za basketball/tennis: dva chipa "Home X.XX" / "Away X.XX"
- Chip = Container s borderRadius 8, border 1px primary s alpha 0.3, padding 8x4, sadržaj Column(label small grey, value bold white)
- Ako `h2h == null`: prikaži "Odds unavailable" u grey

**`lib/widgets/match_card.dart`:**

MatchCard (StatelessWidget) — props: `match`, `onTap` (optional VoidCallback):

- Card → InkWell → Padding(16) → Column:
  - Row 1 (header): Text(sport.icon) + SizedBox(8) + Text(league, bold) + Spacer + Text(relative time do kickoff-a, npr. "in 2h 15m" ili "LIVE")
  - SizedBox(12)
  - Row 2 (teams): Expanded(Text(home, centered)) + Text("vs", grey) + Expanded(Text(away, centered))
  - SizedBox(12)
  - Row 3: OddsWidget(match.h2h)
- LIVE status: ako `match.isLive`, pokazuj crveni "LIVE" badge umjesto countdown-a
- Koristi `intl` DateFormat za lijep prikaz kickoff-a kad je >24h

**`lib/widgets/sport_selector.dart`:**

SportSelector (StatelessWidget) — props: `selectedSport` (Sport?), `onSportSelected` (ValueChanged<Sport?>):

- Row sa 4 ChoiceChip-a: "All" (selected=null), "⚽ Soccer", "🏀 Basketball", "🎾 Tennis"
- Horizontal scroll ako ne stane
- ChoiceChip selectedColor = primary s alpha 0.3, labelStyle bold kad selected

### Ažuriraj fajlove

**`lib/screens/matches_screen.dart`** — kompletno prepisati:

- StatefulWidget s `initState` koji poziva `context.read<MatchesProvider>().fetchMatches()` ako `hasApiKey` (inače ne poziva)
- Scaffold.body → Column:
  - SportSelector na vrhu (Padding 16)
  - Expanded → Consumer<MatchesProvider>
    - Ako `!hasApiKey`: _buildNoApiKeyState (key_off icon + "The Odds API key required" + "Go to Settings to add your key")
    - Ako `isLoading && allMatches.isEmpty`: _buildSkeletonList (placeholder za sad — ili 6 Container skeletons; puni skeleton dolazi u Fazi 5)
    - Ako `error != null && allMatches.isEmpty`: error state s Retry buttonom (cloud_off icon + error + "Retry" → fetchMatches())
    - Ako `filteredMatches.isEmpty`: empty state (sentiment_neutral icon + "No matches found for this sport today")
    - Inače: RefreshIndicator → ListView.builder MatchCard-ova
- FloatingActionButton ili AppBar akcija NISU potrebni u S1

**`lib/main.dart`:** dodaj `MultiProvider` (iako je za sad samo jedan provider — priprema za Fazu 3):

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
  ],
  child: const BetSightApp(),
)
```

### Verifikacija Faze 2

- `flutter analyze` → **0 issues**
- `flutter build windows` → uspješan
- Manuelna provjera nije moguća bez API ključa — UI mora pokazivati "API key required" state

### WORKLOG unos za Fazu 2

Isti format kao Phase 1. Detalji linija za svaki Kreirani fajl su korisni ako ih Claude Code može generirati (npr. "Match.fromJson (25 linija)") — ali ne forsiraj ako to usporava rad.

---

## FAZA 3 — Anthropic/Claude Integration

**Cilj:** Chat sučelje s Claude AI za analizu mečeva i kvota. Identičan obrazac kao CoinSight Claude chat, ali sa **match context injection** umjesto watchlist injection.

### Kreiraj fajlove

**`lib/services/claude_service.dart`:**

```dart
class ClaudeService {
  final http.Client _client;
  String _apiKey = '';
  
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static const _apiVersion = '2023-06-01';
  static const _timeout = Duration(seconds: 30);
  static const _maxTokens = 1024;
  
  ClaudeService({http.Client? client}) : _client = client ?? http.Client();
  
  bool get hasApiKey => _apiKey.isNotEmpty;
  void setApiKey(String key) => _apiKey = key;
  
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String? systemPrompt,
  }) async {
    if (!hasApiKey) throw ClaudeException('API key not configured');
    
    final messages = <Map<String, dynamic>>[
      for (final msg in history) {'role': msg.role, 'content': msg.content},
      {'role': 'user', 'content': userMessage},
    ];
    
    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'messages': messages,
      if (systemPrompt != null) 'system': systemPrompt,
    };
    
    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _apiVersion,
        },
        body: json.encode(body),
      ).timeout(_timeout);
      
      if (response.statusCode == 401) throw ClaudeException('Invalid API key');
      if (response.statusCode == 429) throw ClaudeException('Rate limit exceeded');
      
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw ClaudeException('Malformed response from Claude');
      }
      
      if (response.statusCode != 200) {
        final errorMsg = data['error']?['message'] ?? 'Unknown error';
        throw ClaudeException(errorMsg.toString());
      }
      
      final content = data['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw ClaudeException('Empty response from Claude');
      }
      
      final textBlocks = content
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String);
      
      return textBlocks.join('\n').trim();
    } on TimeoutException {
      throw ClaudeException('Request timed out');
    }
  }
  
  void dispose() => _client.close();
}

class ChatMessage {
  final String role;      // 'user' ili 'assistant'
  final String content;
  final DateTime timestamp;
  
  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ClaudeException implements Exception {
  final String message;
  ClaudeException(this.message);
  @override
  String toString() => 'ClaudeException: $message';
}
```

**`lib/models/analysis_provider.dart`:**

AnalysisProvider extends ChangeNotifier:

- Polja: `_service` (ClaudeService), `_messages` (List<ChatMessage>), `_isLoading`, `_error`
- Konstruktor prima optional ClaudeService
- Getters: `messages`, `isLoading`, `error`, `hasApiKey`
- `_systemPrompt` — hardkodiran string:

```
You are BetSight AI, a sports betting intelligence assistant.
Your job is to help users analyze matches, odds, and betting value
across soccer, basketball, and tennis.

Guidelines:
- When match context is provided, use it directly in your analysis.
- Calculate implied probability from decimal odds (1/odds) and compare to your own estimate.
- Flag value bets where your estimate exceeds implied probability by a meaningful margin.
- Use structured recommendation labels: **VALUE**, **WATCH**, **SKIP**.
- Always mention bookmaker margin if it's unusually high (>8%).
- This is not financial advice. Users must DYOR and gamble responsibly.
```

- `setApiKey(String)`, `clearChat()`, `clearError()`
- `sendMessage(String text, {List<Match>? contextMatches})`:
  1. Build user message string via `_buildUserMessage(text, contextMatches)` — ako contextMatches nije null/empty, dodaj ispred pitanja blok `[SELECTED MATCHES]` s listom meču: `"{league}: {home} vs {away} | odds {h}-{d}-{a} | kickoff {isoTime}"` po matchu
  2. Dodaj user ChatMessage u `_messages`, setLoading true, notifyListeners
  3. Pozovi `_service.sendMessage` s history = svi `_messages` osim zadnjeg (jer zadnji je user message koji šaljemo sad)
  4. Na uspjeh: dodaj assistant ChatMessage u `_messages`
  5. Na grešku: ukloni zadnji user message, seta error
  6. Finally: setLoading false, notifyListeners

**`lib/widgets/chat_bubble.dart`:**

ChatBubble (StatelessWidget) — props: `text` (String), `isUser` (bool):

- Align: user centerRight, assistant centerLeft
- Container: maxWidth 80% screen, margin user(left:48, right:16), assistant(left:16, right:48)
- BoxDecoration: user = primary s alpha 0.2, assistant = card color `#252525`
- BorderRadius asymmetric: user (topLeft 16, topRight 16, bottomLeft 16, bottomRight 4), assistant (topLeft 16, topRight 16, bottomLeft 4, bottomRight 16)
- Child: SelectableText (za copy-paste support)

### Ažuriraj fajlove

**`lib/screens/analysis_screen.dart`** — kompletno prepisati kao StatefulWidget:

- Polja: `_textController` (TextEditingController), `_scrollController` (ScrollController)
- `dispose()` čisti controllere
- `_scrollToBottom()` s Future.delayed(100ms)
- `_sendMessage()`: uzme tekst, cleara controller, poziva `provider.sendMessage(text)`, tada `_scrollToBottom()`
- Scaffold.body → Consumer<AnalysisProvider>:
  - Ako `!hasApiKey`: _buildNoApiKeyState (key_off icon + "Anthropic API key required" + "Add your key in Settings")
  - Inače: Column:
    - Expanded → 
      - Ako `messages.isEmpty && !isLoading`: _buildEmptyState: auto_awesome icon + "Start your betting analysis" + Wrap sa 3 ActionChip-a kao suggestion chips: "Analyze today's EPL", "NBA value picks", "ATP upsets"
      - Inače: ListView.builder MessageBubble-ova + typing indicator ako `isLoading`
    - Ako `error != null`: error bar (red background, error text, X button → `provider.clearError()`)
    - _buildInputBar: Row sa delete_outline IconButton (→ confirm dialog → clearChat), TextField (maxLines: 4, hint "Ask about matches...", enabled: !isLoading), send IconButton (→ _sendMessage; disabled ako text empty ili isLoading)

**`lib/main.dart`** — dodaj AnalysisProvider u MultiProvider:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
  ],
  child: const BetSightApp(),
)
```

### Verifikacija Faze 3

- `flutter analyze` → **0 issues**
- `flutter build windows` → uspješan
- UI bez API ključa mora pokazati "API key required" state

---

## FAZA 4 — Hive Storage + Settings

**Cilj:** Lokalna persistencija za oba API ključa i user preferences, Settings screen s unosom.

### Kreiraj fajlove

**`lib/services/storage_service.dart`:**

```dart
class StorageService {
  static const _settingsBox = 'settings';
  
  // Field keys
  static const _anthropicApiKeyField = 'anthropic_api_key';
  static const _oddsApiKeyField = 'odds_api_key';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
  }
  
  static Box get _box => Hive.box(_settingsBox);
  
  // Anthropic API Key
  static String? getAnthropicApiKey() => _box.get(_anthropicApiKeyField) as String?;
  static Future<void> saveAnthropicApiKey(String key) => _box.put(_anthropicApiKeyField, key);
  static Future<void> deleteAnthropicApiKey() => _box.delete(_anthropicApiKeyField);
  
  // Odds API Key
  static String? getOddsApiKey() => _box.get(_oddsApiKeyField) as String?;
  static Future<void> saveOddsApiKey(String key) => _box.put(_oddsApiKeyField, key);
  static Future<void> deleteOddsApiKey() => _box.delete(_oddsApiKeyField);
}
```

### Ažuriraj fajlove

**`lib/models/matches_provider.dart`** — konstruktor čita key iz Storage i prosljeđuje servisu:

```dart
MatchesProvider({OddsApiService? service}) : _service = service ?? OddsApiService() {
  final key = StorageService.getOddsApiKey();
  if (key != null && key.isNotEmpty) _service.setApiKey(key);
}

Future<void> setApiKey(String key) async {
  _service.setApiKey(key);
  await StorageService.saveOddsApiKey(key);
  notifyListeners();
}

Future<void> removeApiKey() async {
  _service.setApiKey('');
  await StorageService.deleteOddsApiKey();
  _allMatches = [];
  notifyListeners();
}
```

**`lib/models/analysis_provider.dart`** — analogno za Anthropic ključ:

```dart
AnalysisProvider({ClaudeService? service}) : _service = service ?? ClaudeService() {
  final key = StorageService.getAnthropicApiKey();
  if (key != null && key.isNotEmpty) _service.setApiKey(key);
}

Future<void> setApiKey(String key) async {
  _service.setApiKey(key);
  await StorageService.saveAnthropicApiKey(key);
  notifyListeners();
}

Future<void> removeApiKey() async {
  _service.setApiKey('');
  await StorageService.deleteAnthropicApiKey();
  notifyListeners();
}
```

**`lib/screens/settings_screen.dart`** — kompletno prepisati:

StatefulWidget s dvije sekcije (API Keys + About):

- **API Keys sekcija** — dva podsekcije (Anthropic i Odds API), svaka ima:
  - Header Row: icon (key / dataset) + title + status badge (zeleni "Active" ako postoji, narančasti "Not set" ako ne)
  - TextField s `obscureText` (show/hide toggle preko suffixIcon vis/vis_off). onTap čisti masked tekst (jer inače korisnik tapne na "••••" i upisuje preko)
  - Row sa dva buttona: "Save" (ElevatedButton) i "Remove" (conditional TextButton, samo ako je key setovan)
  - Save flow: trim, validate non-empty, provider.setApiKey(), SnackBar "Saved", maskiraj polje
  - Remove flow: confirm dialog → provider.removeApiKey(), SnackBar "Removed", clear polje
  - Za Anthropic hint: "sk-ant-..."
  - Za Odds API hint: "Your the-odds-api.com key"

- **About sekcija**:
  - Divider
  - info rows (Icon + label: value): "Version 1.0.0+1", "Match Data: The Odds API", "AI Analysis: Claude (Anthropic)"
  - Divider
  - Disclaimer text (grey, small): "BetSight is not a betting agency. It is an informational tool. All betting decisions are your own. Gamble responsibly."
  - Link text (greyed hint): "Get an Odds API key at the-odds-api.com" (koristiš `SelectableText` sa copy ikonom — NE koristimo url_launcher u ovoj fazi)

**`lib/main.dart`** — dodaj inicijalizaciju Hive PRIJE runApp:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('StorageService init failed: $e');
  }
  runApp(const BetSightApp());
}
```

### Verifikacija Faze 4

- `flutter analyze` → **0 issues**
- `flutter build windows` → uspješan

---

## FAZA 5 — Polish

**Cilj:** Error handling, loading states, UX poboljšanja. Identičan obrazac kao CoinSight Polish.

### Ažuriraj fajlove

**`lib/services/odds_api_service.dart`** — osiguraj da timeout + FormatException catch već postoje (trebalo bi biti iz Faze 2); ako nedostaje, dodaj.

**`lib/services/claude_service.dart`** — isto (trebalo bi biti iz Faze 3).

**`lib/widgets/match_card.dart`:**

- Dodaj `AnimatedSwitcher(duration: 250ms)` na LIVE badge (pojavljuje se u trenutku kickoff-a kad timer otkuca)
- Dodaj StatefulWidget wrapper s Timer.periodic(Duration(seconds: 30), (_) => setState()) za redovno refresh countdown display-a (LIVE status i "in Xm" countdown)
- Timer se cancela u dispose()

**`lib/widgets/match_card.dart`** — dodaj NOVI widget `MatchCardSkeleton` (StatefulWidget sa AnimationController 1200ms repeat reverse, Tween 0.3→0.6, CurvedAnimation easeInOut):

- Card s istim layoutom kao MatchCard ali shimmerBox-ovi umjesto stvarnog sadržaja
- 3 reda: header skeleton, teams skeleton, odds skeleton
- Boja: `Colors.grey[800]!.withValues(alpha: _animation.value)`

**`lib/screens/matches_screen.dart`:**

- `_buildSkeletonList()`: ListView.builder sa 6 `MatchCardSkeleton` widgeta (zamjena placeholder skeletona iz Faze 2)
- Error bar je Dismissible (horizontal)

**`lib/screens/analysis_screen.dart`:**

- Dodaj `_disposed = false` flag polje, seta se u dispose()
- `_scrollToBottom()`: double guard `if (_disposed || !_scrollController.hasClients) return` prije i unutar Future.delayed
- `_sendMessage()`: nakon poziva provider.sendMessage dodaj `.then((_) => _scrollToBottom())`
- TextField: `enabled: !provider.isLoading`, hint "Waiting for response..." kad loading
- Error bar: Dismissible + X button za dismiss
- `_confirmClearChat()`: AlertDialog s Cancel/Clear buttonima
- Input bar delete button → `_confirmClearChat`

**`lib/screens/settings_screen.dart`:**

- Remove flow confirm dialog (AlertDialog, ne SnackBar)
- Status badge animacije (AnimatedSwitcher 250ms na badge promjenu)

**`lib/main.dart`:**

- Scaffold.body je već IndexedStack iz Faze 1 ✓
- StorageService.init() je već u try/catch iz Faze 4 ✓

### Verifikacija Faze 5

- `flutter analyze` → **0 issues**
- `flutter build windows` → uspješan
- Manuelna vizualna verifikacija: skeletoni se pojavljuju, countdown tiče, AnimatedSwitcher-i glatko mijenjaju stanje

---

## POST-PHASE — Audit, Documentation & Git Setup

**Cilj:** Finalizacija — audit, cleanup, dokumentacija, git.

### Audit

Pročitaj svih ~14 Dart fajlova u `lib/`. Provjeri:

- Null safety strict compliance
- Svi `dispose()` pozivi na mjestu (controllers, services)
- Nema hardkodiranih API ključeva
- Svi providers pravilno wired u MultiProvider
- Import-i clean (nema nekorištenih)

**Zabilježi nalaze** u WORKLOG (ovaj postupak je napravljen u CoinSightu s dva paralelna agenta — ako možeš, uradi isto, inače jedan prolaz).

### Cleanup

Ukloni iz `pubspec.yaml` sve dependencies koji nisu importani igdje. Pokreni `flutter pub get`.

### Kreiraj fajlove

**`LICENSE`** — Proprietary Software License, identičan tekst kao CoinSight LICENSE (5 restrikcija: no copy, no modify, no distribute, no reverse engineer, no transfer; confidentiality clause; AS-IS disclaimer; auto-termination). Copyright: "(c) 2026 BetSight. All rights reserved."

**`README.md`** — kompletna dokumentacija (struktura kao CoinSight README):

- Header s badge-ovima (Flutter, Dart, License, Version, Platform)
- "What is BetSight" intro
- Features tablica (Matches, AI Analysis, Settings)
- Tech Stack tablica (isti layout kao CoinSight)
- Architecture tree (ls lib/)
- Setup sekcija (prerequisites, flutter pub get, flutter run)
- Configuration (dva API keya — gdje ih dobiti, kako ih unijeti u Settings)
- API Usage tablica (The Odds API free tier limits, Anthropic Claude)
- Error Handling tablica (6+ scenarija)
- Security sekcija
- License footer

### Ažuriraj fajlove

**`.gitignore`** — dodaj:

```
# Secrets
.env
.env.*
*.env

# Hive
.hive/

# Dev logs
chat_log.md
work_log.md

# APK/bundles
*.apk
*.aab
```

**`windows/runner/Runner.rc`** — branding:

- CompanyName: `"BetSight"`
- FileDescription: `"BetSight - AI-Powered Sports Betting Intelligence"`
- LegalCopyright: `"Copyright (C) 2026 BetSight. All rights reserved. Proprietary and confidential."`
- ProductName: `"BetSight"`

**`test/widget_test.dart`** — ako je proširiti potrebno:

```dart
import 'dart:io';
import 'package:hive/hive.dart';

setUpAll(() async {
  final tempDir = Directory.systemTemp.createTempSync();
  Hive.init(tempDir.path);
});
```

Dodaj drugi test "Bottom navigation switches tabs" koji tapka na Analysis i Settings, provjerava "API key required" stringove (jer app nema keyove u testu).

### Git

```bash
git init
git add .
git commit -m "Initial commit: BetSight v1.0.0"
```

**Dodatni WORKLOG commit** s detaljnim WORKLOG-om (opcionalno, dvostupanjski commit kao CoinSight).

### Finalna verifikacija

- `flutter analyze` — **0 issues**
- `flutter test` — **2/2 passed**
- `flutter build windows` — betsight.exe built successfully

### Finalni WORKLOG unos

Dodaj na kraj `## Session 1: YYYY-MM-DD — Initial Build` sekciju:

```markdown
### Post-Phase — Audit, Documentation & Git Setup
**Status:** Completed

**Audit rezultati:** [broj fajlova, nalazi]

**Cleanup:** [koji paketi uklonjeni, ako ikoji]

**Kreirani fajlovi:** LICENSE, README.md, WORKLOG.md

**Ažurirani fajlovi:** .gitignore, windows/runner/Runner.rc, test/widget_test.dart, pubspec.yaml

**Git:** initial commit `<hash>`: "Initial commit: BetSight v1.0.0" — X fajlova, Y insertions

**Finalna verifikacija Session 1:**
- flutter analyze — 0 issues
- flutter test — 2/2 passed
- flutter build windows — betsight.exe built

---

## Identified Issues

[Lista svih issues skupljenih tijekom faza 1-5; ako nema, napiši "*No unresolved issues at this time.*"]
```

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Kad si gotov sa svim fazama i Post-Phase, napiši sažetak developeru:

- Ukupno sesija izvršeno: 1 (Faza 1-5 + Post-Phase)
- Broj Dart fajlova u lib/: [X]
- Linije koda (otprilike): [Y]
- Flutter analyze status: 0 issues
- Flutter test status: [N]/[N] passed
- Flutter build windows: uspješan
- Git initial commit hash: [hash]
- Sljedeći predloženi korak: **Developer registrira API ključeve** (Anthropic console + The Odds API), unosi ih u Settings, testira E2E flow (Matches screen prikazuje real kvote, Analysis chat radi s match context injection). Nakon što developer potvrdi da E2E radi, planira se SESSION 2 s `New Value Filter` i strukturiranim Claude recommendation markerom (`**VALUE**` / `**WATCH**` / `**SKIP**`).

Kraj SESSION 1.
