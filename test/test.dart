library xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/xcvbnm.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('xcvbnm', () {
    test('test passwords', () async {
      // Just validate this again some sample passwords
      String test_passwords =
          'zxcvbn\nqwER43@!\nTr0ub4dour&3\ncorrecthorsebatterystaple\ncoRrecth0rseba++ery9.23.2007staple\$\n\nD0g..................\nabcdefghijk987654321\nneverforget13/3/1997\n1qaz2wsx3edc\n\ntemppass22\nbriansmith\nbriansmith4mayor\npassword1\nviking\nthx1138\nScoRpi0ns\ndo you know\n\nryanhunter2000\nrianhunter2000\n\nasdfghju7654rewq\nAOEUIDHG&*()LS_\n\n12345678\ndefghi6789\n\nrosebud\nRosebud\nROSEBUD\nrosebuD\nros3bud99\nr0s3bud99\nR0\$38uD99\n\nverlineVANDERMARK\n\neheuczkqyq\nrWibMFACxAUGZmxhVncy\nBa9ZyWABu99[BK#6MBgbH88Tofv)vs\$w';

      for (String password in test_passwords.split('\n')) {
        var result = xcvbnm.estimate(password);
        expect(result, isNotNull);
      }
    });
  });
}
