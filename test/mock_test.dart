library xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/mock_xcvbnm.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('mock', () {
    test('test with score 0', () async {
      var result = xcvbnm.estimate('fo');
      expect(result.score, 0);
    });

    test('test with score 1', () async {
      var result = xcvbnm.estimate('foo');
      expect(result.score, 1);
    });

    test('test with score 2 & 3 & 4', () async {
      var result = xcvbnm.estimate('foobar');
      expect(result.score, 2);
      result = xcvbnm.estimate('foobarfr');
      expect(result.score, 3);
      result = xcvbnm.estimate('foobarfrotz');
      expect(result.score, 4);
    });
  });
}
