import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/progression/ranks.dart';

void main() {
  test('rank mapping respects levels per rank', () {
    expect(rankForLevel(1), 'Recruit');
    expect(rankForLevel(3), 'Recruit');
    expect(rankForLevel(4), 'Private');
    expect(rankForLevel(25), 'Elite Operator');
  });

  test('in-rank progress and levels-to-next are computed', () {
    expect(inRankProgressForLevel(1), closeTo(1 / 3, 0.0001));
    expect(inRankProgressForLevel(3), closeTo(1, 0.0001));
    expect(levelsToNextRank(5), 1);
  });
}
