library xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('xcvbnm', () {
    test('test with score 0', () async {
      var result = xcvbnm.estimate('fo');
      expect(result.score, 0);
    });
  });
  group('xcvbnm', () {
    test('test with score 1', () async {
      var result = xcvbnm.estimate('foo');
      expect(result.score, 1);
    });
  });
  group('xcvbnm', () {
    test('test with score 2', () async {
      var result = xcvbnm.estimate('foobar');
      expect(result.score, 2);
    });
  });
  group('xcvbnm', () {
    test('test with score 3', () async {
      var result = xcvbnm.estimate('foobarfr');
      expect(result.score, 3);
    });
  });
  group('xcvbnm', () {
    test('test with score 4', () async {
      var result = xcvbnm.estimate('foobarfrotz');
      expect(result.score, 4);
    });
  });
}
