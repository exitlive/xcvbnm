library xcvbnm.matching;

import "scoring.dart" as scoring;
import 'frequency_lists.dart';
import 'adjacency_graphs.dart';
import "../xcvbnm.dart" as xcvbnm;
import 'dart:core' as core;
import 'dart:core' hide Match;

bool empty(var obj) {
  // for array & map
  return obj.isEmpty;
}

extend(List lst, List lst2) => lst.addAll(lst2);

String translate(String string, Map chrMap) {
  var chr;
  List result = [];
  for (chr in string.split("")) {
    var translated = chrMap[chr];
    if (translated != null) {
      chr = translated;
    }
    result.add(chr);
  }
  return result.join("");
}

// mod impl that works for negative numbers
int mod(int n, int m) => ((n % m) + m) % m;

List<scoring.Match> sorted(List<scoring.Match> matches) {
  // sort on i primary, j secondary
  matches.sort((m1, m2) {
    int iDiff = (m1.i - m2.i);
    if (iDiff == 0) {
      return (m1.j - m2.j);
    }
    return iDiff;
  });
  return matches;
}

Map<String, int> buildRankedDict(List orderedList) {
  Map<String, int> result = {};
  var i = 1; // rank starts at 1, not 0
  for (String word in orderedList) {
    result[word] = i++;
  }
  return result;
}

Map<String, Map<String, int>> rankedDictionaries = {
  "passwords": buildRankedDict(frequencyLists["passwords"]),
  "english": buildRankedDict(frequencyLists["english"]),
  "surnames": buildRankedDict(frequencyLists["surnames"]),
  "male_names": buildRankedDict(frequencyLists["male_names"]),
  "female_names": buildRankedDict(frequencyLists["female_names"])
};

Map<String, String> sequences = {
  'lower': 'abcdefghijklmnopqrstuvwxyz',
  'upper': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'digits': '0123456789'
};

Map<String, List<String>> l33tTable = {
  'a': ['4', '@'],
  'b': ['8'],
  'c': ['(', '{', '[', '<'],
  'e': ['3'],
  'g': ['6', '9'],
  'i': ['1', '!', '|'],
  'l': ['1', '|', '7'],
  'o': ['0'],
  's': [r'$', '5'],
  't': ['+', '7'],
  'x': ['%'],
  'z': ['2']
};

Map<String, RegExp> regexen = {
  'alpha_lower': new RegExp(r"[a-z]{2,}"),
  'alpha_upper': new RegExp(r"[A-Z]{2,}"),
  'alpha': new RegExp(r"[a-zA-Z]{2,}"),
  'alphanumeric': new RegExp(r"[a-zA-Z0-9]{2,}"),
  'digits': new RegExp(r"\d{2,}"),
  'symbols': new RegExp(r"[\W_]{2,}"), // includes non-latin unicode chars
  'recent_year': new RegExp(r"19\d\d|200\d|201\d")
};

Map<String, int> regexPrecedence = {
  "alphanumeric": 0,
  "alpha": 1,
  "alpha_lower": 2,
  "alpha_upper": 2,
  "digits": 2,
  "symbols": 2,
  "recent_year": 3
};

int dateMaxYear = 2050;
int dateMinYear = 1000;

Map<int, List<List<int>>> dateSplits = {
  4: [
    [1, 2],
    [2, 3]
  ],
  5: [
    [1, 3],
    [2, 3]
  ],
  6: [
    [1, 2],
    [2, 4],
    [4, 5]
  ],
  7: [
    [1, 3],
    [2, 3],
    [4, 5],
    [4, 6]
  ],
  8: [
    [2, 4],
    [4, 6]
  ]
};

/**
 * omnimatch -- combine everything
 */

List<scoring.Match> omnimatch(String password) {
  List<scoring.Match> matches = [];
  List<Function> matchers = [
    dictionaryMatch,
    reverseDictionaryMatch,
    l33tMatch,
    spatialMatch,
    repeatMatch,
    sequenceMatch,
    regexMatch,
    dateMatch
  ];

  for (var matcher in matchers) {
    matches.addAll(matcher(password));
  }

  return sorted(matches);
}

