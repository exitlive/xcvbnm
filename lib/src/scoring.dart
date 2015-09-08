library xcvbnm.scoring;

import 'dart:math' as math;

const num _secondsPerGuess = .010 / 100;

num nCk(n, k) {
  var d, l, r, ref;
  if (k > n) {
    return 0;
  }
  if (k == 0) {
    return 1;
  }
  r = 1;

  d = 1;
  l = 1;
  ref = k;
  for (; 1 <= ref ? l <= ref : l >= ref; d = 1 <= ref ? ++l : --l) {
    r *= n;
    r /= d;
    n -= 1;
  }
  return r;
}

num lg(num n) {
  return math.log(n) / math.log(2);
}

num entropyToCrackTime(num entropy) {
  return .5 * math.pow(2, entropy) * _secondsPerGuess;
}

int crackTimeToScore(seconds) {
  if (seconds < math.pow(10, 2)) {
    return 0;
  }
  if (seconds < math.pow(10, 4)) {
    return 1;
  }
  if (seconds < math.pow(10, 6)) {
    return 2;
  }
  if (seconds < math.pow(10, 8)) {
    return 3;
  }
  return 4;
}

int calcBruteforceCardinality(String password) {
  var c, cp, digits, l, latin1_letters, latin1_symbols, len, len1, lower, m, max_cp, min_cp, ord, range, ref1, ref2, symbols, upper;

  List unicode_codepoints = [];
  ref1 = password.split('');
  len = ref1.length;
  for (l = 0; l < len; l++) {
    String chr = ref1[l];
    ord = chr.codeUnitAt(0);
    if ((0x30 <= ord && ord <= 0x39)) {
      digits = true;
    } else if ((0x41 <= ord && ord <= 0x5a)) {
      upper = true;
    } else if ((0x61 <= ord && ord <= 0x7a)) {
      lower = true;
    } else if (ord <= 0x7f) {
      symbols = true;
    } else if ((0x80 <= ord && ord <= 0xBF)) {
      latin1_symbols = true;
    } else if ((0xC0 <= ord && ord <= 0xFF)) {
      latin1_letters = true;
    } else if (ord > 0xFF) {
      unicode_codepoints.add(ord);
    }
  }
  c = 0;
  if (digits == true) {
    c += 10;
  }
  if (upper == true) {
    c += 26;
  }
  if (lower == true) {
    c += 26;
  }
  if (symbols == true) {
    c += 33;
  }
  if (latin1_symbols == true) {
    c += 64;
  }
  if (latin1_letters == true) {
    c += 64;
  }
  if (unicode_codepoints.length > 0) {
    min_cp = max_cp = unicode_codepoints[0];
    ref2 = unicode_codepoints.sublist(1);
    len1 = ref2.length;
    for (m = 0; m < len1; m++) {
      cp = ref2[m];
      if (cp < min_cp) {
        min_cp = cp;
      }
      if (cp > max_cp) {
        max_cp = cp;
      }
    }
    range = max_cp - min_cp + 1;
    if (range < 40) {
      range = 40;
    }
    if (range > 100) {
      range = 100;
    }
    c += range;
  }
  return c;
}

String displayTime(num seconds) {
  var base, century, day, display_num, display_str, hour, minute, month, ref, year;
  minute = 60;
  hour = minute * 60;
  day = hour * 24;
  month = day * 31;
  year = month * 12;
  century = year * 100;
  if (seconds < minute) {
    ref = [seconds, "${seconds} second"];
  } else if (seconds < hour) {
    base = (seconds / minute).round();
    ref = [base, "${base} minute"];
  } else if (seconds < day) {
    base = (seconds / hour).round();
    ref = [base, "${base} hour"];
  } else if (seconds < month) {
    base = (seconds / day).round();
    ref = [base, "${base} day"];
  } else if (seconds < year) {
    base = (seconds / month).round();
    ref = [base, "${base} month"];
  } else if (seconds < century) {
    base = (seconds / year).round();
    ref = [base, "${base} year"];
  } else {
    ref = [null, 'centuries'];
  }
  display_num = ref[0];
  display_str = ref[1];
  if ((display_num != null) && display_num != 1) {
    display_str += 's';
  }
  return display_str;
}