library xcvbnm.matching;

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
  "english": buildRankedDict(frequencyLists["english"]),
  "surnames": buildRankedDict(frequencyLists["surnames"]),
  "male_names": buildRankedDict(frequencyLists["male_names"]),
  "female_names": buildRankedDict(frequencyLists["female_names"])
};

Map<String, List<String>> l33tTable = {
  'a': ['4', '@'],
  'b': ['8'],
  'c': ['(', '{', '[', '<'],
  'e': ['3'],
  'g': ['6', '9'],
  'i': ['1', '!', '|'],
  'l': ['1', '|', '7'],
  'o': ['0'],
  's': [r'$', '5'],
  't': ['+', '7'],
  'x': ['%'],
  'z': ['2']
};

class DictionaryMatch extends scoring.Match {
  DictionaryMatch({this.matchedWord, this.dictionaryName, int rank, Map<String, String> sub, bool l33t}) {
    this.rank = rank;
    this.sub = sub;
    this.l33t = l33t;
  }

  String matchedWord;
  String dictionaryName;
}

List<DictionaryMatch> dictionaryMatch(password, [Map rankedDictionaries_]) {
  // _ranked_dictionaries variable is for unit testing purposes
  var len, matches, rank, word;
  if (rankedDictionaries_ == null) {
    rankedDictionaries_ = rankedDictionaries;
  }
  matches = [];
  len = password.length;
  String password_lower = password.toLowerCase();
  rankedDictionaries_.forEach((dictionary_name, Map<String, int> ranked_dict) {
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
            ..dictionaryName = dictionary_name);
        }
      }
    }
  });
  return sorted(matches);
}

// makes a pruned copy of l33t_table that only includes password's possible substitutions
Map<String, List<String>> relevantL33tSubtable(String password, Map<String, List<String>> table) {
  Map password_chars = {};
  password.split('').forEach((String chr) {
    password_chars[chr] = true;
  });
  Map subtable = {};
  table.forEach((letter, List<String> subs) {
    List<String> relevant_subs = [];
    subs.forEach((String sub) {
      if (password_chars.containsKey(sub)) {
        relevant_subs.add(sub);
      }
    });
    if (relevant_subs.isNotEmpty) {
      subtable[letter] = relevant_subs;
    }
  });
  return subtable;
}

/**
 * not supported in dart
 * in javascript, it compares the first element, if null put it at the end, if empty at the beginnin
 * it handles list recursively
 *
 * @return the list itself
 */
List<List> sortListOfList(List<List> lists) {
  //
  int compare(List l1, List l2) {
    // null at the end
    if (l1 == null) {
      if (l2 == null) {
        return 0;
      }
      return 1;
    } else if (l2 == null) {
      return -1;
    }

    // empty at the beginning
    if (l1.isEmpty) {
      if (l2.isEmpty) {
        return 0;
      }
      return -1;
    } else if (l2.isEmpty) {
      return 1;
    }

    if (l1[0] is List) {
      return compare(l1[0], l2[0]);
    }
    return l1[0].compareTo(l2[0]);
  }
  lists.sort(compare);
  return lists;
}

// returns the list of possible 1337 replacement dictionaries for a given password
List<Map> enumerateL33tSubs(Map<String, List<String>> table) {
  List<String> keys = new List.from(table.keys);
  List<List<List<String>>> subs = [[]];

  List<List> dedup(List<List> subs_) {
    List<List> deduped = [];
    Map<String, bool> members = {};

    subs_.forEach((List sub) {
      List<List> assoc = [];
      for (int v = 0; v < sub.length; v++) {
        var k = sub[v];
        assoc.add([k, v]);
      }
      sortListOfList(assoc);
      List<String> labelParts = [];
      assoc.forEach((List row) {
        var k = row[0];
        var v = row[1];
        labelParts.add("${k},${v}");
      });
      String label = labelParts.join('-');
      // Avoid duplicates
      if (!members.containsKey(label)) {
        members[label] = true;
        deduped.add(sub);
      }
    });
    return deduped;
  }

  void helper(List<String> keys) {
    if (keys.isEmpty) {
      return;
    }
    String firstKey = keys[0];
    List<String> restKeys = keys.sublist(1);
    List<List> nextSubs = [];

    table[firstKey].forEach((String l33tChr) {
      for (List<List<String>> sub in subs) {
        int dupL33tIndex = -1;
        for (int i = 0; i < sub.length; i++) {
          if (sub[i][0] == l33tChr) {
            dupL33tIndex = i;
            break;
          }
        }
        if (dupL33tIndex == -1) {
          List subExtension = new List.from(sub);
          subExtension.addAll([
            [l33tChr, firstKey]
          ]);
          nextSubs.add(subExtension);
        } else {
          List subAlternative = new List.from(sub);
          ;
          subAlternative.insert(dupL33tIndex, 1);
          subAlternative.addAll([l33tChr, firstKey]);
          nextSubs.add(sub);
          nextSubs.add(subAlternative);
        }
      }
    });
    subs = dedup(nextSubs);
    helper(restKeys);
  }

  helper(keys);
  List subDicts = [];
  for (var sub in subs) {
    Map<String, String> subDict = {};
    sub.forEach((List data) {
      String l33t_chr = data[0];
      String chr = data[1];
      subDict[l33t_chr] = chr;
    });
    subDicts.add(subDict);
  }
  return subDicts;
}

List<DictionaryMatch> l33tMatch(String password,
    [Map<String, Map<String, int>> rankedDictionaries_, Map<String, List<String>> l33tTable_]) {
  List<DictionaryMatch> matches = [];
  if (rankedDictionaries_ == null) {
    rankedDictionaries_ = rankedDictionaries;
  }
  if (l33tTable_ == null) {
    l33tTable_ = l33tTable;
  }

  for (Map sub in enumerateL33tSubs(relevantL33tSubtable(password, l33tTable_))) {
    // corner case: password has no relevant subs.
    if (sub.isEmpty) {
      break;
    }
    String subbedPassword = translate(password, sub);
    dictionaryMatch(subbedPassword, rankedDictionaries_).forEach((DictionaryMatch match) {
      String token = password.substring(match.i, match.j + 1);
      if (token.toLowerCase() != match.matchedWord) {
        Map matchSub = {};
        sub.forEach((subbedChr, chr) {
          if (token.indexOf(subbedChr) != -1) {
            matchSub[subbedChr] = chr;
          }
        });
        match.l33t = true;
        match.token = token;
        match.sub = matchSub;
        // match.sub_display = ("#{k} -> #{v}" for k,v of match_sub).join(', ')
        // dart specific:
        // match.subDisplay don't do that, sub can be displayed using toString (subDisplay is then a getter
        matches.add(match);
      }
    });
  }
  return matches;
}
