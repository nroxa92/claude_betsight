# BetSight SESSION 4 — Telegram Tipster Monitor + Odds Snapshot Engine

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S3 povijest — posebno S3 zbog BetsProvider/Bet modela i S2 zbog NavigationController pattern-a)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći (za Task 5 bonus pokreni i `flutter build apk --debug`)
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 4: YYYY-MM-DD — Telegram Tipster Monitor + Odds Snapshot Engine`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Samo `git status` je dozvoljen. Developer preuzima `git add -A; git commit; git push`.

**Identified Issues:** Jedan poznati issue uvodi se u ovom task-u, zabilježi ga odmah u Task 1 kako bi se znao kontekst. Ako naiđeš na druge probleme izvan scope-a, zabilježi i njih.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 1.3.0+4`.

---

## Projektni kontekst

S1–S3 su izgradili **closed loop**: Matches → Analyze → VALUE marker → Log Bet → Settle → P&L. App radi, ali korisnik dobiva samo ono što je unio sam. **S4 otvara prve kanale za vanjski intelligence flow:**

1. **Telegram Tipster Monitor** (glavni dio) — pasivni čitač javnih tipster kanala. Korisnik daje bot token + popis kanala; app skuplja poruke koje izgledaju kao bet signali (ključne riječi, liga/tim imena). Signali se ne auto-trustaju — služe kao dodatni context uz Claude analizu i kao "signal feed" u Analysis screenu.

2. **Odds Snapshot Engine** (bonus) — korisnik može "watch-ati" mečeve (star toggle na MatchCard). Pri svakom refresh-u Matches ekrana, trenutne kvote se snapshottaju u Hive box. Ako postoji ≥2 snapshota za watched match, MatchCard prikazuje mini **drift indicator** (↑/↓ s postotkom) — primitivan sharp money detektor bez pozadinskog servisa (štedimo Odds API kvotu).

**Novi Hive boxovi u S4:** `tipster_signals`, `odds_snapshots`
**Novi provideri u S4:** `TelegramProvider`
**Ažurirani model:** MatchesProvider dobiva watched matches + snapshot logic

---

## POZNATO OGRANIČENJE — zabilježi u Identified Issues odmah u Tasku 1

**Telegram Bot API vs MTProto:** Telegram bot može primati poruke **samo iz chatova i kanala gdje je bot dodan kao član**. Većina popularnih tipster kanala NE dozvoljava random bot-ove. To znači da korisnik u praksi može monitorirati:

- Vlastite kanale (gdje je admin)
- Kanale kojih je vlasnik / gdje je bot dobio pristup
- Male zajednice koje specifično dodaju bot

**Za S4 ovo je prihvatljivo ograničenje.** U budućnosti (S7+) može se razmotriti migracija na **MTProto** (Telegram API direktno, user-level auth s API ID + Hash + phone) koja omogućuje čitanje svih javnih kanala. MTProto je značajno kompleksnija integracija (treba `tdlib` ili sličan Dart wrapper) i nije MVP-prijateljska.

**Zapis u Identified Issues na početku Taska 1:**
```
- **Telegram Bot API limitation:** Bot prima poruke samo iz kanala gdje je dodan kao član. Public tipster kanali koji ne dozvoljavaju bot-ove nisu dostupni kroz Bot API. Za full public channel access trebala bi MTProto migracija u kasnijoj sesiji.
```

---

## TASK 1 — TipsterSignal Model + TelegramMonitor Service + Hive Box

**Cilj:** Data + transport layer za Telegram integraciju. Bez UI, samo kostur.

### Kreiraj fajlove

**`lib/models/tipster_signal.dart`:**