/**
 * dictionary match (common passwords, english, last names, etc) ----------------
 */

List<scoring.DictionaryMatch> dictionaryMatch(password, [Map rankedDictionaries_]) {
  // _ranked_dictionaries variable is for unit testing purposes
  var len, matches, rank, word;
  if (rankedDictionaries_ == null) {
    rankedDictionaries_ = rankedDictionaries;
  }
  matches = [];
  len = password.length;
  String password_lower = password.toLowerCase();
  rankedDictionaries_.forEach((dictionary_name, Map<String, int> ranked_dict) {
    for (int i = 0; i < len; i++) {
      for (int j = i; j < len; j++) {
        word = password_lower.substring(i, j + 1);

        if (ranked_dict.containsKey(word)) {
          rank = ranked_dict[word];
          matches.add(new scoring.DictionaryMatch()
            ..i = i
            ..j = j
            ..token = password.substring(i, j + 1)
            ..matchedWord = word
            ..rank = rank
            ..dictionaryName = dictionary_name);
        }
      }
    }
  });
  return sorted(matches);
}

List<scoring.DictionaryMatch> reverseDictionaryMatch(password, [Map rankedDictionaries_]) {
  if (rankedDictionaries_ == null) {
    rankedDictionaries_ = rankedDictionaries;
  }
  String reversePassword = password.split('').reversed.join();
  List<scoring.DictionaryMatch> matches = dictionaryMatch(reversePassword, rankedDictionaries_);
  for (var match in matches) {
    match.token = match.token.split('').reversed.join(); // reverse back
    match.reversed = true;
    int i = password.length - 1 - match.j;
    int j = password.length - 1 - match.i;
    match.i = i;
    match.j = j;
  }
  return sorted(matches);
}

setUserInputDictionary(List<String> orderedList) {
  rankedDictionaries['user_inputs'] = buildRankedDict(orderedList);
}

//
// # dictionary match with common l33t substitutions
//

// makes a pruned copy of l33t_table that only includes password's possible substitutions
Map<String, List<String>> relevantL33tSubtable(String password, Map<String, Iterable<String>> table) {
  Map passwordChars = {};
  for (int i = 0; i < password.length; i++) {
    String chr = password[i];
    passwordChars[chr] = true;
  }
  Map subtable = {};
  table.forEach((letter, Iterable<String> subs) {
    List<String> relevantSubs = [];
    subs.forEach((String sub) {
      if (passwordChars.containsKey(sub)) {
        relevantSubs.add(sub);
      }
    });
    if (relevantSubs.isNotEmpty) {
      subtable[letter] = relevantSubs;
    }
  });
  return subtable;
}

/**
 * not supported in dart
 * in javascript, it compares the first element, if null put it at the end, if empty at the beginnin
 * it handles list recursively
 *
 * [[2, 3], [1, 2], null, [], 1, 3] => [[], 1, [1, 2], [2, 3], 3, null]
 * @return the list itself
 */
List<List> sortListOfList(List<List> lists) {
  int compareValue(var v1, var v2) {
    try {
      if (v1 == null) {
        if (v2 == null) {
          return 0;
        }
        return 1;
      } else if (v2 == null) {
        return -1;
      }
      return v1.compareTo(v2);
    } catch (e) {}
    return 0;
  }
  //
  int compare(var l1, var l2) {
    // null at the end
    if (l1 == null) {
      if (l2 == null) {
        return 0;
      }
      return 1;
    } else if (l2 == null) {
      return -1;
    }

    // convert to list
    if (!(l1 is List)) {
      l1 = [l1];
    }
    if (!(l2 is List)) {
      l2 = [l2];
    }

    // empty at the beginning
    if (l1.isEmpty) {
      if (l2.isEmpty) {
        return 0;
      }
      return -1;
    } else if (l2.isEmpty) {
      return 1;
    }

    if (l1[0] is List) {
      return compare(l1[0], l2[0]);
    }

    int result = 0;
    for (int i = 0; i < l1.length; i++) {
      // l1 bigger so exit
      if (i >= l2.length) {
        return 1;
      } else {
        result = compareValue(l1[i], l2[i]);
        if (result != 0) {
          break;
        }
      }
    }
    if (result == 0 && l2.length > l1.length) {
      return -1;
    }

    return result;
  }
  lists.sort(compare);
  return lists;
}

