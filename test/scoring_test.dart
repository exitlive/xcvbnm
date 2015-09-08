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
      //['4567', true, lg(10) + lg(4)],
      //['7654', false, lg(10) + lg(4) + 1],
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
      // ? report issue to DROPBOX
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
}