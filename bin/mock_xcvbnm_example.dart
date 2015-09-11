#!/usr/bin/env dart
library xcvbnm.mock_example.bin;

import 'package:xcvbnm/mock_xcvbnm.dart';

main() {
  String password = "my_pwd_1";

  Xcvbnm xcvbnm = new Xcvbnm();
  Result result = xcvbnm.estimate(password);
  print(result.toMap());
}
