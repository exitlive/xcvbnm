part of xcvbnm;

class _Xcvbnm extends Object implements Xcvbnm {
  Result estimate(String password, {List<String> userInputs}) {
    Result result = new Result();
    Stopwatch sw = new Stopwatch();
    sw.start();

    // reset the user inputs matcher on a per-request basis to keep things stateless
    if (userInputs == null) {
      userInputs = [];
    }
    matching.setUserInputDictionary(userInputs);

    List<scoring.Match> matches = matching.omnimatch(password);
    result = scoring.minimumEntropyMatchSequence(password, matches);
    sw.stop();
    result.calcTime = sw.elapsedMilliseconds;
    return result;
  }
}

class _Result extends Object with Result {
  /// for debugging
  Map toJson() {
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
      map["calc_time"] = calcTime;
    }
    if (matchSequence != null && matchSequence.isNotEmpty) {
      List lst = [];
      map["match_equence"] = lst;
      for (Match match in matchSequence) {
        lst.add(match.toJson());
      }
    }
    return map;
  }
}