// returns the list of possible 1337 replacement dictionaries for a given password
List<Map> enumerateL33tSubs(Map<String, List<String>> table) {
  List<String> keys = new List.from(table.keys);

  List<List> dedup(List<List> subs_) {
    List<List> deduped = [];
    Map<String, bool> members = {};

    subs_.forEach((List sub) {
      List<List> assoc = [];
      for (int v = 0; v < sub.length; v++) {
        var k = sub[v];
        assoc.add([k, v]);
      }
      sortListOfList(assoc);
      List<String> labelParts = [];
      assoc.forEach((List row) {
        var k = row[0];
        var v = row[1];
        labelParts.add("${k},${v}");
      });
      String label = labelParts.join('-');
      // Avoid duplicates
      if (!members.containsKey(label)) {
        members[label] = true;
        deduped.add(sub);
      }
    });
    return deduped;
  }

  List<List<List<String>>> subs = [[]];

  void helper(List<String> keys) {
    if (keys.isEmpty) {
      return;
    }
    String firstKey = keys[0];
    List<String> restKeys = keys.sublist(1);
    List<List> nextSubs = [];

    table[firstKey].forEach((String l33tChr) {
      for (List<List<String>> sub in subs) {
        int dupL33tIndex = -1;
        for (int i = 0; i < sub.length; i++) {
          if (sub[i][0] == l33tChr) {
            dupL33tIndex = i;
            break;
          }
        }
        if (dupL33tIndex == -1) {
          List subExtension = new List.from(sub);
          subExtension.addAll([
            [l33tChr, firstKey]
          ]);
          nextSubs.add(subExtension);
        } else {
          List subAlternative = new List.from(sub);
          subAlternative.removeRange(dupL33tIndex, dupL33tIndex + 1);
          subAlternative.add([l33tChr, firstKey]);
          nextSubs.add(sub);
          nextSubs.add(subAlternative);
        }
      }
    });
    subs = dedup(nextSubs);
    helper(restKeys);
  }

  helper(keys);
  List subDicts = [];
  for (var sub in subs) {
    Map<String, String> subDict = {};
    sub.forEach((List data) {
      String l33t_chr = data[0];
      String chr = data[1];
      subDict[l33t_chr] = chr;
    });
    subDicts.add(subDict);
  }
  return subDicts;
}

List<scoring.DictionaryMatch> l33tMatch(String password,
    [Map<String, Map<String, int>> rankedDictionaries_, Map<String, List<String>> l33tTable_]) {
  List<scoring.DictionaryMatch> matches = [];
  if (rankedDictionaries_ == null) {
    rankedDictionaries_ = rankedDictionaries;
  }
  if (l33tTable_ == null) {
    l33tTable_ = l33tTable;
  }

  for (Map sub in enumerateL33tSubs(relevantL33tSubtable(password, l33tTable_))) {
    // corner case: password has no relevant subs.
    if (sub.isEmpty) {
      break;
    }
    String subbedPassword = translate(password, sub);
    dictionaryMatch(subbedPassword, rankedDictionaries_).forEach((scoring.DictionaryMatch match) {
      String token = password.substring(match.i, match.j + 1);
      if (token.toLowerCase() != match.matchedWord) {
        Map matchSub = {};
        sub.forEach((subbedChr, chr) {
          if (token.indexOf(subbedChr) != -1) {
            matchSub[subbedChr] = chr;
          }
        });
        match.l33t = true;
        match.token = token;
        match.sub = matchSub;
        // match.sub_display = ("#{k} -> #{v}" for k,v of match_sub).join(', ')
        // dart specific:
        // match.subDisplay don't do that, sub can be displayed using toString (subDisplay is then a getter
        matches.add(match);
      }
    });
  }
  return matches;
}

