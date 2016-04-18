library xcvbnm.scoring;

import 'dart:math' as math;

import 'package:xcvbnm/src/adjacency_graphs.dart';
import 'package:xcvbnm/src/feedback.dart';
import 'package:xcvbnm/src/result.dart';

// single guess time (10ms) over number of cores guessing in parallel
// for a hash function like bcrypt/scrypt/PBKDF2, 10ms per guess is a safe lower bound.
// (usually a guess would take longer -- this assumes fast hardware and a small work factor.)
// adjust for your site accordingly if you use another hash function, possibly by
// several orders of magnitude!
const num _secondsPerGuess = .010 / 100;

const int minYearSpace = 20;
const int referenceYear = 2000;

num nCk(n, k) {
  // http://blog.plover.com/math/choose.html
  var d, r;
  if (k > n) {
    return 0;
  }
  if (k == 0) {
    return 1;
  }
  r = 1;
  for (d = 1; d <= k; d++) {
    r *= n;
    r /= d;
    n -= 1;
  }
  return r;
}

num lg(num n) {
  return math.log(n) / math.log(2);
}

/**
 * threat model -- stolen hash catastrophe scenario
 *
 * passwords are stored as salted hashes, different random salt per user.
 *   (making rainbow attacks infeasable.)
 * hashes and salts were stolen. attacker is guessing passwords at max rate.
 * attacker has several CPUs at their disposal.
 */

num entropyToCrackTime(num entropy) {
  return .5 * math.pow(2, entropy) * _secondsPerGuess; // .5 for average vs total
}

int crackTimeToScore(seconds) {
  if (seconds < math.pow(10, 2)) {
    return 0;
  }
  if (seconds < math.pow(10, 4)) {
    return 1;
  }
  if (seconds < math.pow(10, 6)) {
    return 2;
  }
  if (seconds < math.pow(10, 8)) {
    return 3;
  }
  return 4;
}

int calcBruteforceCardinality(String password) {
  var c, cp;
  bool digits, latin1Letters, latin1Symbols;
  bool lower;
  int maxCp, minCp;
  var range;
  bool symbols, upper;

  List unicodeCodepoints = [];

  for (int ord in password.codeUnits) {
    if ((0x30 <= ord && ord <= 0x39)) {
      digits = true;
    } else if (0x41 <= ord && ord <= 0x5a) {
      upper = true;
    } else if (0x61 <= ord && ord <= 0x7a) {
      lower = true;
    } else if (ord <= 0x7f) {
      symbols = true;
    } else if (0x80 <= ord && ord <= 0xBF) {
      latin1Symbols = true;
    } else if (0xC0 <= ord && ord <= 0xFF) {
      latin1Letters = true;
    } else if (ord > 0xFF) {
      unicodeCodepoints.add(ord);
    }
  }
  c = 0;
  if (digits == true) {
    c += 10;
  }
  if (upper == true) {
    c += 26;
  }
  if (lower == true) {
    c += 26;
  }
  if (symbols == true) {
    c += 33;
  }
  if (latin1Symbols == true) {
    c += 64;
  }
  if (latin1Letters == true) {
    c += 64;
  }
  if (unicodeCodepoints.length > 0) {
    minCp = maxCp = unicodeCodepoints[0];
    for (int i = 0; i < unicodeCodepoints.length; i++) {
      cp = unicodeCodepoints[i];
      if (cp < minCp) {
        minCp = cp;
      }
      if (cp > maxCp) {
        maxCp = cp;
      }
    }
    // if the range between unicode codepoints is small,
    // assume one extra alphabet is in use (eg cyrillic, korean) and add a ballpark +40
    //
    // if the range is large, be very conservative and add +100 instead of the range.
    // (codepoint distance between chinese chars can be many thousand, for example,
    // but that cardinality boost won't be justified if the characters are common.)
    range = maxCp - minCp + 1;
    if (range < 40) {
      range = 40;
    }
    if (range > 100) {
      range = 100;
    }
    c += range;
  }
  return c;
}

