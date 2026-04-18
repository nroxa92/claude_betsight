# BetSight SESSION 5.5 FIX — Prompt Redesign + Trade Action Bar + Bot Manager + Context Enhancements

## UPUTA ZA CLAUDE CODE

**Prije početka pročitaj:**
- `CLAUDE.md` (pravila, autonomni režim, redoslijed unutar faze)
- `WORKLOG.md` (S1–S5 povijest — posebno S2 markers, S3 BetsProvider/BetEntrySheet, S4 Telegram + Odds Snapshot, S5 rate limit i cache)

**Nakon čitanja napiši kratki summary (3–5 rečenica) što ćeš raditi, potom nastavi autonomno kroz svih 5 zadataka bez čekanja na developerovu potvrdu.**

**Nakon svakog zadatka obavezno:**
1. `flutter analyze` — mora biti 0 issues
2. `flutter build windows` — mora proći
3. Dodaj unos u `WORKLOG.md` pod novu sekciju `## Session 5.5 FIX: YYYY-MM-DD — Prompt Redesign + Action Bar + Bot Manager + Context Enhancements`
4. Tek onda prelazi na sljedeći zadatak

**Git:** Claude Code **NE radi git commit ni git push.** Developer preuzima.

**Identified Issues:** Ako naiđeš na nove probleme, zabilježi u postojeću `## Identified Issues` sekciju.

**Verzija:** u Tasku 1 ažuriraj `pubspec.yaml` na `version: 1.3.2+6` (patch bump jer je "fix" sesija iako ambiciozna).

---

## Projektni kontekst

S1–S5 su izgradili stabilan feature set s dobrom infrastrukturom. **Ono što je slabo je *kvaliteta korisničkog iskustva u ključnim dodirnim točkama*:**

- **Prompt je na "S1 razini"** — 28-line generički tekst. Claude često vraća mlake analize bez eksplicitne preporuke kojeg outcome-a kladiti.
- **"Log Bet" button** je dostupan nakon VALUE markera, ali je to jedan usamljen button bez feedback opcija. CoinSight je imao *Trade Action Bar* s tri opcije (BUY NOW / SKIP / TELEGRAM) — SKIP je logirao rejected preporuku za budućnu prompt kalibraciju.
- **Telegram kanali** se sada upisuju kao obični stringovi u listu. Nema pojma koji kanal daje kvalitetne signale, koji šum.
- **Context injection** koristi samo staged matches + staged signals. Ne koristimo **user-ovu bet povijest** (iz S3 BetsProvider-a) ni **odds drift** (iz S4 snapshot engine-a) kao dodatni kontekst.

**S5.5 cilj:** **Dovesti BetSight na CoinSight razinu kvalitete** prije nego Neven pokrene prvi real-world test. Sustigni CoinSight S2 (prompt redesign) + S3 Faza F (Action Bar) + S5 (Bot Manager reliability) u jednoj sesiji.

**Novi Hive boxovi u S5.5:** `monitored_channels_detail` (MonitoredChannel zapisi s reliability scoring-om)
**Novi modeli:** `MonitoredChannel`
**Novi screen:** `BotManagerScreen` (push route, ne IndexedStack tab)

---

## TASK 1 — Prompt Redesign (BetSight S2 level)

**Cilj:** Zamijeniti trenutni generic system prompt s precizno kalibriranim engleskim 40-line promptom strukturiranim po CoinSight S2 uzorku.

### Ažuriraj fajlove

**`pubspec.yaml`** — version bump: `version: 1.3.2+6`

**`lib/models/analysis_provider.dart`** — zamijeni trenutni `_systemPrompt` s:

