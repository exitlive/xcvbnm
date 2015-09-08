library xcvbnm.scoring;

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