String displayTime(num seconds) {
  var century, day, displayNum, displayStr, hour, minute, month, year;
  minute = 60;
  hour = minute * 60;
  day = hour * 24;
  month = day * 31;
  year = month * 12;
  century = year * 100;
  if (seconds < minute) {
    displayNum = seconds;
    displayStr = "${seconds} second";
  } else if (seconds < hour) {
    displayNum = (seconds / minute).round();
    displayStr = "${displayNum} minute";
  } else if (seconds < day) {
    displayNum = (seconds / hour).round();
    displayStr = "${displayNum} hour";
  } else if (seconds < month) {
    displayNum = (seconds / day).round();
    displayStr = "${displayNum} day";
  } else if (seconds < year) {
    displayNum = (seconds / month).round();
    displayStr = "${displayNum} month";
  } else if (seconds < century) {
    displayNum = (seconds / year).round();
    displayStr = "${displayNum} year";
  } else {
    displayStr = 'centuries';
  }
  if ((displayNum != null) && displayNum != 1) {
    displayStr += 's';
  }
  return displayStr;
}

class Match {
  String pattern;

  num entropy;

  Match({this.entropy, this.baseEntropy, this.pattern, this.i, this.j, this.token});

  // repeat/sequence/regex/spatial entropy
  String token;

  // dictionary/repeat
  num baseEntropy;

  // match sequence
  int i;
  int j;

  toJson() {
    Map map = {'pattern': pattern, 'token': token, 'entropy': entropy, 'base_entropy': baseEntropy, 'i': i, 'j': j};
    for (var key in map.keys.toList()) {
      // Remove null values from map
      if (map[key] == null) map.remove(key);
    }
    return map;
  }

  toString() => toJson().toString();
}

class SequenceMatch extends Match {
  SequenceMatch({this.ascending, int i, int j, String token, this.sequenceName, this.sequenceSpace})
      : super(pattern: 'sequence', i: i, j: j, token: token);

  // sequence entropy
  String sequenceName;
  int sequenceSpace;
  bool ascending;

  @override
  toJson() {
    Map map = super.toJson();
    if (sequenceName != null) {
      map["sequence_name"] = sequenceName;
    }
    if (sequenceSpace != null) {
      map["sequence_space"] = sequenceSpace;
    }
    if (ascending != null) {
      map["ascending"] = ascending;
    }
    return map;
  }
}

class RepeatMatch extends Match {
  // repeat
  String baseToken;
  List<Match> baseMatches;

  RepeatMatch({num baseEntropy, this.baseToken, this.baseMatches, int i, int j, String token})
      : super(pattern: 'repeat', i: i, j: j, token: token, baseEntropy: baseEntropy);

  @override
  toJson() {
    Map map = super.toJson();
    if (baseToken != null) {
      map["base_token"] = baseToken;
    }
    if (baseMatches != null) {
      List<Map> list = [];
      for (Match match in baseMatches) {
        list.add(match.toJson());
      }
      map["baseMatches"] = list;
    }
    return map;
  }
}

class SpatialMatch extends Match {
  // spatial
  String graph;
  int shiftedCount;
  int turns;

  SpatialMatch({this.graph, this.shiftedCount, this.turns, int i, int j, String token})
      : super(pattern: 'spatial', i: i, j: j, token: token);

  @override
  toJson() {
    Map map = super.toJson();
    if (graph != null) {
      map["graph"] = graph;
    }
    if (shiftedCount != null) {
      map["shiftedCount"] = shiftedCount;
    }
    if (turns != null) {
      map["turns"] = turns;
    }
    return map;
  }
}

class RegexMatch extends Match {
  // regex
  String regexName;
  List<String> regexMatch;

