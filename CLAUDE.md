Ako Claude Code primijeti bug ili dvojbu koja nije dio zadatka koji rješava, dodaje je pod sekciju Identified Issues u WORKLOG.md ali je ne popravlja bez pitanja.

## Redoslijed implementacije

Implementacija ide fazno i svaka faza mora biti funkcionalna prije prelaska na sljedeću. Faza 1 je scaffold projekta, pubspec.yaml s dependencies, osnovna navigacija i tamna tema (primary #6C63FF, secondary #03DAC6, surface #1E1E1E, card #252525). Faza 2 je The Odds API integracija i Matches screen s MatchCard widgetom i stvarnim kvotama za nogomet (EPL + Champions League), košarku (NBA) i tenis (ATP), uz apstraktni Match model koji pokriva sva tri sporta. Faza 3 je Anthropic integracija, ClaudeService i Analysis chat screen s osnovnim chat UI-jem i injection konteksta odabranih mečeva. Faza 4 je Hive logging i Settings screen za unos dva API ključa (Anthropic i The Odds API). Faza 5 je polish — error handling, loading states i UX detalji.

Claude Code prolazi sve faze autonomno, bez čekanja developerove potvrde. Nakon svake faze pokreće `flutter analyze` (mora biti 0 issues) i `flutter build windows`, te piše WORKLOG unos s popisom Kreirani / Ažurirani fajlovi i Verifikacija.

Unutar faze redoslijed je: pubspec dependencies → model → service → provider → widget → screen.

Nakon Faze 5 Claude Code radi Post-Phase: audit svih lib/ fajlova, cleanup nekorištenih dependency-ja, LICENSE (proprietary), README.md, ažuriranje WORKLOG-a, .gitignore, windows/runner/Runner.rc (BetSight branding), osnovni widget testovi s Hive temp directory init, git init, initial commit.
