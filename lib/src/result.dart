library xcvbnm.result;

import 'scoring.dart' as scoring;

/// [Xcvbnm] estimate result
class Result {
  String password;

  /// bits
  num entropy;

  /// estimation of actual crack time, in seconds.
  num crackTime;

  /// same crack time, as a friendlier string:
  /// "instant", "6 minutes", "centuries", etc.
  String crackTimeDisplay;

  /// [0,1,2,3,4] if crack time is less than
  /// [10**2, 10**4, 10**6, 10**8, Infinity].
  /// (useful for implementing a strength bar.)
  int score;

  /// how long it took xcvbnm to calculate an answer,
  /// in milliseconds.
  int calcTime;

  /// the list of patterns that zxcvbn based the
  /// entropy calculation on.
  List<scoring.Match> matchSequence;

  /// for debugging
  Map toJson() {
    Map map = {
      'password': password,
      'entropy': entropy,
      'crack_time': crackTime,
      'crack_time_display': crackTimeDisplay,
      'score': score,
      'calc_time': calcTime,
    };

    for (var key in map.keys.toList()) {
      // Remove null values from map
      if (map[key] == null) map.remove(key);
    }

    if (matchSequence != null && matchSequence.isNotEmpty) {
      List lst = [];
      map['match_equence'] = lst;
      for (scoring.Match match in matchSequence) {
        lst.add(match.toJson());
      }
    }
    return map;
  }
}
