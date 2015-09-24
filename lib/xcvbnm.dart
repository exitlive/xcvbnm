library xcvbnm;

import "src/matching.dart" as matching;
import "src/scoring.dart" as scoring;

part 'src/xcvbnm_impl.dart';

///
/// Match sequence
///
abstract class Match {
  /// js like output of the result
  Map toMap();
}

///
/// xcvbnm analysic result
///
abstract class Result {
  factory Result() => new _Result();

  /// password
  String password;

  /// bits
  num entropy;

  /// estimation of actual crack time, in seconds.
  num crackTime;

  /// same crack time, as a friendlier string:
  /// "instant", "6 minutes", "centuries", etc.
  String crackTimeDisplay;

  /// [0,1,2,3,4] if crack time is less than
  /// [10**2, 10**4, 10**6, 10**8, Infinity].
  /// (useful for implementing a strength bar.)
  int score;

  /// how long it took xcvbnm to calculate an answer,
  /// in milliseconds.
  int calcTime;

  /// the list of patterns that zxcvbn based the
  /// entropy calculation on.
  List<Match> matchSequence;

  /// js like output of the result
  Map toMap();
}

///
/// base implementation class
///
abstract class Xcvbnm {
  ///
  /// estimate a password according
  /// Returns a [:Result:] with the data of the analysis
  ///
  /// The optional [user_inputs] argument is an array of strings that zxcvbn will treat as an extra dictionary.
  /// This can be whatever list of strings you like, but is meant for user inputs from other fields of the form,
  /// like name and email. That way a password that includes a user's personal information can be heavily penalized.
  /// This list is also good for site-specific vocabulary
  /// Acme Brick Co. might want to include ['acme', 'brick', 'acmebrick', etc].
  ///
  Result estimate(String password, {List<String> userInputs});

  ///
  /// Creates a [Xcvbnm] object.
  ///
  factory Xcvbnm() => new _Xcvbnm();
}

///
/// the one and only entrypoint needed
///
Result xcvbnm(String password, {List<String> userInputs}) {
  Xcvbnm impl = new Xcvbnm();
  return impl.estimate(password);
}
