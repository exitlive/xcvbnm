library xcvbnm.xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('xcvbnm', () {
    test('test foo', () async {
      var result = xcvbnm.estimate('foo');
      expect(result, isNotNull);
    });
    test('test passwords', () async {
      // Just validate this again some sample passwords
      var test_passwords = [
        r'zxcvbn',
        r'qwER43@!',
        r'Tr0ub4dour&3',
        r'correcthorsebatterystaple',
        r'coRrecth0rseba++ery9.23.2007staple$',
        r'D0g..................',
        r'abcdefghijk987654321',
        r'neverforget13/3/1997',
        r'1qaz2wsx3edc',
        r'temppass22',
        r'briansmith',
        r'briansmith4mayor',
        r'password1',
        r'viking',
        r'thx1138',
        r'ScoRpi0ns',
        r'do you know',
        r'ryanhunter2000',
        r'rianhunter2000',
        r'asdfghju7654rewq',
        r'AOEUIDHG&*()LS_',
        r'12345678',
        r'defghi6789',
        r'rosebud',
        r'Rosebud',
        r'ROSEBUD',
        r'rosebuD',
        r'ros3bud99',
        r'r0s3bud99',
        r'R0$38uD99',
        r'verlineVANDERMARK',
        r'eheuczkqyq',
        r'rWibMFACxAUGZmxhVncy',
        r'Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w',
      ];

      for (String password in test_passwords) {
        var result = xcvbnm.estimate(password);
        expect(result, isNotNull);
      }
    });
  });
}