  RegexMatch({this.regexName, this.regexMatch, int i, int j, String token})
      : super(pattern: 'regex', i: i, j: j, token: token);

  @override
  toJson() {
    Map map = super.toJson();
    if (regexName != null) {
      map["regexName"] = regexName;
    }
    if (regexMatch != null) {
      map["regexMatch"] = regexMatch;
    }
    return map;
  }
}

class DateMatch extends Match {
  // date entropy
  int year;
  int month;
  int day;

  // ?? never used
  bool hasFullYear;
  String separator;

  DateMatch({this.year, this.month, this.day, this.separator, this.hasFullYear, String token, int i, int j})
      : super(pattern: 'date', i: i, j: j, token: token);

  @override
  Map<String, Object> toJson() {
    Map map = super.toJson();
    if (year != null) {
      map['year'] = year;
    }
    if (month != null) {
      map['month'] = month;
    }
    if (day != null) {
      map['day'] = day;
    }
    if (separator != null) {
      map['separator'] = separator;
    }
    return map;
  }
}

/*
 * entropy calcs -- one function per match pattern
 */

typedef num _EntropyFunction(Match match);

num calcEntropy(Match match) {
  if (match.entropy != null) {
    return match.entropy;
  }
  Map<String, _EntropyFunction> entropy_functions = {
    "dictionary": dictionaryEntropy,
    "spatial": spatialEntropy,
    "repeat": repeatEntropy,
    "sequence": sequenceEntropy,
    "regex": regexEntropy,
    "date": dateEntropy
  };
  return match.entropy = entropy_functions[match.pattern](match);
}

num repeatEntropy(RepeatMatch match) {
  num numRepeats = match.token.length / match.baseToken.length;
  return match.baseEntropy + lg(numRepeats);
}

num sequenceEntropy(SequenceMatch match) {
  num baseEntropy;
  String firstChr = match.token[0];
  // lower entropy for obvious starting points
  if (['a', 'A', 'z', 'Z', '0', '1', '9'].contains(firstChr)) {
    baseEntropy = 2;
  } else {
    if (new RegExp(r"\d").hasMatch(firstChr)) {
      baseEntropy = lg(10); // digits
    } else if (new RegExp(r"[a-z]").hasMatch(firstChr)) {
      baseEntropy = lg(26); // lower
    } else {
      baseEntropy = lg(26) + 1; // extra bit for uppercase
    }
  }
  if (!match.ascending) {
    baseEntropy += 1;
  }
  return baseEntropy + lg(match.token.length);
}

num regexEntropy(RegexMatch match) {
  var yearSpace;
  Map charClassBases = {
    "alpha_lower": 26,
    "alpha_upper": 26,
    "alpha": 52,
    "alphanumeric": 62,
    "digits": 10,
    "symbols": 33
  };
  if (charClassBases.containsKey(match.regexName)) {
    return lg(math.pow(charClassBases[match.regexName], match.token.length));
  } else {
    switch (match.regexName) {
      case 'recent_year':
        // conservative estimate of year space: num years from REFERENCE_YEAR.
        // if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
        yearSpace = (int.parse(match.regexMatch[0]) - referenceYear).abs();
        yearSpace = math.max(yearSpace, minYearSpace);
        return lg(yearSpace);
    }
  }
  return null;
}

num dateEntropy(DateMatch match) {
  var entropy, yearSpace;
  // base entropy: lg of (year distance from REFERENCE_YEAR * num_days * num_years)
  yearSpace = math.max((match.year - referenceYear).abs(), minYearSpace);
  entropy = lg(yearSpace * 31 * 12);
  // add one bit for four-digit years
  if (match.hasFullYear == true) {
    entropy += 1;
  }
  // add two bits for separator selection (one of ~4 choices)
  if (match.separator != null && match.separator.length > 0) {
    entropy += 2;
  }
  return entropy;
}