```dart
static const _systemPrompt = '''
You are BetSight AI, a specialized sports betting intelligence assistant.
You help the user find value bets across soccer, basketball, and tennis by combining match context, real odds, tipster signals, and the user's betting history.

## User profile

The user is an experienced bettor and technical analyst. Do not explain basic concepts (implied probability, bookmaker margin, Asian handicap, spread, over/under) — use them directly. The user pastes match data, odds, and sometimes tipster signals in structured context blocks. Read them carefully before answering.

## Objective 1 — Odds analysis

For every match you analyze:
1. Calculate implied probability for each outcome: `p = 1 / decimal_odds`
2. Sum them — if total > 1.0, the excess is the bookmaker margin (e.g., 1.07 total = 7% margin)
3. Flag if margin > 8% (soft book, worse value across the board)
4. Identify which outcome is most mispriced — this is the candidate for value

If the user provides odds drift data in `[ODDS DRIFT]` block, interpret significant moves (>3%) as smart money signal toward the outcome with falling odds.

## Objective 2 — Match context

Use the user-provided `[SELECTED MATCHES]` block as primary context. If recent form, head-to-head, injuries, or weather data is available (either in the block or from your training knowledge on well-known leagues/teams), incorporate it. For tennis, consider surface and recent rankings. For basketball, consider pace and rest days.

If the user provides `[TIPSTER SIGNALS]` block, treat these as third-party opinions — not facts. Note which channels flagged this match and which outcomes they favored, but do not auto-trust.

If the user provides `[BETTING HISTORY]` block, notice patterns: is this the fifth time the user bets Arsenal this week? Flag potential confirmation bias politely.

## Objective 3 — Recommendation

Every response MUST end with exactly one of these three markers on its own line:

**VALUE** — clear edge detected. You MUST specify:
  - WHICH outcome (Home / Draw / Away / specific player / Over X.X / etc.)
  - At WHICH odds (the current odds from context)
  - Your estimated probability vs implied probability (at least 3 percentage points edge)
  - A concrete next step (e.g., "stake 2% of bankroll", "wait for odds to rise above 2.10")

**WATCH** — interesting spot but edge is marginal, data incomplete, or close to kickoff without confirmation. The user should monitor, not bet yet.

**SKIP** — no edge, fair odds, or too uncertain.

Never combine markers. Never skip the marker. The marker goes on its own line as the last line.

## Constraints

- This is pattern analysis and informational research, not financial advice.
- Never suggest loan-based betting, chasing losses, or increasing stakes after a loss.
- Respect the user's bankroll if provided — suggest stakes as percentage, not absolute amounts.
- If data is genuinely insufficient to form a view, say SKIP with reason — do not fabricate analysis.

## Language

Respond in the language the user uses (English, Croatian, or other). Internal reasoning is always in English for consistency. Sport terminology stays in English even in Croatian responses (e.g., "Asian handicap", "over/under", "moneyline").
''';
```

### Popratne promjene

**`lib/models/analysis_provider.dart`** — `_buildUserMessage` metoda već postoji (iz S4), ali treba proširiti za dva nova bloka koja dolaze u Tasku 5. **Za sada samo prilagodi postojeće blokove da koriste konzistentni engleski format:**

- `[SELECTED MATCHES]` blok — svaki match u jednoj liniji u formatu:
  ```
  {league}: {home} vs {away} | kickoff {ISO time UTC} | odds H/D/A: {h}/{d}/{a} | bookmaker {name}
  ```
  (ako draw ne postoji, samo H/A)

- `[TIPSTER SIGNALS]` blok — koristi postojeći `TipsterSignal.toClaudeContext()` format

### Dokumentacijski artefakt

**Kreiraj `BETLOG.md` u root projekta** (analogno CoinSight CHATLOG.md):

```markdown
# BetSight Analysis Log

This file is for **manual** tracking of Claude VALUE/WATCH/SKIP recommendations and their actual outcomes 24-72h later. Used for long-term prompt calibration.

## Format

| Date | Match | Claude call | My decision | Actual outcome | Notes |
|------|-------|-------------|-------------|----------------|-------|
| 2026-04-20 | Liverpool vs Arsenal | **VALUE** Home @ 1.95 | LOG BET @ 2u | Home won 2-1 | Claude nailed it, sharp book edge |
| 2026-04-20 | Lakers vs Warriors | **SKIP** (margin 11%) | skipped | Warriors won | Good skip, odds were soft |
| ... | ... | ... | ... | ... | ... |

## Calibration notes

Patterns observed over time:
- Claude is [too bullish / well-calibrated / too conservative] on...
- VALUE markers tend to be accurate when...
- SKIP misses happened when...
```

File nije kod — nema flutter analyze impact. Samo se commita u repo.

### Verifikacija Taska 1

- `flutter analyze` → 0 issues (ako prompt ima sintaksnih grešaka u string literalu, triple-quote handling, ispraviti)
- `flutter build windows` → uspješan

---

## TASK 2 — Trade Action Bar (CoinSight S3 Faza F analogija)

**Cilj:** Zamijeniti postojeći usamljeni "Log this as a bet" button s **Action Bar** s tri opcije: LOG BET / SKIP / ASK MORE. SKIP logira rejected feedback za kalibraciju. ASK MORE fokusira input polje s pre-fill tekstom.

### Ažuriraj fajlove

**`lib/models/analysis_log.dart`** — proširi AnalysisLog s user feedback poljem:

```dart
enum UserFeedback { none, logged, skipped, askedMore }

// Dodaj u AnalysisLog klasu:
final UserFeedback userFeedback;
final DateTime? feedbackAt;

// Ažuriraj constructor, toMap/fromMap, copyWith
```

**`lib/services/storage_service.dart`** — dodaj metodu `updateAnalysisLogFeedback`:

