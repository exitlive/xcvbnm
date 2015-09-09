library xcvbnm.scoring_test;

import 'package:test/test.dart';
import 'dart:math' as math;
import 'package:xcvbnm/src/scoring.dart';
import 'dart:core' hide Match;

main() {
  const num epsilon = 1e-10;

  test('nCk', () {
    var k, l, len, n, ref, ref1, result;
    ref = [[0, 0, 1], [1, 0, 1], [5, 0, 1], [0, 1, 0], [0, 5, 0], [2, 1, 2], [4, 2, 6], [33, 7, 4272048]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      n = ref1[0];
      k = ref1[1];
      result = ref1[2];
      expect(nCk(n, k), result);
    }
    n = 49;
    k = 12;
    expect(nCk(n, k), nCk(n, n - k), reason: "mirror identity");
    expect(nCk(n, k), nCk(n - 1, k - 1) + nCk(n - 1, k), reason: "pascal's triangle identity");
  });

  test('lg', () {
    var l, len, n, p, ref, ref1, result;
    ref = [[1, 0], [2, 1], [4, 2], [32, 5]];

    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      n = ref1[0];
      result = ref1[1];
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
    var e, e0, e1, e2, e3, l, len, n, ref;
    var results;
    ref = [0, 1, 7, 60];
    results = [];
    len = ref.length;
    for (l = 0; l < len; l++) {
      n = ref[l];
      results.add(entropyToCrackTime(n));
    }
    e0 = ref[0];
    e1 = ref[1];
    e2 = ref[2];
    e3 = ref[3];

    expect(e0 < e1 && e1 < e2 && e2 < e3, isTrue, reason: "monotonically increasing");
    for (l = 0; l < len; l++) {
      e = results[l];
      expect(e, greaterThan(0), reason: "always positive");
    }
  });

  test('crackTimeToScore', () {
    var l, len, msg, ref, ref1, score, seconds;
    ref = [[0, 0], [10, 0], [math.pow(10, 9), 4]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      seconds = ref1[0];
      score = ref1[1];
      msg = "crack time of ${seconds} seconds has score of ${score}";
      expect(crackTimeToScore(seconds), score, reason: msg);
    }
  });

  test('calcBruteforceCardinality', () {
    var cardinality, l, len, msg, ref, ref1, str;
    ref = [['a', 26], ['h', 26], ['z', 26], ['Q', 26], ['0', 10], ['9', 10], ['\$', 33], ['£', 64], ['å', 64], ['α', 40], ['αβ', 40], ['Ϫα', 58], ['好', 40], ['信息论', 100], ['a\$', 59], ['aQ£', 116], ['9Z9Z', 36], ['«信息论»', 164]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      str = ref1[0];
      cardinality = ref1[1];
      msg = "cardinality of ${str} is ${cardinality}";
      expect(calcBruteforceCardinality(str), cardinality, reason: msg);
    }
  });

  test('displayTime', () {
    var display, l, len, msg, ref, ref1, seconds;
    ref = [[0, '0 seconds'], [1, '1 second'], [32, '32 seconds'], [60, '1 minute'], [121, '2 minutes'], [3600, '1 hour'], [2 * 3600 * 24 + 5, '2 days'], [1 * 3600 * 24 * 31 + 4000, '1 month'], [99 * 3600 * 24 * 31 * 12, '99 years'], [math.pow(10, 10), 'centuries']];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      seconds = ref1[0];
      display = ref1[1];
      msg = "${seconds} seconds has a display time of ${display}";
      expect(displayTime(seconds), display, reason: msg);
    }
  });

  test('calcEntropy', () {
    var match, msg;
    match = new Match()
      ..entropy = 1;
    expect(calcEntropy(match), 1, reason: "calc_entropy returns cached entropy when available");
    match = new Match()
      ..pattern = 'date'
      ..year = 1977
      ..month = 7
      .. day = 14;
    msg = "calc_entropy delegates based on pattern";
    expect(calcEntropy(match), dateEntropy(match), reason: msg);
  });

  test('repeatEntropy', () {
    var entropy, l, len, match, msg, ref, ref1, token;
    ref = [['aa', lg(26 * 2)], ['999', lg(10 * 3)], ['\$\$\$\$', lg(33 * 4)]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      token = ref1[0];
      entropy = ref1[1];
      match = new Match()
        ..token = token;
      msg = "the repeat pattern '${token}' has entropy of ${entropy}";
      expect(repeatEntropy(match), entropy, reason: msg);
    }
  });

  test('sequenceEntropy', () {
    var ascending, entropy, l, len, match, msg, ref, ref1, token;
    ref = [
      //['ab', true, lg(26) + lg(2)],
      ['XYZ', true, lg(26) + 1 + lg(3)],
      ['4567', true, lg(10) + lg(4)],
      ['7654', false, lg(10) + lg(4) + 1],
      ['ZYX', false, lg(26) + 1 + lg(3) + 1]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      token = ref1[0];
      ascending = ref1[1];
      entropy = ref1[2];
      match = new Match()
        ..token = token
        .. ascending = ascending;
      msg = "the sequence pattern '${token}' has entropy of ${entropy}";
      expect(sequenceEntropy(match), entropy, reason: msg);
    }
  });

  test('regexEntropy', () {
    var match;
    match = new Match()
      ..token = 'aizocdk'
      ..regexName = 'alpha_lower'
      ..regexMatch = ['aizocdk'];

    expect(regexEntropy(match), lg(math.pow(26, 7)));
    match = new Match()
      ..token = 'ag7C8'
      ..regexName = 'alphanumeric'
      ..regexMatch = ['ag7C8'];
    expect(regexEntropy(match), lg(math.pow(2 * 26 + 10, 5)));
    match = new Match()
      ..token = '1972'
      ..regexName = 'recent_year'
      ..regexMatch = ['1972'];

    expect(regexEntropy(match), lg(referenceYear - 1972));
    match = new Match()
      ..token = '1992'
      ..regexName = 'recent_year'
      ..regexMatch = ['1992'];

    expect(regexEntropy(match), lg(minYearSpace));
  });

  test('dateEntropy', () {
    var match, msg;
    match = new Match()
      ..token = '1123'
      ..separator = ''
      ..hasFullYear = false
      ..year = 1923
      ..month = 1
      ..day = 1;
    msg = "entropy for ${match.token} is lg days * months * distance_from_ref_year";
    expect(dateEntropy(match), lg(12 * 31 * (referenceYear - match.year)), reason: msg);
    match = new Match()
      ..token = '1/1/2010'
      ..separator = '/'
      ..hasFullYear = true
      ..year = 2010
      ..month = 1
      ..day = 1;
    msg = "recent years assume MIN_YEAR_SPACE.";
    msg += " extra entropy is added for separators and a 4-digit year.";
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
    Match match = new Match()
      ..token = 'zxcvbn'
      ..graph = 'qwerty'
      ..turns = 1
      ..shiftedCount = 0;
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
    match = new Match()
      ..token = 'zxcft6yh'
      ..graph = 'qwerty'
      ..turns = 3
      ..shiftedCount = 0;
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
      ..sub = {
      '@': 'a'
    };
    msg = "extra entropy is added for common l33t substitutions";
    expect(dictionaryEntropy(match), lg(32) + extraL33tEntropy(match), reason: msg);
    match = new Match()
      ..token = 'AaA@@@'
      ..rank = 32
      ..l33t = true
      ..sub = {
      '@': 'a'
    };
    msg = "extra entropy is added for both capitalization and common l33t substitutions";
    expected = lg(32) + extraL33tEntropy(match) + extraUppercaseEntropy(match);
    expect(dictionaryEntropy(match), expected, reason: msg);
  });

  test('extraUppercaseEntropy', () {
    var extra_entropy, l, len, msg, ref, ref1, word;
    ref = [['', 0], ['a', 0], ['A', 1], ['abcdef', 0], ['Abcdef', 1], ['abcdeF', 1], ['ABCDEF', 1], ['aBcdef', lg(nCk(6, 1))], ['aBcDef', lg(nCk(6, 1) + nCk(6, 2))], ['ABCDEf', lg(nCk(6, 1))], ['aBCDEf', lg(nCk(6, 1) + nCk(6, 2))], ['ABCdef', lg(nCk(6, 1) + nCk(6, 2) + nCk(6, 3))]];
    len = ref.length;
    for (l = 0; l < len; l++) {
      ref1 = ref[l];
      word = ref1[0];
      extra_entropy = ref1[1];
      msg = "extra uppercase entropy of ${word} is ${extra_entropy}";
      expect(extraUppercaseEntropy(new Match()
        ..
      token = word
      ), extra_entropy, reason: msg);
    }
  });

  test('extraL33tEntropy', () {
    var extra_entropy, l, len, match, msg, ref, ref1, word;
    Map sub;
    match = new Match()
      ..l33t = false;
    expect(extraL33tEntropy(match), 0, reason: "0 extra entropy for non-l33t matches");
    ref = [
      ['', 0, {}], ['a', 0, {}], [
        '4', 1, {
          '4': 'a'
        }
      ], [
        '4pple', 1, {
          '4': 'a'
        }
      ], ['abcet', 0, {}], [
        '4bcet', 1, {
          '4': 'a'
        }
      ], [
        'a8cet', 1, {
          '8': 'b'
        }
      ], [
        'abce+', 1, {
          '+': 't'
        }
      ], [
        '48cet', 2, {
          '4': 'a',
          '8': 'b'
        }
      ], [
        'a4a4aa', lg(nCk(6, 2) + nCk(6, 1)), {
          '4': 'a'
        }
      ], [
        '4a4a44', lg(nCk(6, 2) + nCk(6, 1)), {
          '4': 'a'
        }
      ], [
        'a44att+', lg(nCk(4, 2) + nCk(4, 1)) + lg(nCk(3, 1)), {
          '4': 'a',
          '+': 't'
        }
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
      ..sub = {
      '4': 'a'
    };
    extra_entropy = lg(nCk(6, 2) + nCk(6, 1));
    msg = "capitalization doesn't affect extra l33t entropy calc";
    expect(extraL33tEntropy(match), extra_entropy, reason: msg);
  });
}