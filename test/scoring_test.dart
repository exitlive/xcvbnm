library xcvbnm.scoring_test;

import 'package:test/test.dart';
import 'dart:math' as math;
import 'package:xcvbnm/src/scoring.dart';
import 'package:xcvbnm/src/matching.dart' as matching;
import 'package:xcvbnm/src/xcvbnm_common.dart' as xcvbnm;
import 'dart:core' hide Match;

main() {
  const num epsilon = 1e-10;

  test('nCk', () {
    var k, n, result;
    for (List row in [
      [0, 0, 1],
      [1, 0, 1],
      [5, 0, 1],
      [0, 1, 0],
      [0, 5, 0],
      [2, 1, 2],
      [4, 2, 6],
      [33, 7, 4272048]
    ]) {
      n = row[0];
      k = row[1];
      result = row[2];
      expect(nCk(n, k), result);
    }
    n = 49;
    k = 12;
    expect(nCk(n, k), nCk(n, n - k), reason: "mirror identity");
    expect(nCk(n, k), nCk(n - 1, k - 1) + nCk(n - 1, k), reason: "pascal's triangle identity");
  });

  test('lg', () {
    var n, p, result;
    for (List row in [
      [1, 0],
      [2, 1],
      [4, 2],
      [32, 5]
    ]) {
      n = row[0];
      result = row[1];
      expect(lg(n), result);
    }
    n = 17;
    p = 4;
    expect(lg(n * p), closeTo(lg(n) + lg(p), epsilon), reason: "product rule");
    expect(lg(n / p), closeTo(lg(n) - lg(p), epsilon), reason: "quotient rule");
    expect(lg(10), closeTo(1 / (math.log(2) / math.LN10), epsilon), reason: "base switch rule");
    expect(lg(math.pow(n, p)), closeTo(p * lg(n), epsilon), reason: "power rule");
    expect(lg(n), closeTo(math.log(n) / math.log(2), epsilon), reason: "base change rule");
  });

  test('entropyToCrackTime', () {
    List e = [];
    for (int n in [0, 1, 7, 60]) {
      e.add(entropyToCrackTime(n));
    }
    expect(e[0] < e[1] && e[1] < e[2] && e[2] < e[3], isTrue, reason: "monotonically increasing");
    for (var en in e) {
      expect(en, greaterThan(0), reason: "always positive");
    }
  });

  test('crackTimeToScore', () {
    for (List row in [
      [0, 0],
      [10, 0],
      [math.pow(10, 9), 4]
    ]) {
      var seconds = row[0];
      var score = row[1];
      expect(crackTimeToScore(seconds), score, reason: "crack time of ${seconds} seconds has score of ${score}");
    }
  });

  test('calcBruteforceCardinality', () {
    for (List row in [
      // beginning / middle / end of lowers range
      ['a', 26],
      ['h', 26],
      ['z', 26],
      // sample from each other character group
      ['Q', 26],
      ['0', 10],
      ['9', 10],
      ['\$', 33],
      ['£', 64],
      ['å', 64],
      // unicode
      ['α', 40],
      ['αβ', 40],
      ['Ϫα', 58],
      ['好', 40],
      ['信息论', 100],
      // combinations
      ['a\$', 59],
      ['aQ£', 116],
      ['9Z9Z', 36],
      ['«信息论»', 164]
    ]) {
      String str = row[0];
      int cardinality = row[1];
      expect(calcBruteforceCardinality(str), cardinality, reason: "cardinality of ${str} is ${cardinality}");
    }
  });

  test('displayTime', () {
    for (List row in [
      [0, '0 seconds'],
      [1, '1 second'],
      [1, '1 second'],
      [32, '32 seconds'],
      [60, '1 minute'],
      [121, '2 minutes'],
      [3600, '1 hour'],
      [2 * 3600 * 24 + 5, '2 days'],
      [1 * 3600 * 24 * 31 + 4000, '1 month'],
      [99 * 3600 * 24 * 31 * 12, '99 years'],
      [math.pow(10, 10), 'centuries']
    ]) {
      num seconds = row[0];
      String display = row[1];
      expect(displayTime(seconds), display, reason: "${seconds} seconds has a display time of ${display}");
    }
  });

  test('minimumEntropySearch', () {
    var cardinality, expected, m0, m1, m2, matches, password, ref, ref1, ref2, ref3, ref4;
    Function msg;

    Match m(i, j, entropy) {
      return new Match()
        ..i = i
        ..j = j
        ..entropy = entropy;
    }
    password = '0123456789';
    cardinality = 10;

    msg = (s) {
      return "returns one bruteforce match given an empty match sequence: " + s;
    };
    xcvbnm.Result result = minimumEntropyMatchSequence(password, []);
    expect(result.matchSequence.length, 1, reason: msg("result.length == 1"));

    m0 = result.matchSequence[0];
    expect(m0.pattern, 'bruteforce', reason: msg("match.pattern == 'bruteforce'"));
    expect(m0.token, password, reason: msg("match.token == " + password));
    expect(m0.cardinality, cardinality, reason: msg("match.cardinality == ${cardinality}"));
    expected = (lg(math.pow(cardinality, password.length))).round();
    expect((result.entropy).round(), expected, reason: msg("total entropy == ${expected}"));
    expect((m0.entropy).round(), expected, reason: msg("match entropy == ${expected}"));
    expect([m0.i, m0.j], [0, 9], reason: msg("[i, j] == [${m0.i}, ${m0.j}]"));
    msg = (s) {
      return "returns match + bruteforce when match covers a prefix of password: " + s;
    };

    ref = [m(0, 5, 1)];
    m0 = ref[0];
    matches = ref;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.matchSequence.length, 2, reason: msg("result.match.sequence.length == 2"));
    expect(result.matchSequence[0], m0, reason: msg("first match is the provided match object"));
    m1 = result.matchSequence[1];
    expect(m1.pattern, 'bruteforce', reason: msg("second match is bruteforce"));
    expect([m1.i, m1.j], [6, 9], reason: msg("second match covers full suffix after first match"));
    msg = (s) {
      return "returns bruteforce + match when match covers a suffix: " + s;
    };

    ref1 = [m(3, 9, 1)];
    m1 = ref1[0];
    matches = ref1;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.matchSequence.length, 2, reason: msg("result.match.sequence.length == 2"));
    m0 = result.matchSequence[0];
    expect(m0.pattern, 'bruteforce', reason: msg("first match is bruteforce"));
    expect([m0.i, m0.j], [0, 2], reason: msg("first match covers full prefix before second match"));
    expect(result.matchSequence[1], m1, reason: msg("second match is the provided match object"));

    msg = (s) {
      return "returns bruteforce + match + bruteforce when match covers an infix: " + s;
    };
    ref2 = [m(1, 8, 1)];
    m1 = ref2[0];
    matches = ref2;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.matchSequence.length, 3, reason: msg("result.length == 3"));
    expect(result.matchSequence[1], m1, reason: msg("middle match is the provided match object"));
    m0 = result.matchSequence[0];
    m2 = result.matchSequence[2];
    expect(m0.pattern, 'bruteforce', reason: msg("first match is bruteforce"));
    expect(m2.pattern, 'bruteforce', reason: msg("third match is bruteforce"));
    expect([m0.i, m0.j], [0, 0], reason: msg("first match covers full prefix before second match"));
    expect([m2.i, m2.j], [9, 9], reason: msg("third match covers full suffix after second match"));

    msg = (s) {
      return "chooses lower-entropy match given two matches of the same span: " + s;
    };
    ref3 = [m(0, 9, 1), m(0, 9, 2)];
    m0 = ref3[0];
    m1 = ref3[1];
    matches = ref3;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.matchSequence.length, 1, reason: msg("result.length == 1"));
    expect(result.matchSequence[0], m0, reason: msg("result.match_sequence[0] == m0"));

    m0.entropy = 3;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.matchSequence.length, 1, reason: msg("result.length == 1"));
    expect(result.matchSequence[0], m1, reason: msg("result.match_sequence[0] == m1"));

    msg = (s) {
      return "when m0 covers m1 and m2, choose [m0] when m0 < m1 + m2: " + s;
    };
    ref4 = [m(0, 9, 1), m(0, 3, 1), m(4, 9, 1)];
    m0 = ref4[0];
    m1 = ref4[1];
    m2 = ref4[2];
    matches = ref4;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.entropy, 1, reason: msg("total entropy == 1"));
    expect(result.matchSequence, [m0], reason: msg("match_sequence is [m0]"));

    msg = (s) {
      return "when m0 covers m1 and m2, choose [m1, m2] when m0 > m1 + m2: " + s;
    };
    m0.entropy = 3;
    result = minimumEntropyMatchSequence(password, matches);
    expect(result.entropy, 2, reason: msg("total entropy == 2"));
    expect(result.matchSequence, [m1, m2], reason: msg("match_sequence is [m1, m2]"));
  });

  test('calcEntropy', () {
    var match, msg;
    match = new Match()..entropy = 1;
    expect(calcEntropy(match), 1, reason: "calc_entropy returns cached entropy when available");
    match = new DateMatch(year: 1977, month: 7, day: 14);
    msg = "calc_entropy delegates based on pattern";
    expect(calcEntropy(match), dateEntropy(match), reason: msg);
  });

  test('repeatEntropy', () {
    for (List row in [
      ['aa', 'a'],
      ['999', '9'],
      [r'$$$$', r'$'],
      ['abab', 'ab'],
      ['batterystaplebatterystaplebatterystaple', 'batterystaple']
    ]) {
      String token = row[0];
      String baseToken = row[1];

      num baseEntropy = minimumEntropyMatchSequence(baseToken, matching.omnimatch(baseToken)).entropy;

      RepeatMatch match = new RepeatMatch(token: token, baseToken: baseToken, baseEntropy: baseEntropy);
      num expectedEntropy = baseEntropy + lg(match.token.length / match.baseToken.length);
      expect(repeatEntropy(match), expectedEntropy,
          reason: "the repeat pattern '${token}' has entropy of ${expectedEntropy}");
    }
  });

  test('sequenceEntropy', () {
    for (List row in [
      ['ab', true, 2 + lg(2)],
      ['XYZ', true, lg(26) + 1 + lg(3)],
      ['4567', true, lg(10) + lg(4)],
      ['7654', false, lg(10) + lg(4) + 1],
      ['ZYX', false, 2 + lg(3) + 1]
    ]) {
      String token = row[0];
      bool ascending = row[1];
      num entropy = row[2];
      SequenceMatch match = new SequenceMatch(token: token, ascending: ascending);
      expect(sequenceEntropy(match), entropy, reason: "the sequence pattern '${token}' has entropy of ${entropy}");
    }
  });

  test('regexEntropy', () {
    var match;

    match = new RegexMatch(token: 'aizocdk', regexName: 'alpha_lower', regexMatch: ['aizocdk']);
    expect(regexEntropy(match), lg(math.pow(26, 7)));

    match = new RegexMatch(token: 'ag7C8', regexName: 'alphanumeric', regexMatch: ['ag7C8']);
    expect(regexEntropy(match), lg(math.pow(2 * 26 + 10, 5)));

    match = new RegexMatch(token: '1972', regexName: 'recent_year', regexMatch: ['1972']);
    expect(regexEntropy(match), lg(referenceYear - 1972));

    match = new RegexMatch(token: '1992', regexName: 'recent_year', regexMatch: ['1992']);
    expect(regexEntropy(match), lg(minYearSpace));
  });

  test('dateEntropy', () {
    var match, msg;
    match = new DateMatch(token: '1123', separator: '', hasFullYear: false, year: 1923, month: 1, day: 1);
    msg = "entropy for ${match.token} is lg days * months * distance_from_ref_year";
    expect(dateEntropy(match), lg(12 * 31 * (referenceYear - match.year)), reason: msg);

    match = new DateMatch(token: '1/1/2010', separator: '/', hasFullYear: true, year: 2010, month: 1, day: 1);
    msg = "recent years assume MIN_YEAR_SPACE. extra entropy is added for separators and a 4-digit year.";
    expect(dateEntropy(match), lg(12 * 31 * minYearSpace) + 2 + 1, reason: msg);
  });

  test('_calcAverageDegree', () {
    expect(keyboardAverageDegree, closeTo(4.595744680851064, epsilon));
    expect(keyboardStartingPositions, 94);
    expect(keypadAverageDegree, closeTo(5.066666666666666, epsilon));
    expect(keypadStartingPositions, 15);
  });

  test('spatialEntropy', () {
    var L, base_entropy, d, entropy, i, j, l, msg, o, possibilities, ref, ref1, s, shifted_entropy;
    SpatialMatch match = new SpatialMatch(token: 'zxcvbn', graph: 'qwerty', turns: 1, shiftedCount: 0);
    base_entropy = lg(keyboardStartingPositions * keyboardAverageDegree * (match.token.length - 1));
    msg = "with no turns or shifts, entropy is lg(starts * degree * (len-1))";
    expect(spatialEntropy(match), base_entropy, reason: msg);

    match.entropy = null;
    match.token = 'ZxCvbn';
    match.shiftedCount = 2;
    shifted_entropy = base_entropy + lg(nCk(6, 2) + nCk(6, 1));
    msg = "entropy is added for shifted keys, similar to capitals in dictionary matching";
    expect(spatialEntropy(match), shifted_entropy, reason: msg);
    match.entropy = null;
    match.token = 'ZXCVBN';
    match.shiftedCount = 6;
    shifted_entropy = base_entropy + 1;
    msg = "when everything is shifted, only 1 bit is added";
    expect(spatialEntropy(match), shifted_entropy, reason: msg);
    match = new SpatialMatch(token: 'zxcft6yh', graph: 'qwerty', turns: 3, shiftedCount: 0);

    possibilities = 0;
    L = match.token.length;
    s = keyboardStartingPositions;
    d = keyboardAverageDegree;
    i = 2;
    ref = L;
    for (l = 2; 2 <= ref ? l <= ref : l >= ref; i = 2 <= ref ? ++l : --l) {
      j = 1;
      ref1 = math.min(match.turns, i - 1);
      for (o = 1; 1 <= ref1 ? o <= ref1 : o >= ref1; j = 1 <= ref1 ? ++o : --o) {
        possibilities += nCk(i - 1, j - 1) * s * math.pow(d, j);
      }
    }
    entropy = lg(possibilities);
    msg = "spatial entropy accounts for turn positions, directions and starting keys";
    expect(spatialEntropy(match), entropy, reason: msg);
  });

  test('dictionaryEntropy', () {
    var expected, match, msg;
    match = new Match()
      ..token = 'aaaaa'
      ..rank = 32;
    msg = "base entropy is the lg of the rank";
    expect(dictionaryEntropy(match), lg(32), reason: msg);
    match = new Match()
      ..token = 'AAAaaa'
      ..rank = 32;
    msg = "extra entropy is added for capitalization";
    expect(dictionaryEntropy(match), lg(32) + extraUppercaseEntropy(match), reason: msg);
    match = new Match()
      ..token = 'aaa@@@'
      ..rank = 32
      ..l33t = true
      ..sub = {'@': 'a'};
    msg = "extra entropy is added for common l33t substitutions";
    expect(dictionaryEntropy(match), lg(32) + extraL33tEntropy(match), reason: msg);
    match = new Match()
      ..token = 'AaA@@@'
      ..rank = 32
      ..l33t = true
      ..sub = {'@': 'a'};
    msg = "extra entropy is added for both capitalization and common l33t substitutions";
    expected = lg(32) + extraL33tEntropy(match) + extraUppercaseEntropy(match);
    expect(dictionaryEntropy(match), expected, reason: msg);
  });

  test('extraUppercaseEntropy', () {
    var extra_entropy, l, len, msg, ref, ref1, word;
    ref = [
      ['', 0],
      ['a', 0],
      ['A', 1],
      ['abcdef', 0],
      ['Abcdef', 1],
      ['abcdeF', 1],
      ['ABCDEF', 1],
      ['aBcdef', lg(nCk(6, 1))],
      ['aBcDef', lg(nCk(6, 1) + nCk(6, 2))],
      ['ABCDEf', lg(nCk(6, 1))],
      ['aBCDEf', lg(nCk(6, 1) + nCk(6, 2))],
      ['ABCdef', lg(nCk(6, 1) + nCk(6, 2) + nCk(6, 3))]
    ];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      word = ref1[0];
      extra_entropy = ref1[1];
      msg = "extra uppercase entropy of ${word} is ${extra_entropy}";
      expect(extraUppercaseEntropy(new Match()..token = word), extra_entropy, reason: msg);
    }
  });

  test('extraL33tEntropy', () {
    var extra_entropy, l, len, match, msg, ref, ref1, word;
    Map sub;
    match = new Match()..l33t = false;
    expect(extraL33tEntropy(match), 0, reason: "0 extra entropy for non-l33t matches");
    ref = [
      ['', 0, {}],
      ['a', 0, {}],
      [
        '4',
        1,
        {'4': 'a'}
      ],
      [
        '4pple',
        1,
        {'4': 'a'}
      ],
      ['abcet', 0, {}],
      [
        '4bcet',
        1,
        {'4': 'a'}
      ],
      [
        'a8cet',
        1,
        {'8': 'b'}
      ],
      [
        'abce+',
        1,
        {'+': 't'}
      ],
      [
        '48cet',
        2,
        {'4': 'a', '8': 'b'}
      ],
      [
        'a4a4aa',
        lg(nCk(6, 2) + nCk(6, 1)),
        {'4': 'a'}
      ],
      [
        '4a4a44',
        lg(nCk(6, 2) + nCk(6, 1)),
        {'4': 'a'}
      ],
      [
        'a44att+',
        lg(nCk(4, 2) + nCk(4, 1)) + lg(nCk(3, 1)),
        {'4': 'a', '+': 't'}
      ]
    ];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      word = ref1[0];
      extra_entropy = ref1[1];
      sub = ref1[2];
      match = new Match()
        ..token = word
        ..sub = sub
        ..l33t = sub.isNotEmpty;
      msg = "extra l33t entropy of ${word} is ${extra_entropy}";
      expect(extraL33tEntropy(match), extra_entropy, reason: msg);
    }
    match = new Match()
      ..token = 'Aa44aA'
      ..l33t = true
      ..sub = {'4': 'a'};
    extra_entropy = lg(nCk(6, 2) + nCk(6, 1));
    msg = "capitalization doesn't affect extra l33t entropy calc";
    expect(extraL33tEntropy(match), extra_entropy, reason: msg);
  });
}