```dart
class TipsterSignal {
  final String id;                    // UUID — koristi generateUuid()
  final int telegramMessageId;        // iz Telegram getUpdates
  final String channelUsername;       // npr. "@tipsmaster"
  final String channelTitle;          // display name kanala
  final String text;                  // raw poruka text
  final DateTime receivedAt;
  final Sport? detectedSport;         // heuristički detectiran sport (može biti null)
  final String? detectedLeague;       // heuristički detectiran league (može biti null)
  final bool isRelevant;              // true ako prošao keyword filter, false ako samo dedup
  
  const TipsterSignal({
    required this.id,
    required this.telegramMessageId,
    required this.channelUsername,
    required this.channelTitle,
    required this.text,
    required this.receivedAt,
    this.detectedSport,
    this.detectedLeague,
    required this.isRelevant,
  });
  
  /// Truncated preview za UI
  String get preview {
    final trimmed = text.trim();
    if (trimmed.length <= 150) return trimmed;
    return '${trimmed.substring(0, 147)}...';
  }
  
  /// Format za Claude context injection
  String toClaudeContext() {
    final timeAgo = _relativeTime(receivedAt);
    final sport = detectedSport?.display ?? 'unknown sport';
    return '[$timeAgo] $channelUsername ($sport): ${preview}';
  }
  
  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'telegramMessageId': telegramMessageId,
    'channelUsername': channelUsername,
    'channelTitle': channelTitle,
    'text': text,
    'receivedAt': receivedAt.toIso8601String(),
    'detectedSport': detectedSport?.name,
    'detectedLeague': detectedLeague,
    'isRelevant': isRelevant,
  };
  
  factory TipsterSignal.fromMap(Map<dynamic, dynamic> map) => TipsterSignal(
    id: map['id'] as String,
    telegramMessageId: map['telegramMessageId'] as int,
    channelUsername: map['channelUsername'] as String,
    channelTitle: map['channelTitle'] as String,
    text: map['text'] as String,
    receivedAt: DateTime.parse(map['receivedAt'] as String),
    detectedSport: map['detectedSport'] == null
        ? null
        : Sport.values.firstWhere((s) => s.name == map['detectedSport']),
    detectedLeague: map['detectedLeague'] as String?,
    isRelevant: map['isRelevant'] as bool,
  );
}
```

**`lib/services/telegram_monitor.dart`:**