/**
 * spatial match (qwerty/dvorak/keypad)
 */

List<scoring.SpatialMatch> spatialMatch(String password, [Map<String, Map<String, List<String>>> graphs_]) {
  if (graphs_ == null) {
    graphs_ = adjacencyGraphs;
  }
  List<scoring.Match> matches = [];
  graphs_.forEach((graphName, graph) {
    matches.addAll(spatialMatchHelper(password, graph, graphName));
  });
  sorted(matches);
  return matches;
}

RegExp shiftedRx = new RegExp(r'[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]');

List<scoring.SpatialMatch> spatialMatchHelper(String password, Map<String, List<String>> graph, String graphName) {
  List<scoring.SpatialMatch> matches = [];
  int i = 0;
  while (i < password.length - 1) {
    int j = i + 1;
    int lastDirection = null;
    int turns = 0;
    int shiftedCount;
    if (['qwerty', 'dvorak'].contains(graphName) && shiftedRx.hasMatch(password.substring(i, j))) {
      // initial character is shifted
      shiftedCount = 1;
    } else {
      shiftedCount = 0;
    }
    while (true) {
      String prevChar = password.substring(j - 1, j);
      bool found = false;
      int foundDirection = -1;
      int curDirection = -1;

      List<String> adjacents = graph[prevChar];
      if (adjacents == null) {
        adjacents = [];
      }

      // consider growing pattern by one character if j hasn't gone over the edge.
      if (j < password.length) {
        String curChar = password.substring(j, j + 1);
        for (String adj in adjacents) {
          curDirection += 1;
          if ((adj != null) && (adj.indexOf(curChar) != -1)) {
            found = true;
            foundDirection = curDirection;
            if (adj.indexOf(curChar) == 1) {
              // index 1 in the adjacency means the key is shifted,
              // 0 means unshifted: A vs a, % vs 5, etc.
              // for example, 'q' is adjacent to the entry '2@'.
              // @ is shifted w/ index 1, 2 is unshifted.
              shiftedCount += 1;
            }
            if (lastDirection != foundDirection) {
              // adding a turn is correct even in the initial case when last_direction is null:
              // every spatial pattern starts with a turn.
              turns += 1;
              lastDirection = foundDirection;
            }
            break;
          }
        }
      }
      // if the current pattern continued, extend j and try to grow again
      if (found) {
        j += 1;
      } else {
        // otherwise push the pattern discovered so far, if any...
        if (j - i > 2) {
          // don't consider length 1 or 2 chains.

          matches.add(new scoring.SpatialMatch(
              i: i,
              j: j - 1,
              token: password.substring(i, j),
              graph: graphName,
              turns: turns,
              shiftedCount: shiftedCount));
        }
        // ...and then start a new search for the rest of the password.
        i = j;
        break;
      }
    }
  }
  return matches;
}

/**
 * repeats (aaa, abcabcabc) and sequences (abcdef)
 */
List<scoring.RepeatMatch> repeatMatch(String password) {
  List<scoring.RepeatMatch> matches = [];
  RegExp greedy = new RegExp(r"(.+)\1+");
  RegExp lazy = new RegExp(r"(.+?)\1+");
  RegExp lazyAnchored = new RegExp(r"^(.+?)\1+$");
  int lastIndex = 0;
  core.Match match;
  String baseToken;

  while (lastIndex < password.length) {
    // We test password after lastIndex
    String pattern = password.substring(lastIndex);

    core.Match greedyMatch = greedy.firstMatch(pattern);
    core.Match lazyMatch = lazy.firstMatch(pattern);
    if (greedyMatch == null) {
      break;
    }

    if (greedyMatch.end - greedyMatch.start > lazyMatch.end + lazyMatch.start) {
      // greedy beats lazy for 'aabaab'
      //  greedy: [aabaab, aab]
      // lazy:   [aa,     a]
      match = greedyMatch;
      //  greedy's repeated string might itself be repeated, eg.
      // aabaab in aabaabaabaab.
      // run an anchored lazy match on greedy's repeated string
      // to find the shortest repeated string
      baseToken = lazyAnchored.firstMatch(match.group(0)).group(1);
    } else {
      // lazy beats greedy for 'aaaaa'
      //   greedy: [aaaa,  aa]
      //   lazy:   [aaaaa, a]
      match = lazyMatch;
      baseToken = match.group(1);
    }

    int i = lastIndex + match.start;
    int j = lastIndex + match.start + match.group(0).length - 1;

    // recursively match and score the base string
    xcvbnm.Result baseAnalysis = scoring.minimumEntropyMatchSequence(baseToken, omnimatch(baseToken));
    List<scoring.Match> baseMatches = baseAnalysis.matchSequence;
    num baseEntropy = baseAnalysis.entropy;
    matches.add(new scoring.RepeatMatch(
        i: i, j: j, token: match[0], baseToken: baseToken, baseEntropy: baseEntropy, baseMatches: baseMatches));
    lastIndex = j + 1;
  }
  return matches;
}

