library xcvbnm.core;

import 'package:xcvbnm/src/result.dart';
import 'package:xcvbnm/src/scoring.dart' as scoring;
import 'package:xcvbnm/src/matching.dart' as matching;

class Xcvbnm {
  /// Estimate the strenght of password
  /// Returns a [Result] with the data of the analysis
  ///
  /// The optional [user_inputs] argument is an array of strings that zxcvbn will treat as an extra dictionary.
  /// This can be whatever list of strings you like, but is meant for user inputs from other fields of the form,
  /// like name and email. That way a password that includes a user's personal information can be heavily penalized.
  /// This list is also good for site-specific vocabulary
  /// Acme Brick Co. might want to include ['acme', 'brick', 'acmebrick', etc].
  ///
  Result estimate(String password, {List<String> userInputs}) {
    Result result = new Result();
    Stopwatch sw = new Stopwatch();
    sw.start();

    // reset the user inputs matcher on a per-request basis to keep things stateless
    if (userInputs == null) {
      userInputs = [];
    }
    matching.setUserInputDictionary(userInputs);

    List<scoring.Match> matches = matching.omnimatch(password);
    result = scoring.minimumEntropyMatchSequence(password, matches);
    sw.stop();
    result.calcTime = sw.elapsedMilliseconds;
    return result;
  }
}