```dart
class TelegramMonitor {
  final http.Client _client;
  String _botToken = '';
  int _lastUpdateId = 0;
  Timer? _pollTimer;
  void Function(TipsterSignal)? onSignalReceived;
  
  static const _baseUrl = 'https://api.telegram.org';
  static const _timeout = Duration(seconds: 15);
  static const _pollInterval = Duration(seconds: 10);
  
  // Keyword filter za relevance detection
  static const _relevanceKeywords = [
    'tip', 'bet', 'value', 'lock', 'odds', 'pick', 'stake',
    'vs', 'home', 'away', 'draw', 'over', 'under', 'handicap',
    'epl', 'nba', 'atp', 'wta', 'champions',
  ];
  
  TelegramMonitor({http.Client? client}) : _client = client ?? http.Client();
  
  bool get hasToken => _botToken.isNotEmpty;
  bool get isMonitoring => _pollTimer?.isActive ?? false;
  
  void setBotToken(String token) {
    final wasMonitoring = isMonitoring;
    stopMonitoring();
    _botToken = token;
    if (wasMonitoring) startMonitoring();
  }
  
  void startMonitoring() {
    if (!hasToken || isMonitoring) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll(); // first poll immediately
  }
  
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
  
  /// Test connection with getMe endpoint
  Future<Map<String, dynamic>> testConnection() async {
    if (!hasToken) throw TelegramException('Bot token not configured');
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/bot$_botToken/getMe'))
          .timeout(_timeout);
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) {
        throw TelegramException(data['description']?.toString() ?? 'Unknown error');
      }
      return data['result'] as Map<String, dynamic>;
    } on TimeoutException {
      throw TelegramException('Request timed out');
    } on FormatException {
      throw TelegramException('Malformed response');
    }
  }
  
  Future<void> _poll() async {
    if (!hasToken) return;
    try {
      final uri = Uri.parse('$_baseUrl/bot$_botToken/getUpdates').replace(queryParameters: {
        'offset': (_lastUpdateId + 1).toString(),
        'timeout': '0',
        'allowed_updates': '["channel_post","message"]',
      });
      
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return;
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['ok'] != true) return;
      
      final updates = (data['result'] as List<dynamic>?) ?? [];
      for (final update in updates) {
        final map = update as Map<String, dynamic>;
        final updateId = map['update_id'] as int;
        if (updateId > _lastUpdateId) _lastUpdateId = updateId;
        
        final post = map['channel_post'] ?? map['message'];
        if (post == null) continue;
        
        final signal = _parseUpdate(post as Map<String, dynamic>);
        if (signal != null) onSignalReceived?.call(signal);
      }
    } catch (e) {
      // Silent fail — poll će se ponoviti
    }
  }
  
  TipsterSignal? _parseUpdate(Map<String, dynamic> post) {
    final text = post['text'] as String? ?? post['caption'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    
    final messageId = post['message_id'] as int;
    final chat = post['chat'] as Map<String, dynamic>?;
    if (chat == null) return null;
    
    final username = chat['username'] as String?;
    final title = chat['title'] as String? ?? 'Unknown';
    if (username == null) return null; // skip private chats
    
    final lowerText = text.toLowerCase();
    final isRelevant = _relevanceKeywords.any((kw) => lowerText.contains(kw));
    if (!isRelevant) return null; // skip noise
    
    // Heuristic sport/league detection
    Sport? detectedSport;
    String? detectedLeague;
    if (lowerText.contains('epl') || lowerText.contains('premier league')) {
      detectedSport = Sport.soccer;
      detectedLeague = 'EPL';
    } else if (lowerText.contains('champions league') || lowerText.contains('ucl')) {
      detectedSport = Sport.soccer;
      detectedLeague = 'Champions League';
    } else if (lowerText.contains('nba')) {
      detectedSport = Sport.basketball;
      detectedLeague = 'NBA';
    } else if (lowerText.contains('atp') || lowerText.contains('wta')) {
      detectedSport = Sport.tennis;
    }
    
    return TipsterSignal(
      id: generateUuid(),
      telegramMessageId: messageId,
      channelUsername: '@$username',
      channelTitle: title,
      text: text.trim(),
      receivedAt: DateTime.now(),
      detectedSport: detectedSport,
      detectedLeague: detectedLeague,
      isRelevant: true,
    );
  }
  
  void dispose() {
    stopMonitoring();
    _client.close();
  }
}

class TelegramException implements Exception {
  final String message;
  TelegramException(this.message);
  @override
  String toString() => 'TelegramException: $message';
}
```

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump: `version: 1.3.0+4`

**`lib/services/storage_service.dart`** — dodaj `tipster_signals` box:

```dart
static const _tipsterSignalsBox = 'tipster_signals';
static const _telegramTokenField = 'telegram_bot_token';
static const _monitoredChannelsField = 'monitored_channels';
static const _telegramEnabledField = 'telegram_enabled';

// u init():
await Hive.openBox(_tipsterSignalsBox);

static Box get _signalsBox => Hive.box(_tipsterSignalsBox);

// Signals CRUD
static Future<void> saveSignal(TipsterSignal signal) =>
    _signalsBox.put(signal.id, signal.toMap());

static List<TipsterSignal> getAllSignals() {
  final maps = _signalsBox.values.toList();
  final signals = <TipsterSignal>[];
  for (final map in maps) {
    try {
      signals.add(TipsterSignal.fromMap(map as Map<dynamic, dynamic>));
    } catch (_) {
      // skip malformed
    }
  }
  signals.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  return signals;
}

static Future<int> clearOldSignals({Duration keepFor = const Duration(days: 7)}) async {
  final cutoff = DateTime.now().subtract(keepFor);
  final keys = <dynamic>[];
  for (final key in _signalsBox.keys) {
    try {
      final signal = TipsterSignal.fromMap(_signalsBox.get(key) as Map<dynamic, dynamic>);
      if (signal.receivedAt.isBefore(cutoff)) keys.add(key);
    } catch (_) {
      keys.add(key); // delete malformed
    }
  }
  for (final k in keys) { await _signalsBox.delete(k); }
  return keys.length;
}

// Telegram settings (in settings box)
static String? getTelegramToken() => _box.get(_telegramTokenField) as String?;
static Future<void> saveTelegramToken(String token) => _box.put(_telegramTokenField, token);
static Future<void> deleteTelegramToken() => _box.delete(_telegramTokenField);

static List<String> getMonitoredChannels() =>
    (_box.get(_monitoredChannelsField) as List<dynamic>?)?.cast<String>() ?? [];
static Future<void> saveMonitoredChannels(List<String> channels) =>
    _box.put(_monitoredChannelsField, channels);

static bool getTelegramEnabled() => (_box.get(_telegramEnabledField) as bool?) ?? false;
static Future<void> saveTelegramEnabled(bool enabled) => _box.put(_telegramEnabledField, enabled);
```