```dart
static Future<void> updateAnalysisLogFeedback(String logId, UserFeedback feedback) async {
  final map = _logsBox.get(logId) as Map<dynamic, dynamic>?;
  if (map == null) return;
  final log = AnalysisLog.fromMap(map);
  final updated = log.copyWith(userFeedback: feedback, feedbackAt: DateTime.now());
  await saveAnalysisLog(updated);
}

// Nove query metode za prompt kalibraciju u budućnosti
static List<AnalysisLog> getLogsByRecommendation(RecommendationType type) {
  return getAllAnalysisLogs().where((l) => l.recommendationType == type).toList();
}

static Map<RecommendationType, Map<UserFeedback, int>> getFeedbackStats() {
  final stats = <RecommendationType, Map<UserFeedback, int>>{};
  for (final log in getAllAnalysisLogs()) {
    stats.putIfAbsent(log.recommendationType, () => {});
    stats[log.recommendationType]!.update(
      log.userFeedback,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
  }
  return stats;
}
```

**`lib/models/analysis_provider.dart`** — zadrži trenutno spremanje AnalysisLog-a iz S3, ali pri spremanju zapamti `lastLogId` kako bi Action Bar mogao update-ati feedback:

```dart
String? _lastLogId;
String? get lastLogId => _lastLogId;

// U postojećoj sendMessage metodi, nakon uspjeha, zapamti ID:
final log = AnalysisLog(
  id: generateUuid(),
  // ... ostala polja
  userFeedback: UserFeedback.none,
);
_lastLogId = log.id;
await StorageService.saveAnalysisLog(log);
```

Dodaj metode:
```dart
Future<void> recordFeedback(String logId, UserFeedback feedback) async {
  await StorageService.updateAnalysisLogFeedback(logId, feedback);
  // No notifyListeners needed — UI doesn't rebuild on this
}
```

**`lib/widgets/trade_action_bar.dart`** (NOVI FAJL):

```dart
/// Pojavljuje se ispod assistant ChatBubble-a kada response sadrži **VALUE** marker.
/// Nudi tri akcije: LOG BET (primary), SKIP (outlined), ASK MORE (outlined).
class TradeActionBar extends StatelessWidget {
  final String logId;
  final String assistantResponse;
  final Match? stagedMatch; // first staged match if any, used for prefill
  
  const TradeActionBar({
    super.key,
    required this.logId,
    required this.assistantResponse,
    this.stagedMatch,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: AppTheme.green),
              const SizedBox(width: 6),
              Text(
                'VALUE signal detected',
                style: TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logBet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('LOG BET'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _skip(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('SKIP'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _askMore(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('ASK MORE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _logBet(BuildContext context) {
    context.read<AnalysisProvider>().recordFeedback(logId, UserFeedback.logged);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BetEntrySheet(prefilledMatch: stagedMatch),
    );
  }
  
  void _skip(BuildContext context) {
    context.read<AnalysisProvider>().recordFeedback(logId, UserFeedback.skipped);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recommendation skipped — logged for calibration'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _askMore(BuildContext context) {
    context.read<AnalysisProvider>().recordFeedback(logId, UserFeedback.askedMore);
    // Emit event za Analysis screen da pre-fill-a input s "Why do you think this is value? What's the main risk?"
    // Jednostavan pristup: callback prop ili GlobalKey, ali jednostavnije je koristiti AnalysisProvider kao middleman
    context.read<AnalysisProvider>().setInputPrefill(
      "Why do you think this is value? What's the main risk?",
    );
  }
}
```

**`lib/models/analysis_provider.dart`** — dodaj input prefill polje:

```dart
String? _inputPrefill;
String? get inputPrefill => _inputPrefill;

void setInputPrefill(String text) {
  _inputPrefill = text;
  notifyListeners();
}

void clearInputPrefill() {
  if (_inputPrefill == null) return;
  _inputPrefill = null;
  notifyListeners();
}
```

**`lib/screens/analysis_screen.dart`** — 3 promjene:

1. **Zamijeni postojeći "Log this as a bet" button** (dodan u S3 Task 3) s `TradeActionBar` widgetom kada VALUE marker detektiran:

```dart
itemBuilder: (context, i) {
  final msg = provider.messages[i];
  final isUser = msg.role == 'user';
  final isValueResponse = !isUser && 
      parseRecommendationType(msg.content) == RecommendationType.value;
  
  // Za Action Bar treba lastLogId iz providera — samo za zadnju value response poruku
  final showActionBar = isValueResponse && i == provider.messages.length - 1;
  
  return Column(
    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      ChatBubble(text: msg.content, isUser: isUser),
      if (showActionBar && provider.lastLogId != null)
        TradeActionBar(
          logId: provider.lastLogId!,
          assistantResponse: msg.content,
          stagedMatch: provider.stagedMatches.firstOrNull,
        ),
    ],
  );
},
```