List<scoring.Match> sequenceMatch(String password) {
  List<scoring.Match> matches = [];
  int minSequenceLength = 3; // TODO allow 2-char sequences?

  sequences.forEach((String sequenceName, String sequence) {
    for (int direction in [1, -1]) {
      int i = 0;
      while (i < password.length) {
        String chr = password[i];
        int sequencePosition = sequence.indexOf(chr);
        if (sequencePosition == -1) {
          i += 1;
          continue;
        }
        int j = i + 1;

        while (j < password.length) {
          // mod by sequence length to allow sequences to wrap around: xyzabc
          int nextSequencePosition = mod(sequencePosition + direction, sequence.length);
          if (sequence.indexOf(password[j]) != nextSequencePosition) {
            break;
          }
          j += 1;
          sequencePosition = nextSequencePosition;
        }
        j -= 1;
        if (j - i + 1 >= minSequenceLength) {
          matches.add(new scoring.SequenceMatch(
              i: i,
              j: j,
              token: password.substring(i, j + 1),
              sequenceName: sequenceName,
              sequenceSpace: sequence.length,
              ascending: direction == 1));
        }
        i = j + 1;
      }
    }
  });
  return sorted(matches);
}

/**
 * regex matching
 */
List<scoring.RegexMatch> regexMatch(password, [Map<String, RegExp> _regexen]) {
  if (_regexen == null) {
    _regexen = regexen;
  }

  List<scoring.RegexMatch> matches = [];
  _regexen.forEach((String name, RegExp regex) {
    // regex.lastIndex = 0 # keeps regex_match stateless
    // Here the dart port is slightly different as we don't have the ability to "continue" a regexp
    // Instead use a allMatches
    Iterable<core.Match> rxAllMatches = regex.allMatches(password);

    for (core.Match rxMatch in rxAllMatches) {
      String token = rxMatch[0];
      // Convert match to list of string
      List<String> regexMatches = [];
      for (int i = 0; i <= rxMatch.groupCount; i++) {
        regexMatches.add(rxMatch[i]);
      }

      matches.add(new scoring.RegexMatch(
          token: token, i: rxMatch.start, j: rxMatch.end - 1, regexName: name, regexMatch: regexMatches));
    }
  });

  // currently, match list includes a bunch of redundancies:
  // ex for every alpha_lower match, also an alpha and alphanumeric match of the same [i,j].
  // ex for every recent_year match, also an alphanumeric match and digits match.
  //# use precedence to filter these redundancies out.
  Map<String, Object> precedence_map = {}; // maps from 'i-j' to current highest precedence
  String getKey(scoring.Match match) => "${match.i}-${match.j}";
  int higestPrecedence;
  for (scoring.RegexMatch match in matches) {
    String key = getKey(match);
    int precedence = regexPrecedence[match.regexName];
    if (precedence_map.containsKey(key)) {
      higestPrecedence = precedence_map[key];
      if (higestPrecedence > precedence) {
        continue;
      }
    }
    precedence_map[key] = precedence;
  }
  return sorted(new List.from(matches.where((scoring.RegexMatch match) {
    return (precedence_map[getKey(match)] == regexPrecedence[match.regexName]);
  })));
}