**Dodaj u `WORKLOG.md` Identified Issues sekciju (replace `*No unresolved issues at this time.*`):**

```markdown
## Identified Issues

- **Telegram Bot API limitation:** Bot prima poruke samo iz kanala gdje je dodan kao član. Public tipster kanali koji ne dozvoljavaju bot-ove nisu dostupni kroz Bot API. Za full public channel access trebala bi MTProto migracija u kasnijoj sesiji.
```

### Verifikacija Taska 1

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 2 — TelegramProvider + Main Lifecycle

**Cilj:** State management za Telegram i auto-start monitor pri pokretanju app-a ako je enabled.

### Kreiraj fajlove

**`lib/models/telegram_provider.dart`:**

```dart
class TelegramProvider extends ChangeNotifier {
  final TelegramMonitor _monitor;
  List<TipsterSignal> _signals = [];
  List<String> _monitoredChannels = [];
  bool _enabled = false;
  String? _error;
  
  TelegramProvider({TelegramMonitor? monitor}) : _monitor = monitor ?? TelegramMonitor() {
    _monitor.onSignalReceived = _handleNewSignal;
    
    // Load saved state
    _signals = StorageService.getAllSignals();
    _monitoredChannels = StorageService.getMonitoredChannels();
    _enabled = StorageService.getTelegramEnabled();
    
    final token = StorageService.getTelegramToken();
    if (token != null && token.isNotEmpty) {
      _monitor.setBotToken(token);
      if (_enabled) _monitor.startMonitoring();
    }
  }
  
  // Getters
  List<TipsterSignal> get signals => List.unmodifiable(_signals);
  List<TipsterSignal> get recentSignals {
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));
    return _signals.where((s) => s.receivedAt.isAfter(sixHoursAgo)).toList();
  }
  
  List<TipsterSignal> signalsForSport(Sport? sport) {
    if (sport == null) return recentSignals;
    return recentSignals.where((s) => s.detectedSport == sport).toList();
  }
  
  List<String> get monitoredChannels => List.unmodifiable(_monitoredChannels);
  bool get enabled => _enabled;
  bool get hasToken => _monitor.hasToken;
  bool get isMonitoring => _monitor.isMonitoring;
  String? get error => _error;
  int get recentCount => recentSignals.length;
  
  // Methods
  Future<void> setBotToken(String token) async {
    _monitor.setBotToken(token);
    await StorageService.saveTelegramToken(token);
    notifyListeners();
  }
  
  Future<void> removeBotToken() async {
    _monitor.stopMonitoring();
    _monitor.setBotToken('');
    await StorageService.deleteTelegramToken();
    await setEnabled(false);
    notifyListeners();
  }
  
  Future<void> addChannel(String channel) async {
    final clean = channel.trim();
    if (clean.isEmpty || _monitoredChannels.contains(clean)) return;
    _monitoredChannels = [..._monitoredChannels, clean];
    await StorageService.saveMonitoredChannels(_monitoredChannels);
    notifyListeners();
  }
  
  Future<void> removeChannel(String channel) async {
    _monitoredChannels = _monitoredChannels.where((c) => c != channel).toList();
    await StorageService.saveMonitoredChannels(_monitoredChannels);
    notifyListeners();
  }
  
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await StorageService.saveTelegramEnabled(enabled);
    if (enabled && hasToken) {
      _monitor.startMonitoring();
    } else {
      _monitor.stopMonitoring();
    }
    notifyListeners();
  }
  
  Future<String> testConnection() async {
    try {
      final info = await _monitor.testConnection();
      final botName = info['username'] ?? info['first_name'] ?? 'Bot';
      _error = null;
      notifyListeners();
      return '@$botName';
    } catch (e) {
      _error = e is TelegramException ? e.message : 'Connection failed';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> clearOldSignals() async {
    await StorageService.clearOldSignals();
    _signals = StorageService.getAllSignals();
    notifyListeners();
  }
  
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
  
  void _handleNewSignal(TipsterSignal signal) {
    // Dedup: skip ako već imamo signal s istim telegramMessageId i channelUsername
    final exists = _signals.any((s) =>
        s.telegramMessageId == signal.telegramMessageId &&
        s.channelUsername == signal.channelUsername);
    if (exists) return;
    
    // Filter: skip ako kanal nije u monitored list (only if list is non-empty)
    if (_monitoredChannels.isNotEmpty && !_monitoredChannels.contains(signal.channelUsername)) {
      return;
    }
    
    _signals = [signal, ..._signals];
    StorageService.saveSignal(signal);
    notifyListeners();
  }
  
  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }
}
```

