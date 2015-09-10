library xcvbnm.xcvbnm_test;

import 'package:test/test.dart';
import 'package:xcvbnm/src/xcvbnm_impl.dart';

void main() {
  var xcvbnm = new Xcvbnm();

  group('xcvbnm', () {
    test('test foo', () async {
      var result = xcvbnm.estimate('fo');
      expect(result, isNotNull);
    });
  });
}
