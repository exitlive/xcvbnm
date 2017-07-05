library xcvbnm.browser.demo;

import 'package:xcvbnm/xcvbnm.dart';
import 'package:xcvbnm/src/scoring.dart' as scoring;
import 'dart:html';

const String _HELP = 'help';
const String _MATCH = 'match';
const String _DEPENDENCY = 'dependency';

void main() {
  int maxMatchToDisplay;

  // good sample of data
  String testPasswords =
      'zxcvbn\nqwER43@!\nTr0ub4dour&3\ncorrecthorsebatterystaple\ncoRrecth0rseba++ery9.23.2007staple\$\n\nD0g..................\nabcdefghijk987654321\nneverforget13/3/1997\n1qaz2wsx3edc\n\ntemppass22\nbriansmith\nbriansmith4mayor\npassword1\nviking\nthx1138\nScoRpi0ns\ndo you know\n\nryanhunter2000\nrianhunter2000\n\nasdfghju7654rewq\nAOEUIDHG&*()LS_\n\n12345678\ndefghi6789\n\nrosebud\nRosebud\nROSEBUD\nrosebuD\nros3bud99\nr0s3bud99\nR0\$38uD99\n\nverlineVANDERMARK\n\neheuczkqyq\nrWibMFACxAUGZmxhVncy\nBa9ZyWABu99[BK#6MBgbH88Tofv)vs\$w';

  List<String> passwords = testPasswords.split('\n');

  DivElement getResultEl(String password) {
    // The only call
    Result result = new Xcvbnm().estimate(password);

    DivElement resultEl = new DivElement()..classes.add('app-result');
    List<String> lines = [
      "----- Result ------",
      "password:           ${result.password}",
      "entropy:            ${result.entropy}",
      "crack_time:         ${new Duration(milliseconds: result.crackTime)}",
      "crack_time_display: ${result.crackTimeDisplay}",
      "score from 0 to 4:  ${result.score}",
      "cecl_time:          ${new Duration(milliseconds: result.calcTime)}"
    ];
    for (String line in lines) {
      resultEl.append(new PreElement()
        ..classes.add("app-line")
        ..text = line);
    }

    print(result.toJson());
    if (result.matchSequence != null && result.matchSequence.isNotEmpty) {
      int i = 1;
      DivElement matchesEl = new DivElement()..classes.add('app-matches');
      resultEl.append(matchesEl);
      for (var match in result.matchSequence) {
        if (maxMatchToDisplay != null && i > maxMatchToDisplay) {
          break;
        }

        DivElement matchEl = new DivElement()..classes.add('app-match');
        matchesEl.append(matchEl);
        List<String> lines = ["----- match ${i++}/${result.matchSequence.length}"];
        if (match is scoring.Match) {
          lines.add("'${match.token}'");
          lines.add("pattern:       '${match.pattern}'");
          lines.add("entropy:       ${match.entropy}");

          if (match.baseEntropy != null) {
            lines.add("base_entropy:  ${match.baseEntropy}");
          }

          if (match is scoring.DictionaryMatch) {
            if (match.rank != null) {
              lines.add("rank:          ${match.rank}");
            }
            if (match.uppercaseEntropy != null) {
              lines.add("upper_entropy: ${match.uppercaseEntropy}");
            }
          }
        }
        for (String line in lines) {
          matchEl.append(new PreElement()
            ..classes.add("app-line")
            ..text = line);
        }
      }
    }
    return resultEl;
  }

  DivElement resultsEl = new DivElement()..classes.add('app-results');
  for (String password in passwords) {
    DivElement resultEl = getResultEl(password);
    print(resultEl);
    resultsEl.append(resultEl);
  }
  DivElement passwordResultsEl = new DivElement()..classes.add('app-results');
  querySelector("#app_password_content").append(passwordResultsEl);
  InputElement appPasswordEl = querySelector('#app_password') as InputElement;
  appPasswordEl.onInput.listen((e) {
    String password = appPasswordEl.value;
    print(password);
    DivElement resultEl = getResultEl(password);
    passwordResultsEl
      ..children.clear()
      ..append(resultEl);
  });

  querySelector('#app_content')
    ..children.clear()
    ..append(resultsEl);
}
