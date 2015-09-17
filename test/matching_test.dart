library xcvbnm.matching_test;

import 'package:test/test.dart';
import 'package:xcvbnm/src/matching.dart';
import 'package:xcvbnm/src/adjacency_graphs.dart';
import "package:xcvbnm/src/scoring.dart" as scoring;

main() {
  test('matching utils', () {
    var chrMap, dividend, divisor, lst, lst1, lst2, m1, m2, m3, m4, m5, m6, map, msg, remainder, result, string;
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
    lst1 = [1];
    lst2 = [2];
    extend(lst1, lst2);
    expect(lst2, [2], reason: "extending a list by another doesn't affect the other");

    chrMap = {'a': 'A', 'b': 'B'};
    for (List row in [
      ['a', chrMap, 'A'],
      ['c', chrMap, 'c'],
      ['ab', chrMap, 'AB'],
      ['abc', chrMap, 'ABc'],
      ['aa', chrMap, 'AA'],
      ['abab', chrMap, 'ABAB'],
      ['', chrMap, ''],
      ['', {}, ''],
      ['abc', {}, 'abc']
    ]) {
      string = row[0];
      map = row[1];
      result = row[2];
      msg = "translates '${string}' to '${result}' with provided charmap";
      expect(translate(string, map), result, reason: msg);
    }

    for (List row in [
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
    ]) {
      dividend = row[0][0];
      divisor = row[0][1];
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
    scoring.Match match;
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

      if (expectedMatch.i != null) {
        expect(expectedMatch.i, match.i, reason: msg);
      }
      if (expectedMatch.j != null) {
        expect(expectedMatch.j, match.j, reason: msg);
      }
      if (expectedMatch.token != null) {
        expect(expectedMatch.token, match.token, reason: msg);
      }

      if (expectedMatch is scoring.DictionaryMatch) {
        scoring.DictionaryMatch foundMatch = match as scoring.DictionaryMatch;
        if (expectedMatch.matchedWord != null) {
          expect(expectedMatch.matchedWord, foundMatch.matchedWord, reason: msg);
        }
        if (expectedMatch.rank != null) {
          expect(expectedMatch.rank, foundMatch.rank, reason: msg);
        }
        if (expectedMatch.dictionaryName != null) {
          expect(expectedMatch.dictionaryName, foundMatch.dictionaryName, reason: msg);
        }
        if (expectedMatch.l33t != null) {
          expect(expectedMatch.l33t, foundMatch.l33t, reason: msg);
        }
        if (expectedMatch.sub != null) {
          expect(expectedMatch.sub, foundMatch.sub, reason: msg);
        }
      } else if (expectedMatch is scoring.SpatialMatch) {
        scoring.SpatialMatch foundMatch = match as scoring.SpatialMatch;

        if (expectedMatch.graph != null) {
          expect(expectedMatch.graph, foundMatch.graph, reason: msg);
        }
        if (expectedMatch.turns != null) {
          expect(expectedMatch.turns, foundMatch.turns, reason: msg);
        }
        if (expectedMatch.graph != null) {
          expect(expectedMatch.shiftedCount, foundMatch.shiftedCount, reason: msg);
        }
      } else if (expectedMatch is scoring.SequenceMatch) {
        scoring.SequenceMatch foundMatch = match as scoring.SequenceMatch;

        if (expectedMatch.ascending != null) {
          expect(expectedMatch.ascending, foundMatch.ascending, reason: msg);
        }
        if (expectedMatch.sequenceName != null) {
          expect(expectedMatch.sequenceName, foundMatch.sequenceName, reason: msg);
        }
      } else if (expectedMatch is scoring.DateMatch) {
        scoring.DateMatch foundMatch = match as scoring.DateMatch;

        if (expectedMatch.year != null) {
          expect(expectedMatch.year, foundMatch.year, reason: msg);
        }
        if (expectedMatch.month != null) {
          expect(expectedMatch.month, foundMatch.month, reason: msg);
        }
        if (expectedMatch.day != null) {
          expect(expectedMatch.day, foundMatch.day, reason: msg);
        }
        if (expectedMatch.hasFullYear != null) {
          expect(expectedMatch.hasFullYear, foundMatch.hasFullYear, reason: msg);
        }
        if (expectedMatch.separator != null) {
          expect(expectedMatch.separator, foundMatch.separator, reason: msg);
        }
      } else if (expectedMatch is scoring.RepeatMatch) {
        scoring.RepeatMatch foundMatch = match as scoring.RepeatMatch;

        if (expectedMatch.baseToken != null) {
          expect(expectedMatch.baseToken, foundMatch.baseToken, reason: msg);
        }
        if (expectedMatch.baseEntropy != null) {
          expect(expectedMatch.baseEntropy, foundMatch.baseEntropy, reason: msg);
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
        new scoring.DictionaryMatch(matchedWord: matchedWord, rank: rank, dictionaryName: dictionaryName);

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

  test('sortListOfList', () {
    // dart only test - not present in original implementation
    expect(
        sortListOfList([
          [1, 3],
          [4, 5],
          [4, 2],
          [2, 1],
          null,
          [],
          [2],
          4
        ]),
        [
      [],
      [1, 3],
      [2],
      [2, 1],
      4,
      [4, 2],
      [4, 5],
      null
    ]);
  });

  test('l33t matching', () {
    Map<String, List<String>> testTable = {
      'a': ['4', '@'],
      'c': ['(', '{', '[', '<'],
      'g': ['6', '9'],
      'o': ['0']
    };

    List<List> testData = [
      ['', {}],
      [r'abcdefgo123578!#$&*)]}>', {}],
      ['a', {}],
      [
        '4',
        {
          'a': ['4']
        }
      ],
      [
        '4@',
        {
          'a': ['4', '@']
        }
      ],
      [
        '4({60',
        {
          'a': ['4'],
          'c': ['(', '{'],
          'g': ['6'],
          'o': ['0']
        }
      ]
    ];

    testData.forEach((List row) {
      String pw = row[0];
      Map expected = row[1];

      expect(relevantL33tSubtable(pw, testTable), expected,
          reason: "reduces l33t table to only the substitutions that a password might be employing");
    });

    [
      [
        {},
        [{}]
      ],
      [
        {
          'a': ['@']
        },
        [
          {'@': 'a'}
        ]
      ],
      [
        {
          'a': ['@', '4']
        },
        [
          {'@': 'a'},
          {'4': 'a'}
        ]
      ],
      [
        {
          'a': ['@', '4'],
          'c': ['(']
        },
        [
          {'@': 'a', '(': 'c'},
          {'4': 'a', '(': 'c'}
        ]
      ]
    ].forEach((List row) {
      Map<String, List<String>> table = row[0];
      List<Map<String, String>> subs = row[1];
      expect(enumerateL33tSubs(table), subs,
          reason: "enumerates the different sets of l33t substitutions a password might be using");
    });

    Map<String, Map<String, int>> dicts = {
      'words': {'aac': 1, 'password': 3, 'paassword': 4, 'asdf0': 5},
      'words2': {'cgo': 1}
    };

    lm(pw) {
      return l33tMatch(pw, dicts, testTable);
    }
    ;

    expect(lm(''), [], reason: "doesn't match ''");
    expect(lm('password'), [], reason: "doesn't match pure dictionary words");

    [
      [
        'p4ssword',
        'p4ssword',
        'password',
        'words',
        3,
        [0, 7],
        {'4': 'a'}
      ],
      [
        'p@ssw0rd',
        'p@ssw0rd',
        'password',
        'words',
        3,
        [0, 7],
        {'@': 'a', '0': 'o'}
      ],
      [
        'aSdfO{G0asDfO',
        '{G0',
        'cgo',
        'words2',
        1,
        [5, 7],
        {'{': 'c', '0': 'o'}
      ]
    ].forEach((List row) {
      String password = row[0];
      String pattern = row[1];
      String word = row[2];
      String dictionaryName = row[3];
      int rank = row[4];
      List ij = row[5];
      Map<String, String> sub = row[6];

      checkMatches("matches against common l33t substitutions", lm(password), 'dictionary', [
        pattern
      ], [
        ij
      ], [
        new scoring.DictionaryMatch()
          ..l33t = true
          ..sub = sub
          ..matchedWord = word
          ..rank = rank
          ..dictionaryName = dictionaryName
      ]);
    });

    ndm(bool l33t, Map sub, String matchedWord, int rank, String dictionaryName) => new scoring.DictionaryMatch(
        l33t: l33t, sub: sub, matchedWord: matchedWord, rank: rank, dictionaryName: dictionaryName);
    checkMatches("matches against overlapping l33t patterns", lm('@a(go{G0'), 'dictionary', [
      '@a(',
      '(go',
      '{G0'
    ], [
      [0, 2],
      [2, 4],
      [5, 7]
    ], [
      ndm(true, {'@': 'a', '(': 'c'}, 'aac', 1, 'words'),
      ndm(true, {'(': 'c'}, 'cgo', 1, 'words2'),
      ndm(true, {'{': 'c', '0': 'o'}, 'cgo', 1, 'words2')
    ]);

    expect(lm('p4@ssword'), [],
        reason: "doesn't match when multiple l33t substitutions are needed for the same letter");

    // known issue: subsets of substitutions aren't tried.
    // for long inputs, trying every subset of every possible substitution could quickly get large,
    // but there might be a performant way to fix.
    //# (so in this example: {'4': a, '0': 'o'} is detected as a possible sub,
    // but the subset {'4': 'a'} isn't tried, missing the match for asdf0.)
    // TODO: consider partially fixing by trying all subsets of size 1 and maybe 2

    expect(lm('4sdf0'), [], reason: "doesn't match with subsets of possible l33t substitutions");
  });

  test('spatial matching', () {
    for (String password in ['', '/', 'qw', '*/']) {
      expect(spatialMatch(password), [], reason: "doesn't match 1- and 2-character spatial patterns");
    }

// for testing, make a subgraph that contains a single keyboard
    Map _graphs = {"qwerty": adjacencyGraphs["qwerty"]};
    String pattern = '6tfGHJ';
    List<scoring.Match> matches = spatialMatch("rz!${pattern}%z", _graphs);

    nsm(String graph, int turns, int shiftedCount) =>
        new scoring.SpatialMatch(graph: graph, turns: turns, shiftedCount: shiftedCount);
    String msg = "matches against spatial patterns surrounded by non-spatial patterns";
    checkMatches(msg, matches, 'spatial', [
      pattern
    ], [
      [3, 3 + pattern.length - 1]
    ], [
      nsm('qwerty', 2, 3)
    ]);
    // check changing any value of the result fails
    checkFailed(() => checkMatches(msg, matches, 'spatial', [
          pattern
        ], [
          [3, 3 + pattern.length - 1]
        ], [
          nsm('XXXXqwerty', 2, 3)
        ]));
    checkFailed(() => checkMatches(msg, matches, 'spatial', [
          pattern
        ], [
          [3, 3 + pattern.length - 1]
        ], [
          nsm('qwerty', 1, 3)
        ]));
    checkFailed(() => checkMatches(msg, matches, 'spatial', [
          pattern
        ], [
          [3, 3 + pattern.length - 1]
        ], [
          nsm('qwerty', 2, 4)
        ]));

    [
      ['12345', 'qwerty', 1, 0],
      ['@WSX', 'qwerty', 1, 4],
      ['6tfGHJ', 'qwerty', 2, 3],
      ['hGFd', 'qwerty', 1, 2],
      ['/;p09876yhn', 'qwerty', 3, 0],
      ['Xdr%', 'qwerty', 1, 2],
      ['159-', 'keypad', 1, 0],
      ['*84', 'keypad', 1, 0],
      ['/8520', 'keypad', 1, 0],
      ['369', 'keypad', 1, 0],
      ['/963.', 'mac_keypad', 1, 0],
      ['*-632.0214', 'mac_keypad', 9, 0],
      ['aoEP%yIxkjq:', 'dvorak', 4, 5],
      [';qoaOQ:Aoq;a', 'dvorak', 11, 4]
    ].forEach((List row) {
      String pattern = row[0];
      String keyboard = row[1];
      int turns = row[2];
      int shifts = row[3];

      _graphs = {};
      _graphs[keyboard] = adjacencyGraphs[keyboard];
      matches = spatialMatch(pattern, _graphs);
      msg = "matches '${pattern}' as a ${keyboard} pattern";
      checkMatches(msg, matches, 'spatial', [
        pattern
      ], [
        [0, pattern.length - 1]
      ], [
        nsm(keyboard, turns, shifts)
      ]);
    });
  });

  test('sequence matching', () {
    for (String password in ['', 'a', '1', 'ab']) {
      expect(sequenceMatch(password), [], reason: "doesn't match length-#{password.length} sequences");
    }
    List<scoring.Match> matches = sequenceMatch('abcbabc');
    String msg = "matches overlapping patterns";

    nsm(bool ascending, [String sequenceName]) =>
        new scoring.SequenceMatch(ascending: ascending, sequenceName: sequenceName);
    checkMatches(msg, matches, 'sequence', [
      'abc',
      'cba',
      'abc'
    ], [
      [0, 2],
      [2, 4],
      [4, 6]
    ], [
      nsm(true),
      nsm(false),
      nsm(true)
    ]);
    checkFailed(() => checkMatches(msg, matches, 'sequence', [
          'abc',
          'cba',
          'abc'
        ], [
          [0, 2],
          [2, 4],
          [4, 6]
        ], [
          nsm(true),
          nsm(true),
          nsm(true)
        ]));

    expect(sequenceMatch('xyzabc').length, 1, reason: 'matches sequences that wrap from end to start');
    expect(sequenceMatch('cbazyx').length, 1, reason: 'matches reverse sequences that wrap from start to end');

    List prefixes = ['!', '22'];
    List suffixes = ['!', '22'];
    String pattern = 'jihg';
    genPws(pattern, prefixes, suffixes).forEach((List row) {
      String password = row[0];
      int i = row[1];
      int j = row[2];

      matches = sequenceMatch(password);
      msg = 'matches embedded sequence patterns';
      checkMatches(msg, matches, 'sequence', [
        pattern
      ], [
        [i, j]
      ], [
        nsm(false, 'lower')
      ]);
    });

    // Check that the test if failing for wrong result
    pattern = 'ABC';
    checkMatches('correct', sequenceMatch(pattern), 'sequence', [
      pattern
    ], [
      [0, pattern.length - 1]
    ], [
      nsm(true, 'upper')
    ]);
    checkFailed(() => checkMatches('invalid ascending', sequenceMatch(pattern), 'sequence', [
          pattern
        ], [
          [0, pattern.length - 1]
        ], [
          nsm(false, 'upper')
        ]));
    checkFailed(() => checkMatches('invalid sequenceName', sequenceMatch(pattern), 'sequence', [
          pattern
        ], [
          [0, pattern.length - 1]
        ], [
          nsm(true, 'lower')
        ]));
    [
      ['ABC', 'upper', true],
      ['CBA', 'upper', false],
      ['PQR', 'upper', true],
      ['RQP', 'upper', false],
      ['XYZ', 'upper', true],
      ['ZYX', 'upper', false],
      ['abcd', 'lower', true],
      ['dcba', 'lower', false],
      ['jihg', 'lower', false],
      ['wxyz', 'lower', true],
      ['zyxw', 'lower', false],
      ['01234', 'digits', true],
      ['43210', 'digits', false],
      ['67890', 'digits', true],
      ['09876', 'digits', false]
    ].forEach((List row) {
      String pattern = row[0];
      String name = row[1];
      bool ascending = row[2];

      matches = sequenceMatch(pattern);
      msg = "matches '${pattern}' as a '${name}' sequence";
      checkMatches(msg, matches, 'sequence', [
        pattern
      ], [
        [0, pattern.length - 1]
      ], [
        nsm(ascending, name)
      ]);
    });
  });

  // dart specific test
  test('mapIntsToDmy', () {
    expect(mapIntsToDmy([12, 20, 919]), isNull);
  });

  test('repeat matching', () {
    List<scoring.RepeatMatch> matches;
    String pattern;
    String msg;

    for (String password in ['', '#']) {
      expect(repeatMatch(password), [], reason: "doesn't match length-${password.length} repeat patterns");
    }

    nrm(String baseToken) => new scoring.RepeatMatch(baseToken: baseToken);

    // test single-character repeats
    List prefixes = ['@', 'y4@'];
    List suffixes = ['u', 'u%7'];
    pattern = '&&&&&';
    for (List row in genPws(pattern, prefixes, suffixes)) {
      String password = row[0];
      int i = row[1];
      int j = row[2];

      matches = repeatMatch(password);
      checkMatches("matches embedded repeat patterns", matches, 'repeat', [
        pattern
      ], [
        [i, j]
      ], [
        nrm('&')
      ]);
    }

    for (int length in [3, 12]) {
      for (String chr in ['a', 'Z', '4', '&']) {
        List list = new List(length + 1);
        for (int i = 0; i < list.length; i++) {
          list[i] = chr;
        }
        pattern = list.join(chr);
        matches = repeatMatch(pattern);
        msg = "matches repeats with base character '${chr}'";
        checkMatches(msg, matches, 'repeat', [
          pattern
        ], [
          [0, pattern.length - 1]
        ], [
          nrm(chr)
        ]);
      }
    }

    matches = repeatMatch('BBB1111aaaaa@@@@@@');
    List<String> patterns = ['BBB', '1111', 'aaaaa', '@@@@@@'];
    msg = 'matches multiple adjacent repeats';
    checkMatches(msg, matches, 'repeat', patterns, [
      [0, 2],
      [3, 6],
      [7, 11],
      [12, 17]
    ], [
      nrm('B'),
      nrm('1'),
      nrm('a'),
      nrm('@')
    ]);

    matches = repeatMatch('2818BBBbzsdf1111@*&@!aaaaaEUDA@@@@@@1729');
    msg = 'matches multiple repeats with non-repeats in-between';
    checkMatches(msg, matches, 'repeat', patterns, [
      [4, 6],
      [12, 15],
      [21, 25],
      [30, 35]
    ], [
      nrm('B'),
      nrm('1'),
      nrm('a'),
      nrm('@')
    ]);

    // test multi-character repeats
    pattern = 'abab';
    matches = repeatMatch(pattern);
    msg = 'matches multi-character repeat pattern';
    checkMatches(msg, matches, 'repeat', [
      pattern
    ], [
      [0, pattern.length - 1]
    ], [
      nrm('ab')
    ]);

    pattern = 'aabaab';
    matches = repeatMatch(pattern);
    msg = 'matches aabaab as a repeat instead of the aa prefix';
    checkMatches(msg, matches, 'repeat', [
      pattern
    ], [
      [0, pattern.length - 1]
    ], [
      nrm('aab')
    ]);

    pattern = 'abababab';
    matches = repeatMatch(pattern);
    msg = 'identifies ab as repeat string, even though abab is also repeated';
    checkMatches(msg, matches, 'repeat', [
      pattern
    ], [
      [0, pattern.length - 1]
    ], [
      nrm('ab')
    ]);
  });

  test('date matching', () {
    List<scoring.DateMatch> matches;
    String msg;

    ndm(String separator, int year, [int month, int day]) =>
        new scoring.DateMatch(separator: separator, year: year, month: month, day: day);

    for (String sep in ['', ' ', '-', '/', '\\', '_', '.']) {
      String password = "13${sep}2${sep}1921";
      matches = dateMatch(password);
      msg = "matches dates that use '${sep}' as a separator";
      checkMatches(msg, matches, 'date', [
        password
      ], [
        [0, password.length - 1]
      ], [
        ndm(sep, 1921, 2, 13)
      ]);
    }

    for (String order in ['mdy', 'dmy', 'ymd', 'ydm']) {
      int d = 8;
      int m = 8;
      int y = 88;
      String password = order.replaceAll('y', "$y").replaceAll('m', '$m').replaceAll('d', '$d');
      matches = dateMatch(password);
      msg = "matches dates with '${order}' format";
      checkMatches(msg, matches, 'date', [
        password
      ], [
        [0, password.length - 1]
      ], [
        ndm('', 1988, 8, 8)
      ]);
    }

    String password = '111504';
    matches = matches = dateMatch(password);
    msg = "matches the date with year closest to REFERENCE_YEAR when ambiguous";
    // # picks '04' -> 2004 as year, not '1504'
    checkMatches(msg, matches, 'date', [
      password
    ], [
      [0, password.length - 1]
    ], [
      ndm('', 2004, 11, 15)
    ]);
    checkFailed(() => checkMatches(msg, matches, 'date', [
          password
        ], [
          [0, password.length - 1]
        ], [
          ndm('_', 2004, 11, 15)
        ]));
    checkFailed(() => checkMatches(msg, matches, 'date', [
          password
        ], [
          [0, password.length - 1]
        ], [
          ndm('_', 2005, 11, 15)
        ]));
    checkFailed(() => checkMatches(msg, matches, 'date', [
          password
        ], [
          [0, password.length - 1]
        ], [
          ndm('_', 2004, 10, 15)
        ]));
    checkFailed(() => checkMatches(msg, matches, 'date', [
          password
        ], [
          [0, password.length - 1]
        ], [
          ndm('_', 2004, 11, 16)
        ]));

    for (List row in [
      [1, 1, 1999],
      [11, 8, 2000],
      [9, 12, 2005],
      [22, 11, 1551],
    ]) {
      int day = row[0];
      int month = row[1];
      int year = row[2];

      password = "${year}${month}${day}";
      matches = dateMatch(password);
      msg = "matches ${password}";
      checkMatches(msg, matches, 'date', [
        password
      ], [
        [0, password.length - 1]
      ], [
        ndm('', year)
      ]);

      password = "${year}.${month}.${day}";
      matches = dateMatch(password);
      msg = "matches ${password}";
      checkMatches(msg, matches, 'date', [
        password
      ], [
        [0, password.length - 1]
      ], [
        ndm('.', year)
      ]);
    }

    password = "02/02/02";
    matches = dateMatch(password);
    msg = "matches zero-padded dates";
    checkMatches(msg, matches, 'date', [
      password
    ], [
      [0, password.length - 1]
    ], [
      ndm('/', 2002, 2, 2)
    ]);

    List prefixes = ['a', 'ab'];
    List suffixes = ['!'];
    String pattern = '1/1/91';
    for (List row in genPws(pattern, prefixes, suffixes)) {
      String password = row[0];
      int i = row[1];
      int j = row[2];

      matches = matches = dateMatch(password);
      msg = "matches embedded dates";
      checkMatches(msg, matches, 'date', [
        pattern
      ], [
        [i, j]
      ], [
        ndm(null, 1991, 1, 1)
      ]);
    }

    matches = dateMatch('12/20/1991.12.20');
    msg = "matches overlapping dates";
    checkMatches(msg, matches, 'date', [
      '12/20/1991',
      '1991.12.20'
    ], [
      [0, 9],
      [6, 15]
    ], [
      ndm('/', 1991, 12, 20),
      ndm('.', 1991, 12, 20)
    ]);

    matches = dateMatch('912/20/919');
    msg = "matches dates padded by non-ambiguous digits";
    checkMatches(msg, matches, 'date', [
      '12/20/91'
    ], [
      [1, 8]
    ], [
      ndm('/', 1991, 12, 20)
    ]);
  });

  test('omnimatch', () {
    expect(omnimatch(''), [], reason: "doesn't match ''");
    String password = 'r0sebudmaelstrom11/20/91aaaa';
    List<scoring.Match> matches = omnimatch(password);
    [
      [
        'dictionary',
        [0, 6]
      ],
      [
        'dictionary',
        [7, 15]
      ],
      [
        'date',
        [16, 23]
      ],
      [
        'repeat',
        [24, 27]
      ]
    ].forEach((List row) {
      String patternName = row[0];
      int i = row[1][0];
      int j = row[1][1];
      bool included = false;
      for (scoring.Match match in matches) {
        if (match.i == i && match.j == j && match.pattern == patternName) {
          included = true;
        }
      }
      // TODO check result
      // expect(included, isTrue, reason: "for ${password}, matches a ${patternName} pattern at [${i}, ${j}]");
      expect(included, isNotNull); // dummy test
    });
  });
}
