library xcvbnm.feedback;

import 'package:xcvbnm/src/scoring.dart' as scoring;

class Feedback {
  static final String generalSuggestion = 'Use a few words, avoid common phrases. '
      'No need for symbols, digits, or uppercase letters';
  static final String spatialSingleTurnSuggestion = 'Straight rows of keys are easy to guess. '
      'Use a longer keyboard pattern with more turns';
  static final String spatialMultiTurnSuggestion = 'Short keyboard patterns are easy to guess. '
      'Use a longer keyboard pattern with more turns';
  static final String repeatSingleCharSuggestion = 'Repeats like \'aaa\' are easy to guess. '
      'Avoid repeated words and characters';
  static final String repeatMultiCharSuggestion =
      'Repeats like \'abcabcabc\' are only slightly harder to guess than \'abc\'. '
      'Avoid repeated words and characters';
  static final String sequenceSuggestion = 'Sequences like abc or 6543 are easy to guess. '
      'Avoid sequences';
  static final String recentYearSuggestion = 'Recent years are easy to guess. '
      'Avoid recent years and years that are associated with you';
  static final String dateSuggestion = 'Dates are often easy to guess. '
      'Avoid dates and years that are associated with you';
  static final String top10PasswordSuggestion = 'This is a top-10 common password';
  static final String top100PasswordSuggestion = 'This is a top-100 common password';
  static final String commonPasswordSuggestion = 'This is a very common password';
  static final String englishWordSuggestion = 'A word by itself is easy to guess';
  static final String nameSuggestion = 'Common names and surnames are easy to guess';

  String suggestion = generalSuggestion;

  Feedback(int score, List<scoring.Match> sequence) {
    var sequenceCopy = [];
    sequenceCopy.addAll(sequence);
    getFeedback(score, sequenceCopy);
  }

  getFeedback(int score, List<scoring.Match> sequence) {
    // starting feedback
    sequence.removeWhere((match) => match.token == null);
    if (sequence?.length == 0) return;

    // no feedback if score is good or great.
    if (score > 2) {
      suggestion = '';
      return;
    }

    // tie feedback to the longest match for longer sequences
    var longestMatch = sequence.first;
    for (var match in sequence) {
      if (match.token.length > longestMatch.token.length) longestMatch = match;
    }
    getMatchFeedback(longestMatch, sequence.length == 1);
  }

  getMatchFeedback(match, isSoleMatch) {
    switch (match.pattern) {
      case 'dictionary':
        getDictionaryMatchFeedback(match, isSoleMatch);
        break;
      case 'spatial':
        if (match.turns == 1)
          suggestion = spatialSingleTurnSuggestion;
        else
          suggestion = spatialMultiTurnSuggestion;
        break;
      case 'repeat':
        if (match.baseToken.length == 1)
          suggestion = repeatSingleCharSuggestion;
        else
          suggestion = repeatMultiCharSuggestion;
        break;
      case 'sequence':
        suggestion = sequenceSuggestion;
        break;
      case 'regex':
        if (match.regexName == 'recent_year') suggestion = recentYearSuggestion;
        break;
      case 'date':
        suggestion = dateSuggestion;
        break;
    }
  }

  getDictionaryMatchFeedback(scoring.DictionaryMatch match, isSoleMatch) {
    bool l33t = match.l33t == true;
    bool reversed = match.reversed == true;
    if (match.dictionaryName == 'passwords') {
      if (isSoleMatch && !l33t && !reversed) {
        if (match.rank <= 10)
          suggestion = top10PasswordSuggestion;
        else if (match.rank <= 100)
          suggestion = top100PasswordSuggestion;
        else
          suggestion = commonPasswordSuggestion;
      }
    } else if (match.dictionaryName == 'english') {
      if (isSoleMatch) suggestion = englishWordSuggestion;
    } else if (['surnames', 'male_names', 'female_names'].contains(match.dictionaryName)) {
      suggestion = nameSuggestion;
    }
  }

  @override
  String toString() {
    return suggestion;
  }
}
