library xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';

class XcvbnmMock extends Object implements Xcvbnm {
  int getNaiveScore(String password) {
    if (password.length < 3) return 0;
    if (password.length < 5) return 1;
    if (password.length < 7) return 2;
    if (password.length < 9) return 3;
    if (password.length < 11) return 3;
    return 4;
  }

  Result estimate(String password, {List<String> userInputs}) {
    return new Result()
      ..score = getNaiveScore(password)
      ..password = password;
  }
}

void main() {
  Xcvbnm xcvbnm = new XcvbnmMock();

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
