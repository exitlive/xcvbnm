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