/**
 * date matching
 */
List<scoring.Match> dateMatch(String password) {
  // a "date" is recognized as:
  // any 3-tuple that starts or ends with a 2- or 4-digit year,
  //   with 2 or 0 separator chars (1.1.91 or 1191),
  //   maybe zero-padded (01-01-91 vs 1-1-91),
  //   a month between 1 and 12,
  //   a day between 1 and 31.
  //
  // note: this isn't true date parsing in that "feb 31st" is allowed,
  // this doesn't check for leap years, etc.
  //
  // recipe:
  // start with regex to find maybe-dates, then attempt to map the integers
  // onto month-day-year to filter the maybe-dates into dates.
  // finally, remove matches that are substrings of other matches to reduce noise.
  //
  // note: instead of using a lazy or greedy regex to find many dates over the full string,
  // this uses a ^...$ regex against every substring of the password -- less performant but leads
  // to every possible date match.
  List<scoring.Match> matches = [];
  RegExp maybeDateNoSeparator = new RegExp(r"^\d{4,8}$");
  // ( \d{1,4} )    day, month, year
  // ( [\s/\\_.-] ) separator
  // ( \d{1,2} )    day, month
  // \2             same separator
  // ( \d{1,4} )    day, month, year
  RegExp maybeDateWithSeparator = new RegExp(r'^(\d{1,4})([\s/\\_.-])(\d{1,2})\2(\d{1,4})$');

  // dates without separators are between length 4 '1191' and 8 '11111991'

  for (int i = 0; i <= password.length - 4; i++) {
    for (int j = i + 3; j <= i + 7; j++) {
      if (j >= password.length) {
        break;
      }
      String token = password.substring(i, j + 1);
      if (!maybeDateNoSeparator.hasMatch(token)) {
        continue;
      }
      List candidates = [];

      for (List<int> row in dateSplits[token.length]) {
        int k = row[0];
        int l = row[1];
        _DayMonthYear dmy = mapIntsToDmy(
            [int.parse(token.substring(0, k)), int.parse(token.substring(k, l)), int.parse(token.substring(l))]);
        if (dmy != null) {
          candidates.add(dmy);
        }
      }

      if (!(candidates.length > 0)) {
        continue;
      }
      // at this point: different possible dmy mappings for the same i,j substring.
      // match the candidate date that has smallest entropy: a year closest to 2000.
      // (scoring.REFERENCE_YEAR).
      //
      // ie, considering '111504', prefer 11-15-04 to 1-1-1504
      // (interpreting '04' as 2004)
      _DayMonthYear bestCandidate;

      int metric(candidate) => (candidate.year - scoring.referenceYear).abs();
      int minDistance = null;
      for (_DayMonthYear candidate in candidates) {
        int distance = metric(candidate);

        if (minDistance == null || (distance < minDistance)) {
          minDistance = distance;
          bestCandidate = candidate;
        }
      }

      matches.add(new scoring.DateMatch(
          token: token,
          i: i,
          j: j,
          separator: '',
          year: bestCandidate.year,
          month: bestCandidate.month,
          day: bestCandidate.day));
    }
  }

  // dates with separators are between length 6 '1/1/91' and 10 '11/11/1991'
  for (int i = 0; i <= password.length - 6; i++) {
    for (int j = i + 5; j <= i + 9; j++) {
      if (j >= password.length) {
        break;
      }
      String token = password.substring(i, j + 1);

/*      if (!maybe_date_with_separator.hasMatch(token)) {
        continue;
      }
      */
      core.Match rxMatch = maybeDateWithSeparator.firstMatch(token);
      if (rxMatch == null) {
        continue;
      }
      _DayMonthYear dmy = mapIntsToDmy([int.parse(rxMatch[1]), int.parse(rxMatch[3]), int.parse(rxMatch[4])]);

      if (dmy == null) {
        continue;
      }

      matches.add(new scoring.DateMatch(
          token: token, i: i, j: j, separator: rxMatch[2], year: dmy.year, month: dmy.month, day: dmy.day));
    }
  }

  // matches now contains all valid date strings in a way that is tricky to capture
  // with regexes only. while thorough, it will contain some unintuitive noise:
  //
  // '2015_06_04', in addition to matching 2015_06_04, will also contain
  // 5(!) other date matches: 15_06_04, 5_06_04, ..., even 2015 (matched as 5/1/2020)
  //
  // to reduce noise, remove date matches that are strict substrings of others
  List<scoring.DateMatch> filteredMatches = [];
  for (var match in matches) {
    bool isSubmatch = false;
    for (var otherMatch in matches) {
      if (match == otherMatch) {
        continue;
      }

      if (otherMatch.i <= match.i && otherMatch.j >= match.j) {
        isSubmatch = true;
        break;
      }
    }
    if (!isSubmatch) {
      filteredMatches.add(match);
    }
  }
  return sorted(filteredMatches);
}

