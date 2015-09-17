library xcvbnm.scoring;

import 'dart:math' as math;
import "adjacency_graphs.dart";
import "xcvbnm_common.dart" as xcvbnm;
import 'dart:core';
import 'dart:core' as core;

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
  var base, century, day, display_num, display_str, hour, minute, month, ref, year;
  minute = 60;
  hour = minute * 60;
  day = hour * 24;
  month = day * 31;
  year = month * 12;
  century = year * 100;
  if (seconds < minute) {
    ref = [seconds, "${seconds} second"];
  } else if (seconds < hour) {
    base = (seconds / minute).round();
    ref = [base, "${base} minute"];
  } else if (seconds < day) {
    base = (seconds / hour).round();
    ref = [base, "${base} hour"];
  } else if (seconds < month) {
    base = (seconds / day).round();
    ref = [base, "${base} day"];
  } else if (seconds < year) {
    base = (seconds / month).round();
    ref = [base, "${base} month"];
  } else if (seconds < century) {
    base = (seconds / year).round();
    ref = [base, "${base} year"];
  } else {
    ref = [null, 'centuries'];
  }
  display_num = ref[0];
  display_str = ref[1];
  if ((display_num != null) && display_num != 1) {
    display_str += 's';
  }
  return display_str;
}

class Match extends xcvbnm.Match {
  String pattern;

  num entropy;

  Match({this.pattern, this.i, this.j, this.token});

  // repeat/sequence/regex/spatial entropy
  String token;

  // dictionary
  int rank;
  num baseEntropy;
  num uppercaseEntropy;
  bool l33t;
  num l33tEntropy;
  Map<String, String> sub;

  String get subDisplay {
    if (sub == null) {
      return null;
    }
    return sub.toString();
  }

  // match sequence
  int i;
  int j;
  int cardinality;

  toMap() {
    Map map = {};
    if (pattern != null) {
      map["pattern"] = pattern;
    }
    if (token != null) {
      map["token"] = token;
    }
    if (i != null) {
      map["i"] = i;
    }
    if (j != null) {
      map["j"] = j;
    }
    return map;
  }

  toString() => toMap().toString();
}

class SequenceMatch extends Match {
  SequenceMatch({this.ascending, int i, int j, String token, this.sequenceName, this.sequenceSpace})
      : super(pattern: 'sequence', i: i, j: j, token: token);

  // sequence entropy
  String sequenceName;
  int sequenceSpace;
  bool ascending;
}

class RepeatMatch extends Match {
  // regex
  String repeatedChar;

  RepeatMatch({this.repeatedChar, int i, int j, String token}) : super(pattern: 'repeat', i: i, j: j, token: token);
}

class SpatialMatch extends Match {
  // spatial
  String graph;
  int shiftedCount;
  int turns;

  SpatialMatch({this.graph, this.shiftedCount, this.turns, int i, int j, String token})
      : super(pattern: 'spatial', i: i, j: j, token: token);
}

class RegexMatch extends Match {
  // regex
  String regexName;
  List<String> regexMatch;

