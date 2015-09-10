library xcvbnm.mock.impl;

import 'xcvbnm_common.dart' hide Xcvbnm;
import 'xcvbnm_common.dart' as common;

class Xcvbnm extends common.Xcvbnm {
  int getNaiveScore(String password) {
    if (password.length < 3) return 0;
    if (password.length < 5) return 1;
    if (password.length < 7) return 2;
    if (password.length < 9) return 3;
    if (password.length < 11) return 3;
    return 4;
  }

  Result estimate(String password, {List<String> userInputs}) {
    return new Result()..score = getNaiveScore(password);
  }
}