**Važno:** Action Bar se pojavljuje samo ispod **zadnje** assistant poruke, da se ne mnoga action bara ne stekne u povijesti chat-a.

2. **Dodaj Consumer<AnalysisProvider> na inputPrefill** — kad je inputPrefill set-an, setuj TextField:

```dart
// U initState ili didChangeDependencies, listenaj providera:
provider.addListener(_handleProviderChange);

void _handleProviderChange() {
  final prefill = context.read<AnalysisProvider>().inputPrefill;
  if (prefill != null && _textController.text.isEmpty) {
    _textController.text = prefill;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: prefill.length),
    );
    // Request focus na TextField
    _focusNode.requestFocus();
    context.read<AnalysisProvider>().clearInputPrefill();
  }
}
```

(Ako `_focusNode` ne postoji u AnalysisScreen-u, kreirati ga kao `FocusNode()` u initState i dispose-ati u dispose.)

3. **Ukloni postojeći `_buildLogBetButton` helper** — zamijenjen s TradeActionBar.

### Verifikacija Taska 2

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan
- Mock test: u testu možeš stvoriti AnalysisLog s VALUE recommendation, verify-aj da TradeActionBar widget renderira 3 button-a — ako je taj test nezgodan, preskoči (flutter test 2/2 iz postojećih S1-S5 mora i dalje prolaziti)

---

## TASK 3 — MonitoredChannel Model + Reliability Scoring

**Cilj:** Promijeni trenutnu listu `List<String>` u TelegramProvider-u u listu `MonitoredChannel` objekata s per-channel statistikama (signals received, signals relevant, reliability score, label). Tako Bot Manager screen (Task 4) može prikazati koji kanali su korisni, koji šum.

### Kreiraj fajlove

**`lib/models/monitored_channel.dart`:**

```dart
class MonitoredChannel {
  final String username;           // e.g., "@tipsmaster"
  final String? title;              // display name once known (populated from first signal)
  final int signalsReceived;        // total messages received (including irrelevant)
  final int signalsRelevant;        // passed relevance keyword filter
  final DateTime addedAt;
  final DateTime? lastSignalAt;
  final DateTime? lastRelevantAt;
  
  const MonitoredChannel({
    required this.username,
    this.title,
    this.signalsReceived = 0,
    this.signalsRelevant = 0,
    required this.addedAt,
    this.lastSignalAt,
    this.lastRelevantAt,
  });
  
  /// -1 = insufficient data (< 10 signals), else ratio
  double get reliabilityScore {
    if (signalsReceived < 10) return -1;
    return signalsRelevant / signalsReceived;
  }
  
  /// Labela za UI: Novo / Niska / Srednja / Visoka (mirrors CoinSight pattern)
  String get reliabilityLabel {
    final score = reliabilityScore;
    if (score < 0) return 'Novo';      // less than 10 signals
    if (score < 0.1) return 'Niska';
    if (score < 0.3) return 'Srednja';
    return 'Visoka';
  }
  
  /// Color mapping za UI badge
  /// Returns int (color value), consumer wraps in Color(value)
  int get reliabilityColorValue {
    final score = reliabilityScore;
    if (score < 0) return 0xFF9E9E9E;   // grey (Novo)
    if (score < 0.1) return 0xFFEF5350; // red (Niska)
    if (score < 0.3) return 0xFFFFA726; // orange (Srednja)
    return 0xFF4CAF50;                   // green (Visoka)
  }
  
  /// Relativni time prikaz zadnjeg relevantnog signala
  String get lastRelevantDisplay {
    if (lastRelevantAt == null) return 'Never';
    final diff = DateTime.now().difference(lastRelevantAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  
  MonitoredChannel copyWith({
    String? title,
    int? signalsReceived,
    int? signalsRelevant,
    DateTime? lastSignalAt,
    DateTime? lastRelevantAt,
  }) {
    return MonitoredChannel(
      username: username,
      title: title ?? this.title,
      signalsReceived: signalsReceived ?? this.signalsReceived,
      signalsRelevant: signalsRelevant ?? this.signalsRelevant,
      addedAt: addedAt,
      lastSignalAt: lastSignalAt ?? this.lastSignalAt,
      lastRelevantAt: lastRelevantAt ?? this.lastRelevantAt,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'username': username,
    'title': title,
    'signalsReceived': signalsReceived,
    'signalsRelevant': signalsRelevant,
    'addedAt': addedAt.toIso8601String(),
    'lastSignalAt': lastSignalAt?.toIso8601String(),
    'lastRelevantAt': lastRelevantAt?.toIso8601String(),
  };
  
  factory MonitoredChannel.fromMap(Map<dynamic, dynamic> map) => MonitoredChannel(
    username: map['username'] as String,
    title: map['title'] as String?,
    signalsReceived: (map['signalsReceived'] as int?) ?? 0,
    signalsRelevant: (map['signalsRelevant'] as int?) ?? 0,
    addedAt: DateTime.parse(map['addedAt'] as String),
    lastSignalAt: map['lastSignalAt'] == null ? null : DateTime.parse(map['lastSignalAt'] as String),
    lastRelevantAt: map['lastRelevantAt'] == null ? null : DateTime.parse(map['lastRelevantAt'] as String),
  );
}
```

