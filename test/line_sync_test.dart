import 'package:flutter_test/flutter_test.dart';
import 'package:lt/audio/line_sync.dart';

void main() {
  const starts = [1200, 4800, 10600];

  test('finds the line at the playhead', () {
    expect(lineIndexAt(starts, 0), -1);
    expect(lineIndexAt(starts, 1200), 0);
    expect(lineIndexAt(starts, 4799), 0);
    expect(lineIndexAt(starts, 11100), 2);
    expect(lineIndexAt(starts, 999999), 2);
    expect(lineIndexAt(const [], 500), -1);
  });
}
