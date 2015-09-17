#!/usr/bin/env dart
library xcvbnm.bin;

import 'package:args/args.dart';
import 'package:xcvbnm/xcvbnm.dart';
import 'package:xcvbnm/src/scoring.dart' as scoring;

const String _HELP = 'help';
const String _MATCH = 'match';
const String _DEPENDENCY = 'dependency';

main(List<String> args) {
  int maxMatchToDisplay = 4;

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addOption(_MATCH, abbr: 'm', help: 'Max number max of match to display', defaultsTo: "${maxMatchToDisplay}");
  ArgResults _argsResult = parser.parse(args);

  bool help = _argsResult[_HELP];
  if (help) {
    print(parser.usage);
    return;
  }

  String param = _argsResult[_MATCH];
  if (param != null) {
    maxMatchToDisplay = int.parse(param, onError: (_) => maxMatchToDisplay);
  }

  List<String> passwords = _argsResult.rest;
  if (passwords == null || passwords.isEmpty) {
    // godle sample of data
    String testPasswords =
        'zxcvbn\nqwER43@!\nTr0ub4dour&3\ncorrecthorsebatterystaple\ncoRrecth0rseba++ery9.23.2007staple\$\n\nD0g..................\nabcdefghijk987654321\nneverforget13/3/1997\n1qaz2wsx3edc\n\ntemppass22\nbriansmith\nbriansmith4mayor\npassword1\nviking\nthx1138\nScoRpi0ns\ndo you know\n\nryanhunter2000\nrianhunter2000\n\nasdfghju7654rewq\nAOEUIDHG&*()LS_\n\n12345678\ndefghi6789\n\nrosebud\nRosebud\nROSEBUD\nrosebuD\nros3bud99\nr0s3bud99\nR0\$38uD99\n\nverlineVANDERMARK\n\neheuczkqyq\nrWibMFACxAUGZmxhVncy\nBa9ZyWABu99[BK#6MBgbH88Tofv)vs\$w';

    passwords = testPasswords.split('\n');
  }
  for (String password in passwords) {
    Result result = xcvbnm(password);

    print("----- Result ------");
    print("password:           ${result.password}");
    print("entropy:              ${result.entropy}");
    print("crack_time:         ${new Duration(milliseconds: result.crackTime)}");
    print("crack_time_display: ${result.crackTimeDisplay}");
    print("score from 0 to 4:  ${result.score}");
    print("cecl_time:          ${new Duration(milliseconds: result.calcTime)}");
    if (result.matchSequence != null && result.matchSequence.isNotEmpty) {
      int i = 1;
      for (scoring.Match match in result.matchSequence) {
        if (i > maxMatchToDisplay) {
          break;
        }
        print("----- match ${i++}/${result.matchSequence.length}");
        if (match is scoring.Match) {
          print("'${match.token}'");
          print("pattern:      '${match.pattern}'");
          print("entropy:       ${match.entropy}");

          if (match is scoring.DictionaryMatch) {
            if (match.rank != null) {
              print("rank:          ${match.rank}");
            }
          }

          if (match.baseEntropy != null) {
            print("base_entropy:  ${match.baseEntropy}");
          }

          if (match is scoring.DictionaryMatch) {
            if (match.uppercaseEntropy != null) {
              print("upper_entropy: ${match.uppercaseEntropy}");
            }
          }
        }
      }
    }
    print("");
  }
}