### Ažuriraj fajlove

**`lib/services/storage_service.dart`** — dodaj novi Hive box i CRUD:

```dart
static const _channelsDetailBox = 'monitored_channels_detail';

// U init():
await Hive.openBox(_channelsDetailBox);

static Box get _channelsBox => Hive.box(_channelsDetailBox);

static List<MonitoredChannel> getAllMonitoredChannels() {
  final list = <MonitoredChannel>[];
  for (final map in _channelsBox.values) {
    try {
      list.add(MonitoredChannel.fromMap(map as Map<dynamic, dynamic>));
    } catch (_) {/* skip */}
  }
  list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
  return list;
}

static Future<void> saveMonitoredChannel(MonitoredChannel channel) =>
    _channelsBox.put(channel.username, channel.toMap());

static Future<void> deleteMonitoredChannel(String username) =>
    _channelsBox.delete(username);

// Migration helper — će biti pozvan jednom iz TelegramProvider konstruktora
static Future<void> migrateMonitoredChannels() async {
  // Stari format: List<String> na _monitoredChannelsField u settings boxu
  // Novi: MonitoredChannel objekti u _channelsDetailBox
  final oldList = getMonitoredChannels();
  if (oldList.isEmpty) return;
  if (_channelsBox.isNotEmpty) return; // već migrirano
  
  final now = DateTime.now();
  for (final username in oldList) {
    final channel = MonitoredChannel(
      username: username,
      addedAt: now,
    );
    await saveMonitoredChannel(channel);
  }
  // Ne brišemo stari list (legacy kompatibilnost) — može čišćenje kasnije
}
```

**`lib/models/telegram_provider.dart`** — refactor da koristi MonitoredChannel:

```dart
List<MonitoredChannel> _channels = [];

// U konstruktoru, nakon učitavanja signala:
await StorageService.migrateMonitoredChannels();
_channels = StorageService.getAllMonitoredChannels();

// Zamijeni postojeću `_monitoredChannels` list<String> s novim getterom
List<MonitoredChannel> get channels => List.unmodifiable(_channels);
List<String> get channelUsernames => _channels.map((c) => c.username).toList();

// Ažurirane metode:
Future<void> addChannel(String username) async {
  final clean = username.trim();
  if (clean.isEmpty || _channels.any((c) => c.username == clean)) return;
  
  final channel = MonitoredChannel(username: clean, addedAt: DateTime.now());
  _channels = [..._channels, channel];
  await StorageService.saveMonitoredChannel(channel);
  notifyListeners();
}

Future<void> removeChannel(String username) async {
  _channels = _channels.where((c) => c.username != username).toList();
  await StorageService.deleteMonitoredChannel(username);
  notifyListeners();
}

// U _handleNewSignal — inkrementiraj counter-e na channel objektu:
void _handleNewSignal(TipsterSignal signal) {
  // Dedup:
  final exists = _signals.any((s) =>
      s.telegramMessageId == signal.telegramMessageId &&
      s.channelUsername == signal.channelUsername);
  if (exists) return;
  
  // Update channel stats — uvijek, čak i ako nije u monitored list-i (signal ne prolazi filter)
  final idx = _channels.indexWhere((c) => c.username == signal.channelUsername);
  if (idx != -1) {
    final old = _channels[idx];
    final updated = old.copyWith(
      title: old.title ?? signal.channelTitle,
      signalsReceived: old.signalsReceived + 1,
      signalsRelevant: old.signalsRelevant + (signal.isRelevant ? 1 : 0),
      lastSignalAt: DateTime.now(),
      lastRelevantAt: signal.isRelevant ? DateTime.now() : old.lastRelevantAt,
    );
    _channels[idx] = updated;
    StorageService.saveMonitoredChannel(updated);
  }
  
  // Filter: skip save ako kanal nije monitored (ali stats su već ažurirane ako je bio)
  if (_channels.isNotEmpty && idx == -1) return;
  
  // Filter: preskoči ako signal nije relevant
  if (!signal.isRelevant) return;
  
  _signals = [signal, ..._signals];
  StorageService.saveSignal(signal);
  notifyListeners();
}
```