### Ažuriraj fajlove

**`lib/main.dart`** — dodaj TelegramProvider u MultiProvider:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NavigationController()),
    ChangeNotifierProvider(create: (_) => MatchesProvider()),
    ChangeNotifierProvider(create: (_) => AnalysisProvider()),
    ChangeNotifierProvider(create: (_) => BetsProvider()),
    ChangeNotifierProvider(create: (_) => TelegramProvider()),
  ],
  child: const BetSightApp(),
)
```

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 3 — Telegram Settings Section

**Cilj:** Korisnik može konfigurirati bot token, dodati/ukloniti kanale, uključiti/isključiti monitoring.

### Ažuriraj fajlove

**`lib/screens/settings_screen.dart`** — dodaj novu sekciju **"Telegram Monitor"** između "Bankroll" i "About":

Struktura (nova privatna klasa `_TelegramSection` StatefulWidget, slično kao `_ApiKeySection` koja već postoji):

```
┌─────────────────────────────────────────┐
│ 📡 Telegram Monitor        [Active ●]   │
│                                         │
│ Bot token     [••••••••••] 👁  [Save]   │
│                            [Test][Remove]│
│                                         │
│ Monitored channels:                     │
│   @tipsmaster          [×]              │
│   @bettingexperts      [×]              │
│   [_____________________] [+ Add]       │
│                                         │
│ Monitoring: [●○] Off                    │
│                                         │
│ ⓘ Bot must be member of channels        │
└─────────────────────────────────────────┘
```

Implementacija:
- Bot token field s `obscureText` + visibility toggle + Save/Remove/Test buttons (analogno postojećim API key sekcijama)
- Test Connection: tap → `provider.testConnection()` → SnackBar s bot username-om ili error porukom
- Monitored channels: Consumer<TelegramProvider> → Wrap s Chip-ovima (brisanje kroz deleteIcon), TextField + Add button za dodavanje
- Channel validacija: mora počinjati s `@`, min 5 karaktera (npr. `@abc` ne, `@abcde` da)
- Enable toggle: SwitchListTile s `provider.enabled`, disabled ako nema token-a, onChanged → `provider.setEnabled(value)`
- Info text: ikona info + "Bot must be added as member to channels you want to monitor. Create one via @BotFather."

Helper link: SelectableText "Create bot: https://t.me/BotFather" (info only, bez launch-a — S1 pattern).

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 4 — Signal UI u Analysis Screen + Context Injection

**Cilj:** Korisnik u Analysis screenu vidi signal feed i može ga iskoristiti kao context za Claude analizu.

### Ažuriraj fajlove

**`lib/models/analysis_provider.dart`** — dodaj optional signals u context injection:

```dart
List<TipsterSignal> _stagedSignals = [];
List<TipsterSignal> get stagedSignals => List.unmodifiable(_stagedSignals);
bool get hasStagedSignals => _stagedSignals.isNotEmpty;

void stageSelectedSignals(List<TipsterSignal> signals) {
  _stagedSignals = List.from(signals);
  notifyListeners();
}

