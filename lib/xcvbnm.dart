library xcvbnm;

abstract class Match {

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
}

class Xcvbnm {
  int getNaiveScore(String password) {
    if (password.length < 3) return 0;
    if (password.length < 5) return 1;
    if (password.length < 7) return 2;
    if (password.length < 9) return 3;
    if (password.length < 11) return 3;
    return 4;
  }

  Result estimate(String password, {List<String> userInputs}) {
    return new Result()
      ..score = getNaiveScore(password);
  }
}