**Važno:** Trenutno TelegramMonitor samo pozove callback kad je signal RELEVANT. Sad moraju se pozivati callback-i **i za irrelevant signals** kako bi se ažurirale statistike. To znači da TelegramMonitor._parseUpdate treba vraćati signal i kad nije relevant (s isRelevant=false), ne null.

**`lib/services/telegram_monitor.dart`** — update `_parseUpdate`:

```dart
// U _parseUpdate, umjesto:
//   if (!isRelevant) return null; // skip noise
// uvijek vrati TipsterSignal s isRelevant flagom:

final isRelevant = _relevanceKeywords.any((kw) => lowerText.contains(kw));
// ... sport detection kao prije

return TipsterSignal(
  id: generateUuid(),
  telegramMessageId: messageId,
  channelUsername: '@$username',
  channelTitle: title,
  text: text.trim(),
  receivedAt: DateTime.now(),
  detectedSport: detectedSport,
  detectedLeague: detectedLeague,
  isRelevant: isRelevant,  // false se sada vraća umjesto null
);
```

### Verifikacija Taska 3

- `flutter analyze` → 0 issues
- `flutter test` → 2/2 passed (setUpAll proširiti s `monitored_channels_detail` boxom)
- `flutter build windows` → uspješan

---

## TASK 4 — Bot Manager Screen

**Cilj:** Zasebni screen (push route iz Settings, ne IndexedStack tab) za upravljanje Telegram kanalima s reliability scoring-om. Lista kanala s badge-ovima, per-channel statistike, dodavanje/brisanje.

### Kreiraj fajlove

**`lib/screens/bot_manager_screen.dart`:**

```dart
class BotManagerScreen extends StatefulWidget {
  const BotManagerScreen({super.key});
  
  @override
  State<BotManagerScreen> createState() => _BotManagerScreenState();
}

class _BotManagerScreenState extends State<BotManagerScreen> {
  final _newChannelController = TextEditingController();
  
  @override
  void dispose() {
    _newChannelController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Manager'),
      ),
      body: Consumer<TelegramProvider>(
        builder: (context, provider, _) {
          final channels = provider.channels;
          
          return Column(
            children: [
              // Top stats header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('Channels', channels.length.toString()),
                    _statTile('Total signals',
                        channels.fold<int>(0, (sum, c) => sum + c.signalsReceived).toString()),
                    _statTile('Relevant',
                        channels.fold<int>(0, (sum, c) => sum + c.signalsRelevant).toString()),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Add channel input
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newChannelController,
                        decoration: const InputDecoration(
                          labelText: 'Add channel (e.g., @tipsmaster)',
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                        onSubmitted: (_) => _addChannel(provider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _addChannel(provider),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              
              // Channels list
              Expanded(
                child: channels.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (_, i) => _ChannelCard(
                          channel: channels[i],
                          onDelete: () => _confirmDelete(provider, channels[i].username),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.podcasts, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text('No channels yet', style: TextStyle(color: Colors.grey[400])),
          Text('Add a channel to start monitoring',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
  
  Future<void> _addChannel(TelegramProvider provider) async {
    var text = _newChannelController.text.trim();
    if (text.isEmpty) return;
    if (!text.startsWith('@')) text = '@$text';
    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel username too short')),
      );
      return;
    }
    await provider.addChannel(text);
    _newChannelController.clear();
  }
  
  Future<void> _confirmDelete(TelegramProvider provider, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove channel?'),
        content: Text('Remove $username? Stats for this channel will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.removeChannel(username);
    }
  }
}

class _ChannelCard extends StatelessWidget {
  final MonitoredChannel channel;
  final VoidCallback onDelete;
  
  const _ChannelCard({required this.channel, required this.onDelete});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.title ?? channel.username,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (channel.title != null)
                        Text(
                          channel.username,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                _ReliabilityBadge(channel: channel),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metaChip('${channel.signalsReceived} received'),
                const SizedBox(width: 6),
                _metaChip('${channel.signalsRelevant} relevant'),
                const SizedBox(width: 6),
                _metaChip('Last: ${channel.lastRelevantDisplay}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _ReliabilityBadge extends StatelessWidget {
  final MonitoredChannel channel;
  const _ReliabilityBadge({required this.channel});
  
  @override
  Widget build(BuildContext context) {
    final color = Color(channel.reliabilityColorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        channel.reliabilityLabel,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
```

### Ažuriraj fajlove

**`lib/screens/settings_screen.dart`** — u `_TelegramSection`, zamijeni postojeći channel management (chip list + TextField) s **jednim "Manage Channels" buttonom** koji push-a BotManagerScreen:

```dart
// U _TelegramSection build metodi, umjesto Wrap chipa + TextField + Add button:
OutlinedButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BotManagerScreen()),
    );
  },
  icon: const Icon(Icons.tune),
  label: Text('Manage Channels (${provider.channels.length})'),
),
```

