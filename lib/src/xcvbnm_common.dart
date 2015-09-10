library xcvbnm.common;

abstract class Match {
  Map toMap() {
    Map map = new Map();
    return map;
  }
}

class Result {
  // password
  String password;

  // bits
  num entropy;

  // estimation of actual crack time, in seconds.
  num crackTime;

  // same crack time, as a friendlier string:
  // "instant", "6 minutes", "centuries", etc.
  String crackTimeDisplay;

  // [0,1,2,3,4] if crack time is less than
  // [10**2, 10**4, 10**6, 10**8, Infinity].
  // (useful for implementing a strength bar.)
  int score;

  // how long it took xcvbnm to calculate an answer,
  // in milliseconds.
  int calcTime;

  // match sequence
  List<Match> matchSequence;

  // for debugging
  Map toMap() {
    Map map = new Map();
    map["password"] = password;
    if (entropy != null) {
      map["entropy"] = entropy;
    }
    if (crackTime != null) {
      map["crack_time"] = crackTime;
    }
    if (crackTimeDisplay != null) {
      map["crack_time_display"] = crackTimeDisplay;
    }
    if (score != null) {
      map["score"] = score;
    }
    if (calcTime != null) {
      map["cacl_time"] = new Duration(milliseconds: calcTime);
    }
    if (matchSequence != null && matchSequence.isNotEmpty) {
      List lst = [];
      map["match_equence"] = lst;
      for (Match match in matchSequence) {
        lst.add(match.toMap());
      }
    }
    return map;
  }
}

abstract class Xcvbnm {
  Result estimate(String password, {List<String> userInputs});
}
