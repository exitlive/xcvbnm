library xcvbnm.scoring_test;

import 'package:test/test.dart';

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
}