Ako postoji `provider.monitoredChannels` referenca (getter koji vraća `List<String>` iz starog API-ja), ažuriraj ili preskoči (refactoring u Tasku 3 je to eliminirao).

### Verifikacija Taska 4

- `flutter analyze` → 0 issues
- `flutter build windows` → uspješan

---

## TASK 5 — Context Injection Enhancements

**Cilj:** Dodaj dva nova opcionalna bloka u Claude user message kad su relevantni: `[BETTING HISTORY]` (zadnjih 5 user-ovih bet-ova iz BetsProvider-a) i `[ODDS DRIFT]` (drift podaci za staged matches koji su watched).

### Ažuriraj fajlove

**`lib/models/analysis_provider.dart`** — proširi `_buildUserMessage`:

```dart
String _buildUserMessage(
  String text, {
  List<Match>? contextMatches,
  List<TipsterSignal>? contextSignals,
  List<Bet>? bettingHistory,      // NOVO
  Map<String, OddsDrift>? driftByMatchId,  // NOVO, key = match.id
}) {
  final buf = StringBuffer();
  
  if (contextMatches != null && contextMatches.isNotEmpty) {
    buf.writeln('[SELECTED MATCHES]');
    for (final m in contextMatches) {
      final h2h = m.h2h;
      final oddsStr = h2h == null
          ? 'odds unavailable'
          : h2h.draw == null
              ? 'odds H/A: ${h2h.home}/${h2h.away}'
              : 'odds H/D/A: ${h2h.home}/${h2h.draw}/${h2h.away}';
      final bookmaker = h2h?.bookmaker ?? 'unknown';
      buf.writeln('${m.league}: ${m.home} vs ${m.away} | '
          'kickoff ${m.commenceTime.toIso8601String()} | '
          '$oddsStr | bookmaker $bookmaker');
      
      // ODDS DRIFT per match
      if (driftByMatchId != null && driftByMatchId.containsKey(m.id)) {
        final drift = driftByMatchId[m.id]!;
        if (drift.hasSignificantMove) {
          final dom = drift.dominantDrift;
          buf.writeln('  [drift] ${dom.side} '
              '${dom.percent > 0 ? '+' : ''}${dom.percent.toStringAsFixed(1)}% '
              'since last snapshot');
        }
      }
    }
    buf.writeln('[/SELECTED MATCHES]');
    buf.writeln();
  }
  
  if (contextSignals != null && contextSignals.isNotEmpty) {
    buf.writeln('[TIPSTER SIGNALS]');
    for (final s in contextSignals) {
      buf.writeln(s.toClaudeContext());
    }
    buf.writeln('[/TIPSTER SIGNALS]');
    buf.writeln();
  }
  
  if (bettingHistory != null && bettingHistory.isNotEmpty) {
    buf.writeln('[BETTING HISTORY — last ${bettingHistory.length} bets]');
    for (final bet in bettingHistory) {
      final outcome = bet.actualProfit;
      final outcomeStr = outcome == null
          ? 'pending'
          : outcome > 0
              ? 'won +${outcome.toStringAsFixed(2)}'
              : outcome < 0
                  ? 'lost ${outcome.toStringAsFixed(2)}'
                  : 'void';
      buf.writeln('${bet.placedAt.toIso8601String().substring(0, 10)} | '
          '${bet.sport.display} | ${bet.home} vs ${bet.away} | '
          '${bet.selection.display} @ ${bet.odds.toStringAsFixed(2)} | '
          'stake ${bet.stake} | $outcomeStr');
    }
    buf.writeln('[/BETTING HISTORY]');
    buf.writeln();
  }
  
  buf.write(text);
  return buf.toString();
}
```

**`lib/models/analysis_provider.dart`** — u `sendMessage`, gather additional context:

```dart
Future<void> sendMessage(
  String text, {
  List<Match>? contextMatches,
  List<TipsterSignal>? contextSignals,
}) async {
  // ... existing code ...
  
  // Gather betting history: last 5 bets (settled + pending) sorted by placedAt desc
  final betsProvider = // HOW TO ACCESS? — see note below
  List<Bet>? history;
  try {
    // AnalysisProvider nema direct access to BetsProvider.
    // Dva pristupa: (a) dependency injection u constructor, (b) static accessor.
    // Pristup (b) je jednostavniji ovdje — dodaj u main.dart init:
    //   BetsProvider.setInstance(betsProviderInstance);
    // Ovdje koristi BetsProvider.instance().allBets.
    // DEFAULT ako je kompliciranije: čita direktno iz Storage.
    history = StorageService.getAllBets()
        .where((b) => true) // svi
        .toList()
      ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    history = history.take(5).toList();
    if (history.isEmpty) history = null;
  } catch (_) {
    history = null;
  }
  
  // Gather odds drift for staged/selected matches
  final effectiveMatches = contextMatches ?? (_stagedMatches.isNotEmpty ? _stagedMatches : null);
  Map<String, OddsDrift>? drifts;
  if (effectiveMatches != null) {
    drifts = {};
    for (final m in effectiveMatches) {
      final snapshots = StorageService.getSnapshotsForMatch(m.id);
      if (snapshots.length >= 2) {
        drifts[m.id] = OddsDrift.compute(snapshots.first, snapshots.last);
      }
    }
    if (drifts.isEmpty) drifts = null;
  }
  
  final userContent = _buildUserMessage(
    text,
    contextMatches: effectiveMatches,
    contextSignals: effectiveSignals,
    bettingHistory: history,
    driftByMatchId: drifts,
  );
  
  // ... rest of send logic
}
```