void clearStagedSignals() {
  if (_stagedSignals.isEmpty) return;
  _stagedSignals = [];
  notifyListeners();
}
```

U `_buildUserMessage()` ili ekvivalentu:
- Ako `_stagedSignals.isNotEmpty`, dodaj blok `[TIPSTER SIGNALS]` ispod `[SELECTED MATCHES]` bloka
- Format: `\n[TIPSTER SIGNALS]\n${_stagedSignals.map((s) => s.toClaudeContext()).join('\n')}\n[/TIPSTER SIGNALS]`
- Nakon uspješnog send-a, čisti i `_stagedSignals` (kao što se čisti `_stagedMatches`)

**`lib/screens/analysis_screen.dart`** — dodaj signal feed UI:

1. **Signal banner iznad chat liste** (kad postoji `recentCount > 0` u TelegramProvider):
   - Consumer<TelegramProvider> → Container s primary boja alpha 0.1, border alpha 0.3
   - Tekst: "${count} recent tipster signals" + GestureDetector "View →" koji otvara `_showSignalSheet(context)`

2. **`_showSignalSheet(BuildContext context)`** — showModalBottomSheet full-height s:
   - Header: "Recent Signals" + close button
   - Sport filter chips (All / Soccer / Basketball / Tennis)
   - ListView signal kartica (novi privatni widget `_SignalCard`): channel title + time ago + sport icon + preview text + checkbox za selection
   - Footer: "${selectedCount} selected" + FilledButton "Use as context" → `provider.stageSelectedSignals(selected)` + Navigator.pop + SnackBar

3. **Staged signals bar** (iznad input bar-a, ispod staged matches bar-a):
   - Analogno staged matches banner iz S2 Task 5 — primary boja chip s "X tipster signals staged for next question" + close icon

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 5 — BONUS: Odds Snapshot Engine

**Cilj:** Korisnik može "watch-ati" mečeve (star toggle). Pri svakom fetchMatches-u, trenutna H2H kvota se sprema kao snapshot. MatchCard za watched meč prikazuje mini drift indicator ako postoji ≥2 snapshota.

### Kreiraj fajlove

**`lib/models/odds_snapshot.dart`:**

```dart
class OddsSnapshot {
  final String matchId;
  final DateTime capturedAt;
  final double home;
  final double? draw;
  final double away;
  final String bookmaker;
  
  const OddsSnapshot({
    required this.matchId,
    required this.capturedAt,
    required this.home,
    this.draw,
    required this.away,
    required this.bookmaker,
  });
  
  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'capturedAt': capturedAt.toIso8601String(),
    'home': home,
    'draw': draw,
    'away': away,
    'bookmaker': bookmaker,
  };
  
  factory OddsSnapshot.fromMap(Map<dynamic, dynamic> map) => OddsSnapshot(
    matchId: map['matchId'] as String,
    capturedAt: DateTime.parse(map['capturedAt'] as String),
    home: (map['home'] as num).toDouble(),
    draw: map['draw'] == null ? null : (map['draw'] as num).toDouble(),
    away: (map['away'] as num).toDouble(),
    bookmaker: map['bookmaker'] as String,
  );
}

/// Computes drift between two snapshots (older vs newer).
/// Returns negative % if odds dropped (sharp money toward that side), positive if drifted up.
class OddsDrift {
  final double homePercent;
  final double? drawPercent;
  final double awayPercent;
  
  const OddsDrift({
    required this.homePercent,
    this.drawPercent,
    required this.awayPercent,
  });
  
  static OddsDrift compute(OddsSnapshot older, OddsSnapshot newer) {
    double pct(double o, double n) => ((n - o) / o) * 100;
    return OddsDrift(
      homePercent: pct(older.home, newer.home),
      drawPercent: (older.draw != null && newer.draw != null)
          ? pct(older.draw!, newer.draw!)
          : null,
      awayPercent: pct(older.away, newer.away),
    );
  }
  
  /// Largest absolute drift side — useful za primary indicator
  ({String side, double percent}) get dominantDrift {
    final candidates = <(String, double)>[
      ('Home', homePercent),
      if (drawPercent != null) ('Draw', drawPercent!),
      ('Away', awayPercent),
    ];
    candidates.sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
    return (side: candidates.first.$1, percent: candidates.first.$2);
  }
  
