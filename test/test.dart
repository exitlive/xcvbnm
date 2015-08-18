library xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';

void main() {
  group('xcvbnm', () {
    test('test with score 1', () async {
      var result = zxcvbn('foo');
      expect(result.score, 1);
    });
  });
  group('xcvbnm', () {
    test('test with score 2', () async {
      var result = zxcvbn('foobar');
      expect(result.score, 2);
    });
  });
  group('xcvbnm', () {
    test('test with score 3', () async {
      var result = zxcvbn('foobarfrotz');
      expect(result.score, 3);
    });
  });
}