_calcAverageDegree(Map graph) {
  var average, k, key, n, neighbors;
  average = 0;
  for (key in graph.keys) {
    neighbors = graph[key];
    average += ((() {
      var l, len, results;
      results = [];
      len = neighbors.length;
      for (l = 0; l < len; l++) {
        n = neighbors[l];
        if (n != null) {
          results.add(n);
        }
      }
      return results;
    })()).length;
  }
  average /= ((() {
    var results;
    results = [];
    for (k in graph.keys) {
      //v = graph[k];
      results.add(k);
    }
    return results;
  })()).length;
  return average;
}

final num keyboardAverageDegree = _calcAverageDegree(adjacencyGraphs["qwerty"]);
final num keypadAverageDegree = _calcAverageDegree(adjacencyGraphs["keypad"]);
final num keyboardStartingPositions = ((() {
  var ref, results;
  ref = adjacencyGraphs["qwerty"];
  results = [];
  for (var k in ref.keys) {
    //v = ref[k];
    results.add(k);
  }
  return results;
})()).length;
final num keypadStartingPositions = ((() {
  var results;
  Map ref = adjacencyGraphs["keypad"];
  results = [];
  for (var k in ref.keys) {
    //v = ref[k];
    results.add(k);
  }
  return results;
})()).length;

num spatialEntropy(SpatialMatch match) {
  var tokenLength, sc, uc, d, entropy, possibilities, possibleTurns, s, t;
  if (['qwerty', 'dvorak'].contains(match.graph)) {
    s = keyboardStartingPositions;
    d = keyboardAverageDegree;
  } else {
    s = keypadStartingPositions;
    d = keypadAverageDegree;
  }
  possibilities = 0;
  tokenLength = match.token.length;
  t = match.turns;
  for (int i = 2; i <= tokenLength; i++) {
    possibleTurns = math.min(t, i - 1);
    for (int j = 1; j <= possibleTurns; j++) {
      possibilities += nCk(i - 1, j - 1) * s * math.pow(d, j);
    }
  }
  entropy = lg(possibilities);
  // add extra entropy for shifted keys. (% instead of 5, A instead of a.)
  // math is similar to extra entropy of l33t substitutions in dictionary matches.
  if (match.shiftedCount != null && match.shiftedCount > 0) {
    sc = match.shiftedCount;
    uc = match.token.length - match.shiftedCount;
    if (uc == 0) {
      entropy += 1;
    } else {
      possibilities = 0;
      for (int i = 1; i <= math.min(sc, uc); i++) {
        possibilities += nCk(sc + uc, i);
      }
      entropy += lg(possibilities);
    }
  }
  return entropy;
}

class DictionaryMatch extends Match {
  DictionaryMatch({this.matchedWord, this.dictionaryName, this.rank, this.sub, this.l33t, String token})
      : super(pattern: 'dictionary', token: token);

  // dictionary
  bool reversed;
  int rank;
  num uppercaseEntropy;
  num reversedEntropy;
  bool l33t;
  num l33tEntropy;
  Map<String, String> sub;
  String matchedWord;
  String dictionaryName;
  String get subDisplay {
    if (sub == null) {
      return null;
    }
    return sub.toString();
  }

  @override
  toJson() {
    Map map = super.toJson();
    if (reversed != null) {
      map["reversed"] = reversed;
    }
    if (rank != null) {
      map["rank"] = rank;
    }
    if (uppercaseEntropy != null) {
      map["uppercase_entropy"] = uppercaseEntropy;
    }
    if (reversedEntropy != null) {
      map["reversed_entropy"] = reversedEntropy;
    }
    if (l33t != null) {
      map["l33t"] = l33t;
    }
    if (sub != null) {
      map["sub"] = sub;
    }
    if (matchedWord != null) {
      map["matched_word"] = matchedWord;
    }
    if (dictionaryName != null) {
      map["dictionary_name"] = dictionaryName;
    }
    return map;
  }
}

