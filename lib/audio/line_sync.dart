/// Index of the line playing at [positionMs], given line start times sorted
/// ascending. Returns -1 before the first line.
int lineIndexAt(List<int> startsMs, int positionMs) {
  var lo = 0, hi = startsMs.length - 1, ans = -1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    if (startsMs[mid] <= positionMs) {
      ans = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return ans;
}
