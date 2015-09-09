library xcvbnm.matching_test;

import 'package:test/test.dart';
import 'package:xcvbnm/src/matching.dart';
import "package:xcvbnm/src/scoring.dart" as scoring;

main() {
  test('matching utils', () {
    var chr_map,
    dividend,
    divisor,
    l,
    len2,
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
    n,
    o,
    obj,
    ref,
    ref1,
    ref2,
    ref3,
    ref4,
    ref5,
    ref6,
    ref7,
    remainder,
    result,
    string;
    expect(empty([]), isTrue, reason: ".empty returns true for an empty array");
    expect(empty({}), isTrue,
    reason: ".empty returns true for an empty object");

    for (var value in [
      [1],
      [1, 2],
      [[]],
      {"a": 1},
      {"0": {}}
    ]) {
      expect(empty(value), isFalse,
      reason: ".empty returns false for non-empty objects and arrays");
    }

    lst = [];
    extend(lst, []);
    expect(lst, [],
    reason: "extending an empty list with an empty list leaves it empty");
    extend(lst, [1]);
    expect(lst, [1],
    reason:
    "extending an empty list with another makes it equal to the other");
    extend(lst, [2, 3]);
    expect(lst, [1, 2, 3],
    reason:
    "extending a list with another adds each of the other's elements");
    ref1 = [
      [1],
      [2]
    ];
    lst1 = ref1[0];
    lst2 = ref1[1];
    extend(lst1, lst2);
    expect(lst2, [2],
    reason: "extending a list by another doesn't affect the other");
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
    expect(sorted([m1, m2, m3, m4, m5, m6]), [m4, m6, m5, m3, m1, m2],
    reason: msg);
  });

  genpws(pattern, prefixes, suffixes) {
    var i, j, l, len, len1, len2, lst, n, o, prefix, ref, ref1, result, suffix;
    prefixes = new List.from(prefixes);
    suffixes = new List.from(suffixes);
    ref = [prefixes, suffixes];
    len = ref.length;
    for (l = 0; l < len; l++) {
      List lst = ref[l];
      if (lst.indexOf('') < 0) {
        lst.insert(0, '');
      }
    }
    result = [];
    len1 = prefixes.length;
    for (n = 0; n < len1; n++) {
      prefix = prefixes[n];
      len2 = suffixes.length;
      for (o = 0; o < len2; o++) {
        suffix = suffixes[o];
        ref1 = [prefix.length, prefix.length + pattern.length - 1];
        i = ref1[0];
        j = ref1[1];
        result.add([prefix + pattern + suffix, i, j]);
      }
    }
    return result;
  }
  ;

  check_matches(prefix, List<scoring.Match> matches, pattern_names,
                List patterns, ijs, List<scoring.Match> expectedMatches) {
    var i,
    is_equal_len_args,
    j,
    k,
    l,
    lst,
    match,
    msg,
    pattern,
    pattern_name,
    prop,
    prop_list,
    prop_msg,
    prop_name,
    ref,
    ref1,
    ref2,
    results;
    if (pattern_names is String) {
      List result = [];
      for (i = 0; i < patterns.length; i++) {
        result.add(pattern_names);
      }
      pattern_names = result;
    }

    msg = prefix + ": matches.length == ${patterns.length}";
    expect(matches.length, patterns.length, reason: msg);
    results = [];
    for (k = 0; k < patterns.length; k++) {
      match = matches[k];
      pattern_name = pattern_names[k];
      pattern = patterns[k];
      ref2 = ijs[k];
      i = ref2[0];
      j = ref2[1];
      msg = prefix + ": matches[${k}].pattern == '" + pattern_name + "'";
      expect(match.pattern, pattern_name, reason: msg);
      msg = prefix + ": matches[${k}] should have [i, j] of [${i}, ${j}]";
      expect([match.i, match.j], [i, j], reason: msg);
      msg = prefix + ": matches[${k}].token == '" + pattern + "'";
      expect(match.token, pattern, reason: msg);

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
          expect(expectedMatch.dictionaryName, match.dictionaryName,
          reason: msg);
        }
      } else {
        throw "not supported yet";
      }

      /*
      props.forEach((prop_name, prop_list) {
        prop_msg = prop_list[k];
        if (prop_msg is String) {
          prop_msg = "'" + prop_msg + "'";
        }
        msg = prefix + ": matches[${k}].${prop_name} == ${prop_msg}";
        expect(match[prop_name], prop_list[k], reason: msg);
      });
      */
    }
  }
  ;

  test('dictionary matching', () {
    var dict,
    dm,
    i,
    ijs,
    j,
    l,
    len,
    matches,
    msg,
    name,
    password,
    patterns,
    prefixes,
    rank,
    ref,
    ref1,
    suffixes,
    word;

    Map<String, Map<String, int>> test_dicts = {
      "d1": {"motherboard": 1, "mother": 2, "board": 3, "abcd": 4, "cdef": 5},
      "d2": {'z': 1, '8': 2, '99': 3, r'$': 4, 'asdf1234&*': 5}
    };
    dm = (pw) {
      return dictionaryMatch(pw, test_dicts);
    };
    matches = dm('motherboard');
    patterns = ['mother', 'motherboard', 'board'];
    msg = "matches words that contain other words";

    ndm(String matchedWord, int rank, String dictionaryName) =>
    new DictionaryMatch(
        matchedWord: matchedWord,
        rank: rank,
        dictionaryName: dictionaryName);

    check_matches(msg, matches, 'dictionary', patterns, [
      [0, 5],
      [0, 10],
      [6, 10]
    ], [
      ndm('mother', 2, 'd1'),
      ndm('motherboard', 1, 'd1'),
      ndm('board', 3, 'd1')
    ]);

    matches = dm('abcdef');
    patterns = ['abcd', 'cdef'];
    msg = "matches multiple words when they overlap";
    check_matches(msg, matches, 'dictionary', patterns, [
      [0, 3],
      [2, 5]
    ], [
      ndm('abcd', 4, 'd1'),
      ndm('cdef', 5, 'd1')
    ]);

    matches = dm('BoaRdZ');
    patterns = ['BoaRd', 'Z'];
    msg = "ignores uppercasing";
    check_matches(msg, matches, 'dictionary', patterns, [
      [0, 4],
      [5, 5]
    ], [
      ndm('board', 3, 'd1'),
      ndm('z', 1, 'd2')
    ]);

    prefixes = ['q', '%%'];
    suffixes = ['%', 'qq'];
    word = 'asdf1234&*';

    ref = genpws(word, prefixes, suffixes);
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      password = ref1[0];
      i = ref1[1];
      j = ref1[2];
      matches = dm(password);
      msg = "identifies words surrounded by non-words";
      check_matches(msg, matches, 'dictionary', [
        word
      ], [
        [i, j]
      ], [
        ndm(word, 5, "d2")
      ]);
    }

    test_dicts.forEach((String name, dict) {
      Map<String, int> dict = test_dicts[name];
      dict.forEach((String word, int rank) {
        if (word != 'motherboard') {
          matches = dm(word);
          msg = "matches against all words in provided dictionaries";
          check_matches(msg, matches, 'dictionary', [
            word
          ], [
            [0, word.length - 1]
          ], [
            ndm(word, rank, name)
          ]);
        }
      });
    });

    matches = dictionaryMatch('rosebud');
    patterns = ['ros', 'rose', 'rosebud', 'bud'];
    ijs = [
      [0, 2],
      [0, 3],
      [0, 6],
      [4, 6]
    ];
    msg = "default dictionaries";
    check_matches(msg, matches, 'dictionary', patterns, ijs, [ndm(patterns[0], 13085, "surnames"),
    ndm(patterns[1], 65, "female_names"),
    ndm(patterns[2], 245, "passwords"),
    ndm(patterns[3], 786, "male_names")]
    );
  });
}