num dictionaryEntropy(DictionaryMatch match) {
  match.baseEntropy = lg(match.rank); // keep these as properties for display purposes
  match.uppercaseEntropy = extraUppercaseEntropy(match);
  match.reversedEntropy = match.reversed == true ? 1 : 0;
  match.l33tEntropy = extraL33tEntropy(match);
  return match.baseEntropy + match.uppercaseEntropy + match.l33tEntropy + match.reversedEntropy;
}

var _startUpperRegExp = new RegExp(r"^[A-Z][^A-Z]+$");
var _endUpperRegExp = new RegExp(r"^[^A-Z]+[A-Z]$");
var _allUpperRegExp = new RegExp(r"^[^a-z]+$");
var _allLowerRegExp = new RegExp(r"^[^A-Z]+$");

num extraUppercaseEntropy(Match match) {
  var i, m, possibilities, iMax;

  String word = match.token;
  if (_allLowerRegExp.hasMatch(word)) {
    return 0;
  }
  // a capitalized word is the most common capitalization scheme,
  // so it only doubles the search space (uncapitalized + capitalized): 1 extra bit of entropy.
  //  allcaps and end-capitalized are common enough too, underestimate as 1 extra bit to be safe.
  for (RegExp regex in [_startUpperRegExp, _endUpperRegExp, _allUpperRegExp]) {
    if (regex.hasMatch(word)) {
      return 1;
    }
  }

  // otherwise calculate the number of ways to capitalize U+L uppercase+lowercase letters
  // with U uppercase letters or less. or, if there's more uppercase than lower (for eg. PASSwORD),
  // the number of ways to lowercase U+L letters with L lowercase letters or less.
  int u = 0;
  int l = 0;
  RegExp azUpper = new RegExp(r"[A-Z]");
  RegExp azLower = new RegExp(r"[a-z]");
  for (int i = 0; i < word.length; i++) {
    String chr = word[i];
    if (azUpper.hasMatch(chr)) {
      u++;
    }
    if (azLower.hasMatch(chr)) {
      l++;
    }
  }

  possibilities = 0;
  i = 1;
  iMax = math.min(u, l);
  // Dart port should be...
  // for (i = 1; i <= math.min(U, L); i) {
  // but somehow we need to handle when uMax is 0...Bad algo conversion?
  for (m = 1; 1 <= iMax ? m <= iMax : m >= iMax; i = 1 <= iMax ? ++m : --m) {
    possibilities += nCk(u + l, i);
  }
  return lg(possibilities);
}

num extraL33tEntropy(DictionaryMatch match) {
  var chr, extraEntropy, i, possibilities;
  if (match.l33t != true) {
    return 0;
  }
  extraEntropy = 0;
  match.sub.forEach((String subbed, String unsubbed) {
    // lower-case match.token before calculating: capitalization shouldn't affect l33t calc.
    String lowerToken = match.token.toLowerCase();
    // num of subbed chars
    int s = 0;
    // num of unsubbed chars
    int u = 0;
    for (int i = 0; i < lowerToken.length; i++) {
      chr = lowerToken[i];
      if (chr == subbed) {
        s++;
      }
      if (chr == unsubbed) {
        u++;
      }
    }

    if (s == 0 || u == 0) {
      // for this sub, password is either fully subbed (444) or fully unsubbed (aaa)
      // treat that as doubling the space (attacker needs to try fully subbed chars in addition to
      //# unsubbed.)
      extraEntropy += 1;
    } else {
      // this case is similar to capitalization:
      // with aa44a, U = 3, S = 2, attacker needs to try unsubbed + one sub + two subs

      possibilities = 0;
      for (i = 1; i <= math.min(u, s); i++) {
        possibilities += nCk(u + s, i);
      }
      extraEntropy += lg(possibilities);
    }
  });
  return extraEntropy;
}

