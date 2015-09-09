library xcvbnm.matching;

import "../xcvbnm.dart" as xcvbnm;
import "scoring.dart" as scoring;
import 'frequency_lists.dart';

bool empty(var obj) {
  return obj.isEmpty;
}

extend(List lst, List lst2) => lst.addAll(lst2);

String translate(String string, Map chr_map) {
  var chr;
  List result = [];
  for (chr in string.split("")) {
    var translated = chr_map[chr];
    if (translated != null) {
      chr = translated;
    }
    result.add(chr);
  }
  return result.join("");
}

int mod(int n, int m) => ((n % m) + m) % m;

sorted(List<scoring.Match> matches) {
  matches.sort((m1, m2) {
    int iDiff = (m1.i - m2.i);
    if (iDiff == 0) {
      return (m1.j - m2.j);
    }
    return iDiff;
  });
  return matches;
}

Map<String, int> buildRankedDict(List ordered_list) {
  Map<String, int> result = {};
  var i = 1; // rank starts at 1, not 0
  for (String word in ordered_list) {
    result[word] = i++;
  }
  return result;
}

Map<String, Map<String, int>> rankedDictionaries = {
  "passwords": buildRankedDict(frequencyLists["passwords"]),
  "english":buildRankedDict(frequencyLists["english"]),
  "surnames":buildRankedDict(frequencyLists["surnames"]),
  "male_names":buildRankedDict(frequencyLists["male_names"]),
  "female_names":buildRankedDict(frequencyLists["female_names"])
};

class DictionaryMatch extends scoring.Match {
  DictionaryMatch({this.matchedWord, this.dictionaryName, int rank}) {
    this.rank = rank;
  }

  String matchedWord;
  String dictionaryName;
}

dictionaryMatch(password, [Map _ranked_dictionaries]) {
  // _ranked_dictionaries variable is for unit testing purposes
  var dictionary_name, i, j, len, matches, o, p, rank, ranked_dict, ref, ref1, ref2, word;
  if (_ranked_dictionaries == null) {
    _ranked_dictionaries = rankedDictionaries;
  }
  matches = [];
  len = password.length;
  String password_lower = password.toLowerCase();
  _ranked_dictionaries.forEach((dictionary_name, Map<String, int> ranked_dict) {
    for (int i = 0; i < len; i++) {
      for (int j = i; j < len; j++) {
        word = password_lower.substring(i, j + 1);

        if (ranked_dict.containsKey(word)) {
          rank = ranked_dict[word];
          matches.add(new DictionaryMatch()
            ..pattern = 'dictionary'
            ..i = i
            ..j = j
            ..token = password.substring(i, j + 1)
            ..matchedWord = word
            ..rank = rank
            ..dictionaryName = dictionary_name
          );
        }
      }
    }
  });
  return sorted(matches);

}
