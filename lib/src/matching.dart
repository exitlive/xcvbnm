library xcvbnm.matching;

import "../xcvbnm.dart" as xcvbnm;
import "scoring.dart" as scoring;

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