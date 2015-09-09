library xcvbnm.matching_test;

import 'package:test/test.dart';
import 'package:xcvbnm/src/matching.dart';
import "package:xcvbnm/src/scoring.dart" as scoring;

main() {

  test('matching utils', () {
    var chr_map, dividend, divisor, l, len2, lst, lst1, lst2, m1, m2, m3, m4, m5, m6, map, msg, n, o, obj, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, remainder, result, string;
    expect(empty([]), isTrue, reason: ".empty returns true for an empty array");
    expect(empty({}), isTrue, reason: ".empty returns true for an empty object");

    for (var value in [
      [1], [1, 2], [[]], {
        "a": 1
      }, {
        "0": {}
      }
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
    ref1 = [[1], [2]];
    lst1 = ref1[0];
    lst2 = ref1[1];
    extend(lst1, lst2);
    expect(lst2, [2], reason: "extending a list by another doesn't affect the other");
    chr_map = {
      'a': 'A',
      'b': 'B'
    };
    ref2 = [['a', chr_map, 'A'], ['c', chr_map, 'c'], ['ab', chr_map, 'AB'], ['abc', chr_map, 'ABc'], ['aa', chr_map, 'AA'], ['abab', chr_map, 'ABAB'], ['', chr_map, ''], ['', {}, ''], ['abc', {}, 'abc']];
    for (var row in ref2) {
      string = row[0];
      map = row[1];
      result = row[2];

      msg = "translates '${string}' to '${result}' with provided charmap";
      expect(translate(string, map), result, reason: msg);
    }

    ref4 = [[[0, 1], 0], [[1, 1], 0], [[-1, 1], 0], [[5, 5], 0], [[3, 5], 3], [[-1, 5], 4], [[-5, 5], 0], [[6, 5], 1]];
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

    var data = [
      m(5, 5), m(6, 7), m(2, 5), m(0, 0), m(2, 3), m(0, 3)]
    ;
    m1 = data[0];
    m2 = data[1];
    m3 = data[2];
    m4 = data[3];
    m5 = data[4];
    m6 = data[5];
    msg = "matches are sorted on i index primary, j secondary";
    expect(sorted([m1, m2, m3, m4, m5, m6]), [m4, m6, m5, m3, m1, m2], reason: msg);
  });
}