  RegexMatch({this.regexName, this.regexMatch, int i, int j, String token})
      : super(pattern: 'regex', i: i, j: j, token: token);
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
  Map<String, Object> toMap() {
    Map map = super.toMap();
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

num dateEntropy(DateMatch match) {
  var entropy, year_space;
  year_space = math.max((match.year - referenceYear).abs(), minYearSpace);
  entropy = lg(year_space * 31 * 12);
  if (match.hasFullYear == true) {
    entropy += 1;
  }
  if (match.separator != null && match.separator.length > 0) {
    entropy += 2;
  }
  return entropy;
}

num repeatEntropy(Match match) {
  var cardinality;
  cardinality = calcBruteforceCardinality(match.token);
  return lg(cardinality * match.token.length);
}

num sequenceEntropy(SequenceMatch match) {
  var base_entropy;
  String first_chr = match.token[0];
  if (['a', '1'].contains(first_chr)) {
    base_entropy = 1;
  } else {
    if (new RegExp(r"\d").hasMatch(first_chr)) {
      base_entropy = lg(10);
    } else if (new RegExp(r"[a-z]").hasMatch(first_chr)) {
      base_entropy = lg(26);
    } else {
      base_entropy = lg(26) + 1;
    }
  }
  if (!match.ascending) {
    base_entropy += 1;
  }
  return base_entropy + lg(match.token.length);
}

num regexEntropy(RegexMatch match) {
  var year_space;
  Map char_class_bases = {
    "alpha_lower": 26,
    "alpha_upper": 26,
    "alpha": 52,
    "alphanumeric": 62,
    "digits": 10,
    "symbols": 33
  };
  if (char_class_bases.containsKey(match.regexName)) {
    return lg(math.pow(char_class_bases[match.regexName], match.token.length));
  } else {
    switch (match.regexName) {
      case 'recent_year':
        year_space = (int.parse(match.regexMatch[0]) - referenceYear).abs();
        year_space = math.max(year_space, minYearSpace);
        return lg(year_space);
    }
  }
  return null;
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
  var L, S, U, d, entropy, i, j, l, m, o, possibilities, possible_turns, ref, ref1, ref2, ref3, s, t;
  if ((ref = match.graph) == 'qwerty' || ref == 'dvorak') {
    s = keyboardStartingPositions;
    d = keyboardAverageDegree;
  } else {
    s = keypadStartingPositions;
    d = keypadAverageDegree;
  }
  possibilities = 0;
  L = match.token.length;
  t = match.turns;
  i = 2;
  ref1 = L;
  for (l = 2; 2 <= ref1 ? l <= ref1 : l >= ref1; i = (2 <= ref1 ? ++l : --l)) {
    possible_turns = math.min(t, i - 1);
    j = 1;
    ref2 = possible_turns;
    for (m = 1; 1 <= ref2 ? m <= ref2 : m >= ref2; j = (1 <= ref2 ? ++m : --m)) {
      possibilities += nCk(i - 1, j - 1) * s * math.pow(d, j);
    }
  }
  entropy = lg(possibilities);
  if (match.shiftedCount != null && match.shiftedCount > 0) {
    S = match.shiftedCount;
    U = match.token.length - match.shiftedCount;
    if (U == 0) {
      entropy += 1;
    } else {
      possibilities = 0;
      i = 1;
      ref3 = math.min(S, U);
      for (o = 1; 1 <= ref3 ? o <= ref3 : o >= ref3; i = (1 <= ref3 ? ++o : --o)) {
        possibilities += nCk(S + U, i);
      }
      entropy += lg(possibilities);
    }
  }
  return entropy;
}

num dictionaryEntropy(Match match) {
  match.baseEntropy = lg(match.rank);
  match.uppercaseEntropy = extraUppercaseEntropy(match);
  match.l33tEntropy = extraL33tEntropy(match);
  return match.baseEntropy + match.uppercaseEntropy + match.l33tEntropy;
}

var _startUpperRegExp = new RegExp(r"^[A-Z][^A-Z]+$");
var _endUpperRegExp = new RegExp(r"^[^A-Z]+[A-Z]$");
var _allUpperRegExp = new RegExp(r"^[^a-z]+$");
var _allLowerRegExp = new RegExp(r"^[^A-Z]+$");

num extraUppercaseEntropy(Match match) {
  var L, U, chr, i, l, len, m, possibilities, ref, ref1, regex;
  String word = match.token;
  if (_allLowerRegExp.hasMatch(word)) {
    return 0;
  }
  ref = [_startUpperRegExp, _endUpperRegExp, _allUpperRegExp];
  len = ref.length;
  for (l = 0; l < len; l++) {
    regex = ref[l];
    if (regex.hasMatch(word)) {
      return 1;
    }
  }
  U = ((() {
    var len1, m, ref1, results;
    ref1 = word.split('');
    results = [];
    len1 = ref1.length;
    for (m = 0; m < len1; m++) {
      chr = ref1[m];
      if (new RegExp(r"[A-Z]").hasMatch(chr)) {
        results.add(chr);
      }
    }
    return results;
  })()).length;
  L = ((() {
    var len1, m, ref1, results;
    ref1 = word.split('');
    results = [];
    len1 = ref1.length;
    for (m = 0; m < len1; m++) {
      chr = ref1[m];
      if (new RegExp(r"[a-z]").hasMatch(chr)) {
        results.add(chr);
      }
    }
    return results;
  })()).length;
  possibilities = 0;
  i = 1;
  ref1 = math.min(U, L);
  for (m = 1; 1 <= ref1 ? m <= ref1 : m >= ref1; i = 1 <= ref1 ? ++m : --m) {
    possibilities += nCk(U + L, i);
  }
  return lg(possibilities);
}

num extraL33tEntropy(Match match) {
  var S, U, chr, chrs, extra_entropy, i, l, p, possibilities, ref1, subbed, unsubbed;
  if (match.l33t != true) {
    return 0;
  }
  extra_entropy = 0;
  Map ref = match.sub;
  for (subbed in ref.keys) {
    unsubbed = ref[subbed];
    chrs = match.token.toLowerCase().split('');
    S = ((() {
      var l, len, results;
      results = [];
      len = chrs.length;
      for (l = 0; l < len; l++) {
        chr = chrs[l];
        if (chr == subbed) {
          results.add(chr);
        }
      }
      return results;
    })()).length;
    U = ((() {
      var l, len, results;
      results = [];
      len = chrs.length;
      for (l = 0; l < len; l++) {
        chr = chrs[l];
        if (chr == unsubbed) {
          results.add(chr);
        }
      }
      return results;
    })()).length;
    if (S == 0 || U == 0) {
      extra_entropy += 1;
    } else {
      p = math.min(U, S);
      possibilities = 0;
      i = 1;
      ref1 = p;
      for (l = 1; 1 <= ref1 ? l <= ref1 : l >= ref1; i = 1 <= ref1 ? ++l : --l) {
        possibilities += nCk(U + S, i);
      }
      extra_entropy += lg(possibilities);
    }
  }
  return extra_entropy;
}

xcvbnm.Result minimumEntropyMatchSequence(String password, List<Match> matches) {
  var bruteforce_cardinality,
      candidate_entropy,
      crack_time,
      i,
      j,
      k,
      len,
      len1,
      m,
      make_bruteforce_match,
      match,
      match_sequence_copy,
      min_entropy,
      o,
      ref2,
      up_to_k;
  List<Match> match_sequence;
  bruteforce_cardinality = calcBruteforceCardinality(password);

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

  int passwordLength = password.length;
  up_to_k = new List(passwordLength);
  List<Match> backpointers = new List(passwordLength);

  for (k = 0; k < passwordLength; k++) {
    up_to_k[k] = _safeArrayValue(up_to_k, k - 1) + lg(bruteforce_cardinality);
    backpointers[k] = null;
    len = matches.length;
    for (m = 0; m < len; m++) {
      match = matches[m];
      if (!(match.j == k)) {
        continue;
      }
      i = match.i;
      j = match.j;

      candidate_entropy = _safeArrayValue(up_to_k, i - 1) + calcEntropy(match);
      if (candidate_entropy < up_to_k[j]) {
        up_to_k[j] = candidate_entropy;
        backpointers[j] = match;
      }
    }
  }
  match_sequence = [];
  k = passwordLength - 1;
  while (k >= 0) {
    match = backpointers[k];
    if (match != null) {
      match_sequence.add(match);
      k = match.i - 1;
    } else {
      k -= 1;
    }
  }
  match_sequence = new List.from(match_sequence.reversed);
  make_bruteforce_match = (() {
    return (i, j) {
      return new Match()
        ..pattern = 'bruteforce'
        ..i = i
        ..j = j
        ..token = password.substring(i, j + 1)
        ..entropy = lg(math.pow(bruteforce_cardinality, j - i + 1))
        ..cardinality = bruteforce_cardinality;
    };
  })();
  k = 0;
  match_sequence_copy = [];
  len1 = match_sequence.length;
  for (o = 0; o < len1; o++) {
    match = match_sequence[o];
    ref2 = [match.i, match.j];
    i = ref2[0];
    j = ref2[1];
    if (i - k > 0) {
      match_sequence_copy.add(make_bruteforce_match(k, i - 1));
    }
    k = j + 1;
    match_sequence_copy.add(match);
  }
  if (k < password.length) {
    match_sequence_copy.add(make_bruteforce_match(k, password.length - 1));
  }
  match_sequence = match_sequence_copy;
  min_entropy = _safeArrayValue(up_to_k, password.length - 1);
  crack_time = entropyToCrackTime(min_entropy);
  return new xcvbnm.Result()
    ..password = password
    ..entropy = round_to_x_digits(min_entropy, 3)
    ..matchSequence = match_sequence
    ..crackTime = round_to_x_digits(crack_time, 3)
    ..crackTimeDisplay = displayTime(crack_time)
    ..score = crackTimeToScore(crack_time);
}

int round_to_x_digits(n, x) {
  return ((n * math.pow(10, x)) / math.pow(10, x)).round();
}
