import 'package:betsight/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sport enum', () {
    test('has 3 values: soccer, basketball, tennis', () {
      expect(Sport.values, hasLength(3));
      expect(Sport.values, containsAll([Sport.soccer, Sport.basketball, Sport.tennis]));
    });
  });

  group('SportMeta.display', () {
    test('soccer → "Soccer"', () => expect(Sport.soccer.display, 'Soccer'));
    test('basketball → "Basketball"', () => expect(Sport.basketball.display, 'Basketball'));
    test('tennis → "Tennis"', () => expect(Sport.tennis.display, 'Tennis'));
  });

  group('SportMeta.icon', () {
    test('soccer → ⚽', () => expect(Sport.soccer.icon, '⚽'));
    test('basketball → 🏀', () => expect(Sport.basketball.icon, '🏀'));
    test('tennis → 🎾', () => expect(Sport.tennis.icon, '🎾'));
  });

  group('SportMeta.hasDraw', () {
    test('only soccer supports draw', () {
      expect(Sport.soccer.hasDraw, isTrue);
      expect(Sport.basketball.hasDraw, isFalse);
      expect(Sport.tennis.hasDraw, isFalse);
    });
  });

  group('SportMeta.defaultSportKeys', () {
    test('soccer has EPL and Champions League', () {
      expect(Sport.soccer.defaultSportKeys, ['soccer_epl', 'soccer_uefa_champs_league']);
    });
    test('basketball has NBA', () {
      expect(Sport.basketball.defaultSportKeys, ['basketball_nba']);
    });
    test('tennis has ATP singles', () {
      expect(Sport.tennis.defaultSportKeys, ['tennis_atp_singles']);
    });
  });

  group('SportMeta.fromSportKey', () {
    test('soccer_epl → Sport.soccer', () {
      expect(SportMeta.fromSportKey('soccer_epl'), Sport.soccer);
    });
    test('soccer_uefa_champs_league → Sport.soccer', () {
      expect(SportMeta.fromSportKey('soccer_uefa_champs_league'), Sport.soccer);
    });
    test('basketball_nba → Sport.basketball', () {
      expect(SportMeta.fromSportKey('basketball_nba'), Sport.basketball);
    });
    test('tennis_atp_singles → Sport.tennis', () {
      expect(SportMeta.fromSportKey('tennis_atp_singles'), Sport.tennis);
    });
    test('unknown key → null', () {
      expect(SportMeta.fromSportKey('unknown_foo'), isNull);
      expect(SportMeta.fromSportKey(''), isNull);
    });
  });
}
