class PersonalRecordEntry {
  const PersonalRecordEntry({
    required this.value,
    required this.dateKey,
  });

  final int value;
  final String? dateKey;

  PersonalRecordEntry copyWith({
    int? value,
    String? dateKey,
    bool clearDateKey = false,
  }) {
    return PersonalRecordEntry(
      value: value ?? this.value,
      dateKey: clearDateKey ? null : (dateKey ?? this.dateKey),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'dateKey': dateKey,
    };
  }

  factory PersonalRecordEntry.fromMap(Map<String, dynamic> map) {
    return PersonalRecordEntry(
      value: map['value'] as int? ?? 0,
      dateKey: map['dateKey'] as String?,
    );
  }
}

class PersonalRecords {
  const PersonalRecords({
    required this.longestProtocolSec,
    required this.bestCompletionPercent,
    required this.fastestFullProtocolSec,
    required this.mostProtocolsInWeek,
    required this.bestChain,
  });

  factory PersonalRecords.initial() {
    return const PersonalRecords(
      longestProtocolSec: PersonalRecordEntry(value: 0, dateKey: null),
      bestCompletionPercent: PersonalRecordEntry(value: 0, dateKey: null),
      fastestFullProtocolSec: PersonalRecordEntry(value: 0, dateKey: null),
      mostProtocolsInWeek: PersonalRecordEntry(value: 0, dateKey: null),
      bestChain: PersonalRecordEntry(value: 0, dateKey: null),
    );
  }

  final PersonalRecordEntry longestProtocolSec;
  final PersonalRecordEntry bestCompletionPercent;
  final PersonalRecordEntry fastestFullProtocolSec;
  final PersonalRecordEntry mostProtocolsInWeek;
  final PersonalRecordEntry bestChain;

  PersonalRecords copyWith({
    PersonalRecordEntry? longestProtocolSec,
    PersonalRecordEntry? bestCompletionPercent,
    PersonalRecordEntry? fastestFullProtocolSec,
    PersonalRecordEntry? mostProtocolsInWeek,
    PersonalRecordEntry? bestChain,
  }) {
    return PersonalRecords(
      longestProtocolSec: longestProtocolSec ?? this.longestProtocolSec,
      bestCompletionPercent:
          bestCompletionPercent ?? this.bestCompletionPercent,
      fastestFullProtocolSec:
          fastestFullProtocolSec ?? this.fastestFullProtocolSec,
      mostProtocolsInWeek: mostProtocolsInWeek ?? this.mostProtocolsInWeek,
      bestChain: bestChain ?? this.bestChain,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'longestProtocolSec': longestProtocolSec.toMap(),
      'bestCompletionPercent': bestCompletionPercent.toMap(),
      'fastestFullProtocolSec': fastestFullProtocolSec.toMap(),
      'mostProtocolsInWeek': mostProtocolsInWeek.toMap(),
      'bestChain': bestChain.toMap(),
    };
  }

  factory PersonalRecords.fromMap(Map<String, dynamic> map) {
    PersonalRecordEntry read(String key) {
      final raw = map[key];
      if (raw is Map<String, dynamic>) {
        return PersonalRecordEntry.fromMap(raw);
      }
      return const PersonalRecordEntry(value: 0, dateKey: null);
    }

    return PersonalRecords(
      longestProtocolSec: read('longestProtocolSec'),
      bestCompletionPercent: read('bestCompletionPercent'),
      fastestFullProtocolSec: read('fastestFullProtocolSec'),
      mostProtocolsInWeek: read('mostProtocolsInWeek'),
      bestChain: read('bestChain'),
    );
  }
}
