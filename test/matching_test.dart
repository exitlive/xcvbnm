library xcvbnm.matching_test;

import 'package:test/test.dart';
import 'package:xcvbnm/src/matching.dart';
import "package:xcvbnm/src/scoring.dart" as scoring;

main() {
  test('matching utils', () {
    var chr_map,
        dividend,
        divisor,
        lst,
        lst1,
        lst2,
        m1,
        m2,
        m3,
        m4,
        m5,
        m6,
        map,
        msg,
        ref1,
        ref2,
        ref4,
        remainder,
        result,
        string;
    expect(empty([]), isTrue, reason: ".empty returns true for an empty array");
    expect(empty({}), isTrue, reason: ".empty returns true for an empty object");

    for (var value in [
      [1],
      [1, 2],
      [[]],
      {"a": 1},
      {"0": {}}
    ]) {
      expect(empty(value), isFalse, reason: ".empty returns false for non-empty objects and arrays");
    }

    lst = [];
    extend(lst, []);
    expect(lst, [], reason: "extending an empty list with an empty list leaves it empty");
    extend(lst, [1]);
    expect(lst, [1], reason: "extending an empty list with another makes it equal to the other");
    extend(lst, [2, 3]);
    expect(lst, [1, 2, 3], reason: "extending a list with another adds each of the other's elements");
    ref1 = [
      [1],
      [2]
    ];
    lst1 = ref1[0];
    lst2 = ref1[1];
    extend(lst1, lst2);
    expect(lst2, [2], reason: "extending a list by another doesn't affect the other");
    chr_map = {'a': 'A', 'b': 'B'};
    ref2 = [
      ['a', chr_map, 'A'],
      ['c', chr_map, 'c'],
      ['ab', chr_map, 'AB'],
      ['abc', chr_map, 'ABc'],
      ['aa', chr_map, 'AA'],
      ['abab', chr_map, 'ABAB'],
      ['', chr_map, ''],
      ['', {}, ''],
      ['abc', {}, 'abc']
    ];
    for (var row in ref2) {
      string = row[0];
      map = row[1];
      result = row[2];

      msg = "translates '${string}' to '${result}' with provided charmap";
      expect(translate(string, map), result, reason: msg);
    }

    ref4 = [
      [
        [0, 1],
        0
      ],
      [
        [1, 1],
        0
      ],
      [
        [-1, 1],
        0
      ],
      [
        [5, 5],
        0
      ],
      [
        [3, 5],
        3
      ],
      [
        [-1, 5],
        4
      ],
      [
        [-5, 5],
        0
      ],
      [
        [6, 5],
        1
      ]
    ];
    for (var row in ref4) {
      List result = row[0];
      dividend = result[0];
      divisor = result[1];
      remainder = row[1];
      msg = "mod(${dividend},${divisor}) == ${remainder}";
      expect(mod(dividend, divisor), remainder, reason: msg);
    }

    expect(sorted([]), [], reason: "sorting an empty list leaves it empty");

    scoring.Match m(i, j) {
      return new scoring.Match()
        ..i = i
        ..j = j;
    }

    var data = [m(5, 5), m(6, 7), m(2, 5), m(0, 0), m(2, 3), m(0, 3)];
    m1 = data[0];
    m2 = data[1];
    m3 = data[2];
    m4 = data[3];
    m5 = data[4];
    m6 = data[5];
    msg = "matches are sorted on i index primary, j secondary";
    expect(sorted([m1, m2, m3, m4, m5, m6]), [m4, m6, m5, m3, m1, m2], reason: msg);
  });

  // takes a pattern and list of prefixes/suffixes
  // returns a bunch of variants of that pattern embedded
  // with each possible prefix/suffix combination, including no prefix/suffix
  // returns a list of triplets [variant, i, j] where [i,j] is the start/end of the pattern, inclusive
  List<List> genPws(pattern, List prefixes, List suffixes) {
    // Insert an empty string in each list
    for (List lst in [prefixes, suffixes]) {
      if (lst.indexOf('') < 0) {
        lst.insert(0, '');
      }
    }
    List<List> result = [];
    for (String prefix in prefixes) {
      for (String suffix in suffixes) {
        result.add([prefix + pattern + suffix, prefix.length, prefix.length + pattern.length - 1]);
      }
    }
    return result;
  }
  ;

  checkFailed(Function callback, {String reason}) {
    bool success = false;
    try {
      callback();
      success = true;
    } catch (e) {}
    expect(success, isFalse, reason: reason);
  }

  checkMatches(String prefix, List<scoring.Match> matches, var patternNamesOrName, List<String> patterns,
      List<List<int>> ijs, List<scoring.Match> expectedMatches) {
    int i, j, k;
    DictionaryMatch match;
    String msg;
    String pattern;

    List<String> patternNames;
    // shortcut: if checking for a list of the same type of patterns,
    // allow passing a string 'pat' instead of array ['pat', 'pat', ...]
    if (patternNamesOrName is String) {
      patternNames = [];
      for (i = 0; i < patterns.length; i++) {
        patternNames.add(patternNamesOrName);
      }
    } else {
      patternNames = patternNamesOrName;
    }

    // Make sure the argument have the same length
    msg = 'unequal argument lists to check_matches';
    expect(patternNames.length, patterns.length, reason: msg);
    expect(patternNames.length, ijs.length, reason: msg);
    expect(patternNames.length, expectedMatches.length, reason: msg);

    expect(matches.length, patterns.length, reason: "${prefix}: matches.length == ${patterns.length}");
    for (k = 0; k < patterns.length; k++) {
      match = matches[k];
      String patternName = patternNames[k];
      pattern = patterns[k];
      var ij = ijs[k];
      i = ij[0];
      j = ij[1];
      expect(match.pattern, patternName, reason: "${prefix}: matches[${k}].pattern == '${patternName}'");
      expect([match.i, match.j], [i, j], reason: "${prefix}: matches[${k}] should have [i, j] of [${i}, ${j}]");
      expect(match.token, pattern, reason: "${prefix}: matches[${k}].token == '${pattern}'");

      // Check matching
      scoring.Match expectedMatch = expectedMatches[k];
      if (expectedMatch is DictionaryMatch) {
        if (expectedMatch.matchedWord != null) {
          expect(expectedMatch.matchedWord, match.matchedWord, reason: msg);
        }
        if (expectedMatch.rank != null) {
          expect(expectedMatch.rank, match.rank, reason: msg);
        }
        if (expectedMatch.dictionaryName != null) {
          expect(expectedMatch.dictionaryName, match.dictionaryName, reason: msg);
        }
      } else {
        throw "not supported yet";
      }
    }
  }
  ;

  test('genWps', () {
    // dart only test - not present in original implementation
    expect(genPws('word', ['pre'], ['post']), [
      ['word', 0, 3],
      ['wordpost', 0, 3],
      ['preword', 3, 6],
      ['prewordpost', 3, 6]
    ]);
    expect(genPws('word', ['pre1', 'pre2'], ['post1', 'post2']), [
      ['word', 0, 3],
      ['wordpost1', 0, 3],
      ['wordpost2', 0, 3],
      ['pre1word', 4, 7],
      ['pre1wordpost1', 4, 7],
      ['pre1wordpost2', 4, 7],
      ['pre2word', 4, 7],
      ['pre2wordpost1', 4, 7],
      ['pre2wordpost2', 4, 7]
    ]);
  });

  test('dictionary matching', () {
    //var dm, i, ijs, j, matches, msg, password, patterns, prefixes, suffixes, word;
    List<String> patterns;
    List<scoring.Match> matches;
    String msg;

    Map<String, Map<String, int>> testDicts = {
      "d1": {"motherboard": 1, "mother": 2, "board": 3, "abcd": 4, "cdef": 5},
      "d2": {'z': 1, '8': 2, '99': 3, r'$': 4, 'asdf1234&*': 5}
    };
    List<scoring.Match> dm(pw) {
      return dictionaryMatch(pw, testDicts);
    }
    ;
    matches = dm('motherboard');
    patterns = ['mother', 'motherboard', 'board'];
    msg = "matches words that contain other words";

    ndm(String matchedWord, int rank, String dictionaryName) =>
        new DictionaryMatch(matchedWord: matchedWord, rank: rank, dictionaryName: dictionaryName);

    checkMatches(msg, matches, 'dictionary', patterns, [
      [0, 5],
      [0, 10],
      [6, 10]
    ], [
      ndm('mother', 2, 'd1'),
      ndm('motherboard', 1, 'd1'),
      ndm('board', 3, 'd1')
    ]);
    // Check changing any of the expected parameters in the result make if failed in any solution
    checkFailed(() {
      checkMatches(msg, matches, 'dictionary', patterns, [
        [0, 5],
        [0, 10],
        [6, 10]
      ], [
        ndm('XXXXmother', 2, 'd1'),
        ndm('motherboard', 1, 'd1'),
        ndm('board', 3, 'd1')
      ]);
    });
    checkFailed(() {
      checkMatches(msg, matches, 'dictionary', patterns, [
        [0, 5],
        [0, 10],
        [6, 10]
      ], [
        ndm('mother', 2, 'd1'),
        ndm('motherboard', 1000000, 'd1'),
        ndm('board', 3, 'd1')
      ]);
    });
    checkFailed(() {
      checkMatches(msg, matches, 'dictionary', patterns, [
        [0, 5],
        [0, 10],
        [6, 10]
      ], [
        ndm('mother', 2, 'd1'),
        ndm('motherboard', 1, 'd1'),
        ndm('board', 3, 'XXXXd1')
      ]);
    });

    matches = dm('abcdef');
    patterns = ['abcd', 'cdef'];
    msg = "matches multiple words when they overlap";
    checkMatches(msg, matches, 'dictionary', patterns, [
      [0, 3],
      [2, 5]
    ], [
      ndm('abcd', 4, 'd1'),
      ndm('cdef', 5, 'd1')
    ]);

    matches = dm('BoaRdZ');
    patterns = ['BoaRd', 'Z'];
    msg = "ignores uppercasing";
    checkMatches(msg, matches, 'dictionary', patterns, [
      [0, 4],
      [5, 5]
    ], [
      ndm('board', 3, 'd1'),
      ndm('z', 1, 'd2')
    ]);

    List<String> prefixes = ['q', '%%'];
    List<String> suffixes = ['%', 'qq'];
    String word = 'asdf1234&*';

    List<List> pws = genPws(word, prefixes, suffixes);
    pws.forEach((List pwRow) {
      String password = pwRow[0];
      int i = pwRow[1];
      int j = pwRow[2];
      matches = dm(password);
      msg = "identifies words surrounded by non-words";
      checkMatches(msg, matches, 'dictionary', [
        word
      ], [
        [i, j]
      ], [
        ndm(word, 5, "d2")
      ]);
    });

    testDicts.forEach((String name, dict) {
      Map<String, int> dict = testDicts[name];
      dict.forEach((String word, int rank) {
        // skip words that contain others
        if (word != 'motherboard') {
          matches = dm(word);
          msg = "matches against all words in provided dictionaries";
          checkMatches(msg, matches, 'dictionary', [
            word
          ], [
            [0, word.length - 1]
          ], [
            ndm(word, rank, name)
          ]);
        }
      });
    });

    // test the default dictionaries
    matches = dictionaryMatch('rosebud');
    patterns = ['ros', 'rose', 'rosebud', 'bud'];
    List<List<int>> ijs = [
      [0, 2],
      [0, 3],
      [0, 6],
      [4, 6]
    ];
    msg = "default dictionaries";
    checkMatches(msg, matches, 'dictionary', patterns, ijs, [
      ndm(patterns[0], 13085, "surnames"),
      ndm(patterns[1], 65, "female_names"),
      ndm(patterns[2], 245, "passwords"),
      ndm(patterns[3], 786, "male_names")
    ]);
  });
}