class BruteforceMatch extends Match {
  int cardinality;
  BruteforceMatch({this.cardinality, int i, int j, String token, num entropy})
      : super(pattern: "bruteforce", i: i, j: j, token: token, entropy: entropy);
}

/**
 * minimum entropy search
 *
 * takes a list of overlapping matches, returns the non-overlapping sublist with
 * minimum entropy. O(nm) dp alg for length-n password with m candidate matches.
 */
Result minimumEntropyMatchSequence(String password, List<Match> matches) {
  num candidateEntropy, crackTime, minEntropy;
  int i, j, k;
  List upToK;
  Match match;
  List<Match> matchSequence, matchSequenceCopy;

  _safeArrayValue(List array, int index) {
    if ((index < 0) || (index >= array.length)) {
      return 0;
    }
    var value = array[index];
    if (value == null) {
      value = 0;
    }
    return value;
  }

  int bruteforceCardinality = calcBruteforceCardinality(password); // e.g. 26 for lowercase
  int passwordLength = password.length;
  upToK = new List(passwordLength + 1); //  minimum entropy up to k.
  // for the optimal seq of matches up to k, backpointers holds the final match (match.j == k).
  // null means the sequence ends w/ a brute-force character.
  List<Match> backpointers = new List(passwordLength + 1);
  for (k = 0; k <= passwordLength; k++) {
    // starting scenario to try and beat:
    // adding a brute-force character to the minimum entropy sequence at k-1.
    upToK[k] = _safeArrayValue(upToK, k - 1) + lg(bruteforceCardinality);
    backpointers[k] = null;

    for (Match match in matches) {
      if (!(match.j == k)) {
        continue;
      }
      i = match.i;
      j = match.j;

      // see if best entropy up to i-1 + entropy of this match is less than current minimum at j.
      candidateEntropy = _safeArrayValue(upToK, i - 1) + calcEntropy(match);
      if (candidateEntropy < upToK[j]) {
        upToK[j] = candidateEntropy;
        backpointers[j] = match;
      }
    }
  }

  // walk backwards and decode the best sequence
  matchSequence = [];
  k = passwordLength - 1;
  while (k >= 0) {
    match = backpointers[k];
    if (match != null) {
      matchSequence.add(match);
      k = match.i - 1;
    } else {
      k -= 1;
    }
  }
  matchSequence = new List.from(matchSequence.reversed);

  // fill in the blanks between pattern matches with bruteforce "matches"
  // that way the match sequence fully covers the password:
  // match1.j == match2.i - 1 for every adjacent match1, match2.
  makeBruteforceMatch(i, j) {
    return new BruteforceMatch(
        i: i,
        j: j,
        token: password.substring(i, j + 1),
        entropy: lg(math.pow(bruteforceCardinality, j - i + 1)),
        cardinality: bruteforceCardinality);
  }

  k = 0;
  matchSequenceCopy = [];
  for (match in matchSequence) {
    i = match.i;
    j = match.j;
    if (i - k > 0) {
      matchSequenceCopy.add(makeBruteforceMatch(k, i - 1));
    }
    k = j + 1;
    matchSequenceCopy.add(match);
  }
  if (k < password.length) {
    matchSequenceCopy.add(makeBruteforceMatch(k, password.length - 1));
  }
  matchSequence = matchSequenceCopy;

  minEntropy = _safeArrayValue(upToK, password.length - 1);
  crackTime = entropyToCrackTime(minEntropy);

  // final result object
  return new Result()
    ..password = password
    ..entropy = roundToXDigits(minEntropy, 3)
    ..matchSequence = matchSequence
    ..feedback = new Feedback(score, matchSequence).toString()
    ..crackTime = roundToXDigits(crackTime, 3)
    ..crackTimeDisplay = displayTime(crackTime)
    ..score = crackTimeToScore(crackTime);
}

int roundToXDigits(n, x) {
  return ((n * math.pow(10, x)) / math.pow(10, x)).round();
}