_DayMonthYear mapIntsToDmy(List<int> ints) {
  // given a 3-tuple, discard if:
  //   middle int is over 31 (for all dmy formats, years are never allowed in the middle)
  //   middle int is zero
  //   any int is over the max allowable year
  //   any int is over two digits but under the min allowable year
  //   2 ints are over 31, the max allowable day
  //   2 ints are zero
  //   all ints are over 12, the max allowable month
  if (ints[1] > 31 || ints[1] <= 0) {
    return null;
  }

  int over12 = 0;
  int over31 = 0;
  int under1 = 0;
  for (int i in ints) {
    if ((99 < i && i < dateMinYear) || (i > dateMaxYear)) {
      return null;
    }
    if (i > 31) {
      over31 += 1;
    }
    if (i > 12) {
      over12 += 1;
    }
    if (i <= 0) {
      under1 += 1;
    }
  }
  if ((over31 >= 2) || (over12 == 3) || (under1 >= 2)) {
    return null;
  }

  // first look for a four digit year: yyyy + daymonth or daymonth + yyyy
  List possibleYearSplits = [
    [ints[2], ints.sublist(0, 2)], // year last
    [ints[0], ints.sublist(1, 3)] // year first
  ];

  for (List row in possibleYearSplits) {
    int y = row[0];
    List rest = row[1];

    if (dateMinYear <= y && y <= dateMaxYear) {
      // GOON HERE
      _DayMonth dm = mapIntsToDm(rest);
      if (dm != null) {
        return new _DayMonthYear(day: dm.day, month: dm.month, year: y);
      } else {
        // for a candidate that includes a four-digit year,
        // when the remaining ints don't match to a day and month,
        // it is not a date.
        return null;
      }
    }
  }

  // given no four-digit year, two digit years are the most flexible int to match, so
  // try to parse a day-month out of ints[0..1] or ints[1..0]
  for (List row in possibleYearSplits) {
    int y = row[0];
    List rest = row[1];

    _DayMonth dm = mapIntsToDm(rest);
    if (dm != null) {
      y = twoToFourDigitYear(y);
      return new _DayMonthYear(day: dm.day, month: dm.month, year: y);
    }
  }
  return null;
}

class _DayMonth {
  int day;
  int month;

  _DayMonth({this.day, this.month});

  toString() => "$month/$day";
}

class _DayMonthYear extends _DayMonth {
  int year;

  _DayMonthYear({int day, int month, this.year}) : super(day: day, month: month);

  toString() => "$year/${super.toString()}";
}

_DayMonth mapIntsToDm(List<int> ints) {
  for (List row in [ints, new List.from(ints.reversed)]) {
    int d = row[0];
    int m = row[1];
    if ((1 <= d && d <= 31) && (1 <= m && m <= 12)) {
      return new _DayMonth(day: d, month: m);
    }
  }
  return null;
}

int twoToFourDigitYear(int year) {
  if (year > 99) {
    return year;
  } else {
    if (year > 50) {
      // 87 -> 1987
      return year + scoring.referenceYear - 100;
    } else {
      // 15 -> 2015
      return year + scoring.referenceYear;
    }
  }
}
