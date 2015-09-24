#!/usr/bin/env dart
library xcvbnm.example.bin;

import 'package:xcvbnm/xcvbnm.dart';
import 'dart:convert';

test1() {
  String password = "my_pwd_1";
  // Use the direct helper API
  Result result = xcvbnm(password);
  print(const JsonEncoder.withIndent("  ").convert(result.toJson()));
}

test2() {
  String password = "my_pwd_1";
  // Use the object (can allow mocking)
  Xcvbnm xcvbnm = new Xcvbnm();
  Result result = xcvbnm.estimate(password);
  print(const JsonEncoder.withIndent("  ").convert(result.toJson()));
}

main() {
  test1();
  test2();
}