  bool get hasSignificantMove => homePercent.abs() > 3 ||
      awayPercent.abs() > 3 ||
      (drawPercent?.abs() ?? 0) > 3;
}
```

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj `odds_snapshots` box + watched matches field:

```dart
static const _oddsSnapshotsBox = 'odds_snapshots';
static const _watchedMatchIdsField = 'watched_match_ids';

// in init():
await Hive.openBox(_oddsSnapshotsBox);

static Box get _snapshotsBox => Hive.box(_oddsSnapshotsBox);

// Snapshots key pattern: "${matchId}_${isoTimestamp}"
// This way sve snapshots za match su grupirani po prefixu
static Future<void> saveSnapshot(OddsSnapshot snapshot) async {
  final key = '${snapshot.matchId}_${snapshot.capturedAt.toIso8601String()}';
  await _snapshotsBox.put(key, snapshot.toMap());
}

static List<OddsSnapshot> getSnapshotsForMatch(String matchId) {
  final snapshots = <OddsSnapshot>[];
  for (final key in _snapshotsBox.keys) {
    if (key is String && key.startsWith('${matchId}_')) {
      try {
        final map = _snapshotsBox.get(key) as Map<dynamic, dynamic>;
        snapshots.add(OddsSnapshot.fromMap(map));
      } catch (_) {/* skip */}
    }
  }
  snapshots.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  return snapshots;
}

static Future<int> clearOldSnapshots({Duration keepFor = const Duration(days: 7)}) async {
  final cutoff = DateTime.now().subtract(keepFor);
  final keysToDelete = <dynamic>[];
  for (final key in _snapshotsBox.keys) {
    try {
      final map = _snapshotsBox.get(key) as Map<dynamic, dynamic>;
      final snapshot = OddsSnapshot.fromMap(map);
      if (snapshot.capturedAt.isBefore(cutoff)) keysToDelete.add(key);
    } catch (_) { keysToDelete.add(key); }
  }
  for (final k in keysToDelete) { await _snapshotsBox.delete(k); }
  return keysToDelete.length;
}

// Watched matches
static Set<String> getWatchedMatchIds() =>
    (_box.get(_watchedMatchIdsField) as List<dynamic>?)?.cast<String>().toSet() ?? {};
static Future<void> saveWatchedMatchIds(Set<String> ids) =>
    _box.put(_watchedMatchIdsField, ids.toList());
```

**`lib/models/matches_provider.dart`** — dodaj watched + snapshot logic:

```dart
Set<String> _watchedMatchIds = {};

// in constructor, after other init:
_watchedMatchIds = StorageService.getWatchedMatchIds();

// Getters
Set<String> get watchedMatchIds => Set.unmodifiable(_watchedMatchIds);
bool isWatched(String matchId) => _watchedMatchIds.contains(matchId);

// Methods
Future<void> toggleWatched(String matchId) async {
  if (_watchedMatchIds.contains(matchId)) {
    _watchedMatchIds.remove(matchId);
  } else {
    _watchedMatchIds.add(matchId);
  }
  await StorageService.saveWatchedMatchIds(_watchedMatchIds);
  notifyListeners();
}

