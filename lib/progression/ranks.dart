const List<String> kRankLadder = [
  'Recruit',
  'Private',
  'Lance Corporal',
  'Corporal',
  'Sergeant',
  'Staff Sergeant',
  'Warrant Officer',
  'Elite Operator',
];

const int kLevelsPerRank = 3;

String rankForLevel(int level) {
  final safeLevel = level < 1 ? 1 : level;
  final index =
      ((safeLevel - 1) ~/ kLevelsPerRank).clamp(0, kRankLadder.length - 1);
  return kRankLadder[index];
}

int rankIndexForLevel(int level) {
  final safeLevel = level < 1 ? 1 : level;
  return ((safeLevel - 1) ~/ kLevelsPerRank).clamp(0, kRankLadder.length - 1);
}

double inRankProgressForLevel(int level) {
  final safeLevel = level < 1 ? 1 : level;
  final inRank = (safeLevel - 1) % kLevelsPerRank;
  if (rankForLevel(safeLevel) == kRankLadder.last) return 1;
  return ((inRank + 1) / kLevelsPerRank).clamp(0, 1);
}

int levelsToNextRank(int level) {
  final safeLevel = level < 1 ? 1 : level;
  if (rankForLevel(safeLevel) == kRankLadder.last) return 0;
  final inRank = (safeLevel - 1) % kLevelsPerRank;
  return kLevelsPerRank - (inRank + 1);
}
