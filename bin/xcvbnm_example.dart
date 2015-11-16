#!/usr/bin/env dart
library xcvbnm.example.bin;

import 'package:xcvbnm/xcvbnm.dart';
import 'dart:convert';

main() {
  String password = 'my_pwd_1';
  Result result = new Xcvbnm().estimate(password);
  print(const JsonEncoder.withIndent("  ").convert(result.toJson()));
}