/// Called after fetchMatches — saves snapshots for watched matches.
Future<void> _captureSnapshotsForWatched() async {
  for (final match in _allMatches) {
    if (!_watchedMatchIds.contains(match.id)) continue;
    final h2h = match.h2h;
    if (h2h == null) continue;
    
    final snapshot = OddsSnapshot(
      matchId: match.id,
      capturedAt: DateTime.now(),
      home: h2h.home,
      draw: h2h.draw,
      away: h2h.away,
      bookmaker: h2h.bookmaker,
    );
    await StorageService.saveSnapshot(snapshot);
  }
}
```

U postojećoj `fetchMatches()` metodi, NAKON što se `_allMatches` popuni iz API-ja i PRIJE `notifyListeners()`, pozovi `await _captureSnapshotsForWatched();`

Dodaj novi getter:
```dart
OddsDrift? driftForMatch(String matchId) {
  final snapshots = StorageService.getSnapshotsForMatch(matchId);
  if (snapshots.length < 2) return null;
  return OddsDrift.compute(snapshots.first, snapshots.last);
}
```

**`lib/widgets/match_card.dart`** — dodaj star toggle + drift indicator:

1. U header Row, **pored kickoff countdown-a** (desni kraj), dodaj `IconButton(icon: star_border/star, onPressed: () => provider.toggleWatched(match.id))`. Koristi AnimatedSwitcher 250ms na star swap.

2. Ispod OddsWidget-a (donji rub karte), ako `provider.driftForMatch(match.id)?.hasSignificantMove == true`, dodaj mali Row:
   - Icon `Icons.trending_down` ili `Icons.trending_up` (ovisi o smjeru dominantnog drift-a)
   - Text: "${drift.dominantDrift.side} ${drift.dominantDrift.percent > 0 ? '+' : ''}${drift.dominantDrift.percent.toStringAsFixed(1)}%"
   - Boja: crvena za pad (-%), plava za rast (+%)

Ovo daje korisniku vizualni signal sharp money movement-a.

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter test` → 2/2 passed (testovi iz S3 moraju raditi — dodaj box `tipster_signals` i `odds_snapshots` u setUpAll)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan

---

## FINALNA VERIFIKACIJA SESIJE 4

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed (provjeri da widget_test.dart ima sve Hive boxove u setUpAll)
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v1.3.0.apk` (očekivano ~145 MB)
- Verzija: `1.3.0+4`
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 3 sekcije, dodaj:

```markdown
---
---

## Session 4: YYYY-MM-DD — Telegram Tipster Monitor + Odds Snapshot Engine

**Kontekst:** S1–S3 izgradili closed loop (Matches → Analyze → Log Bet → Settle → P&L). S4 uvodi prve vanjske intelligence kanale: Telegram tipster monitor (pasivni čitač kanala gdje je bot član) i Odds Snapshot Engine (watched matches + drift detection).

---

### Task 1 — TipsterSignal Model + TelegramMonitor Service + Hive Box
[detalji]

### Task 2 — TelegramProvider + Main Lifecycle
[detalji]

### Task 3 — Telegram Settings Section
[detalji]

### Task 4 — Signal UI u Analysis Screen + Context Injection
[detalji]

### Task 5 — BONUS: Odds Snapshot Engine
[detalji]

---

### Finalna verifikacija Session 4:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.0.apk
- Verzija: 1.3.0+4
- Git: Claude Code NE commita/pusha — developer preuzima
```

**Identified Issues** — ako su dodane nove, dodaj ih u postojeću sekciju. Telegram Bot API ograničenje iz Taska 1 je već trebalo biti dodano.

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 5
- Novih Dart fajlova: 5 (tipster_signal.dart, telegram_monitor.dart, telegram_provider.dart, odds_snapshot.dart, + ev. helper widgeti)
- Ažuriranih Dart fajlova: [broj]
- Ukupno Dart fajlova u lib/: [novi total, očekivano ~33-35]
- Flutter analyze: 0 issues
- Flutter test: [N]/[N] passed
- Builds: Windows ✓, Android APK ✓ (betsight-v1.3.0.apk)
- Identified Issues: Telegram Bot API ograničenje (poznato, dokumentirano)
- Sljedeći predloženi korak: **Developer commit-a i push-a S4 na GitHub.** Poslije testira na Android-u: (1) kreira test bot preko @BotFather, (2) dodaje bot u vlastiti test kanal, (3) u Settings unosi bot token + dodaje test kanal, (4) pošalje poruku u test kanal koja sadrži relevance keyword → signal se treba pojaviti u Analysis signal banner-u. Za Odds Snapshot: (1) otvori Matches, (2) star-a jedan meč, (3) pull-to-refresh → provjeri da se snapshot bilježi, (4) nakon ≥2 refresha s različitim kvotama, drift indicator se pojavi na MatchCard-u. Nakon potvrde, planira se **SESSION 5**: analogno CoinSight S5 — **API rate limit hardening + Odds API cache layer** (Hive-based cache s TTL, background refresh throttling, rate limit tracking).

Kraj SESSION 4.
