#!/usr/bin/env dart
library xcvbnm.mock_example.bin;

import 'package:xcvbnm/xcvbnm.dart';

class XcvbnmMock extends Object with Xcvbnm {
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

main() {
  String password = "my_pwd_1";

  Xcvbnm xcvbnm = new Xcvbnm();
  Result result = xcvbnm.estimate(password);
  print(result.toMap());
}
