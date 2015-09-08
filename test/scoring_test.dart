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
}