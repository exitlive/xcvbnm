library xcvbnm.impl;

import "xcvbnm_common.dart" hide Xcvbnm;
import "xcvbnm_common.dart" as xcvbnm;
import "matching.dart" as matching;
import "scoring.dart" as scoring;

class Xcvbnm extends xcvbnm.Xcvbnm {
  Result estimate(String password, {List<String> userInputs}) {
    Result result = new Result();
    Stopwatch sw = new Stopwatch();
    sw.start();
    //List<xcvbnm.Match> matches = matching.omnimatch(password);
    List<scoring.Match> matches = matching.omnimatch(password);
    // for (xcvbnm.Match match in matches) {
    //  print(match.toMap());
    //}
    result = scoring.minimumEntropyMatchSequence(password, matches);
    //result.calcTime = sw.elapsedMilliseconds;
    sw.stop();
    result.calcTime = sw.elapsedMilliseconds;
    return result;
  }
}