**Napomena:** Pristup BetsProvider-u iz AnalysisProvider-a može se riješiti kroz `StorageService.getAllBets()` direktno — tako AnalysisProvider ostaje decoupled od BetsProvider-a. To je čišće i radi za ovaj use case.

### Verifikacija Taska 5

- `flutter analyze` → 0 issues
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan

---

## FINALNA VERIFIKACIJA SESIJE 5.5

- `flutter analyze` → **0 issues**
- `flutter test` → 2/2 passed
- `flutter build windows` → uspješan
- `flutter build apk --debug` → uspješan
- APK u root: `betsight-v1.3.2.apk`
- Verzija: `1.3.2+6`
- Git: Claude Code **NE commita/pusha** — developer preuzima

---

## FINALNI WORKLOG UNOS

Na kraju `WORKLOG.md`-a, nakon postojeće Session 5 sekcije, dodaj:

```markdown
---
---

## Session 5.5 FIX: YYYY-MM-DD — Prompt Redesign + Trade Action Bar + Bot Manager + Context Enhancements

**Kontekst:** S1–S5 izgradili stabilan feature set sa solidnom infrastrukturom, ali kvaliteta UX-a u ključnim dodirnim točkama nije bila na CoinSight razini. S5.5 FIX podiže prompt s generic S1-level teksta na strukturirani 40-line engleski (analogno CoinSight S2 + S6), zamjenjuje usamljeni "Log Bet" button s Trade Action Bar-om (CoinSight S3 Faza F), dodaje MonitoredChannel model s reliability scoring-om i zasebni Bot Manager screen (CoinSight S5), te proširuje Claude context s [BETTING HISTORY] i [ODDS DRIFT] blokovima.

---

### Task 1 — Prompt Redesign
[detalji]

### Task 2 — Trade Action Bar
[detalji]

### Task 3 — MonitoredChannel Model + Reliability Scoring
[detalji]

### Task 4 — Bot Manager Screen
[detalji]

### Task 5 — Context Injection Enhancements
[detalji]

---

### Finalna verifikacija Session 5.5:
- flutter analyze — 0 issues
- flutter test — N/N passed
- flutter build windows — uspješan
- flutter build apk --debug — uspješan
- APK u rootu: betsight-v1.3.2.apk
- Verzija: 1.3.2+6
- Git: Claude Code NE commita/pusha — developer preuzima
```

---

## ZAVRŠNA PORUKA RAZVIJATELJU

Napiši sažetak:

- Ukupno zadataka izvršeno: 5
- Novih Dart fajlova: 3 (monitored_channel.dart, bot_manager_screen.dart, trade_action_bar.dart)
- Ažuriranih Dart fajlova: [broj, očekivano ~7-8]
- Ukupno Dart fajlova u lib/: [novi total, očekivano 37]
- Novi MD fajl: BETLOG.md (template za ručno bilježenje ishoda Claude preporuka)
- Flutter analyze: 0 issues
- Flutter test: N/N passed
- Builds: Windows ✓, Android APK ✓ (betsight-v1.3.2.apk)
- Sljedeći predloženi korak: **Developer commit-a i push-a S5.5 na GitHub.** APK je sada na "CoinSight razini kvalitete" — spreman za prvi real-world test na Android-u. Preporuka: instalirati APK, postaviti API keyove, koristiti 2-3 dana aktivnog korištenja, bilježiti u BETLOG.md ishode VALUE/WATCH/SKIP preporuka, potom se vratiti s feedback-om. Nakon real-world testa planira se **SESSION 6 — Multi-Source Intelligence Layer** (analogno CoinSight S6): integracija besplatnih sport data izvora (Football-Data.org, BALLDONTLIE, Reddit) u IntelligenceAggregator s confluence scoring-om, smanjenje ovisnosti o Odds API kvoti.

Kraj SESSION 5.5 FIX.
