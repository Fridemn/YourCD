import '../utils/time_format.dart';

enum CooldownRuleType { duration, dailyReset, weeklyReset }

class CooldownRule {
  const CooldownRule({
    required this.type,
    this.durationMinutes = 7 * 24 * 60,
    this.resetHour = 6,
    this.resetMinute = 0,
    this.weekday = DateTime.saturday,
  });

  final CooldownRuleType type;
  final int durationMinutes;
  final int resetHour;
  final int resetMinute;
  final int weekday;

  DateTime nextReadyAfter(DateTime lastUse) {
    return switch (type) {
      CooldownRuleType.duration => lastUse.add(
        Duration(minutes: durationMinutes),
      ),
      CooldownRuleType.dailyReset => _nextDailyResetAfter(lastUse),
      CooldownRuleType.weeklyReset => _nextWeeklyResetAfter(lastUse),
    };
  }

  String get label {
    return switch (type) {
      CooldownRuleType.duration =>
        '使用后冷却 ${formatMinutesAsDuration(durationMinutes)}',
      CooldownRuleType.dailyReset =>
        '每天 ${formatClock(resetHour, resetMinute)} 重置',
      CooldownRuleType.weeklyReset =>
        '每周${weekdayLabel(weekday)} ${formatClock(resetHour, resetMinute)} 重置',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'durationMinutes': durationMinutes,
      'resetHour': resetHour,
      'resetMinute': resetMinute,
      'weekday': weekday,
    };
  }

  factory CooldownRule.fromJson(Map<String, dynamic> json) {
    return CooldownRule(
      type: _parseRuleType(json['type']),
      durationMinutes: _intFromJson(json['durationMinutes'], 7 * 24 * 60),
      resetHour: _intFromJson(json['resetHour'], 6).clamp(0, 23).toInt(),
      resetMinute: _intFromJson(json['resetMinute'], 0).clamp(0, 59).toInt(),
      weekday: _intFromJson(
        json['weekday'],
        DateTime.saturday,
      ).clamp(DateTime.monday, DateTime.sunday).toInt(),
    );
  }

  DateTime _nextDailyResetAfter(DateTime lastUse) {
    final sameDay = DateTime(
      lastUse.year,
      lastUse.month,
      lastUse.day,
      resetHour,
      resetMinute,
    );
    return sameDay.isAfter(lastUse)
        ? sameDay
        : sameDay.add(const Duration(days: 1));
  }

  DateTime _nextWeeklyResetAfter(DateTime lastUse) {
    final dayOffset = (weekday - lastUse.weekday) % DateTime.daysPerWeek;
    final candidateDate = DateTime(
      lastUse.year,
      lastUse.month,
      lastUse.day,
      resetHour,
      resetMinute,
    ).add(Duration(days: dayOffset));

    return candidateDate.isAfter(lastUse)
        ? candidateDate
        : candidateDate.add(const Duration(days: DateTime.daysPerWeek));
  }
}

class LifeSkill {
  const LifeSkill({
    required this.id,
    required this.name,
    required this.note,
    required this.iconKey,
    required this.imagePath,
    required this.colorValue,
    required this.rule,
    required this.lastUsedAt,
    required this.history,
    required this.notificationsEnabled,
    required this.notificationId,
  });

  static const _keep = Object();

  final String id;
  final String name;
  final String note;
  final String iconKey;
  final String? imagePath;
  final int colorValue;
  final CooldownRule rule;
  final DateTime? lastUsedAt;
  final List<SkillUse> history;
  final bool notificationsEnabled;
  final int notificationId;

  DateTime? nextAvailableAt() {
    final lastUse = lastUsedAt;
    if (lastUse == null) {
      return null;
    }
    return rule.nextReadyAfter(lastUse);
  }

  bool isAvailableAt(DateTime now) {
    final next = nextAvailableAt();
    return next == null || !next.isAfter(now);
  }

  Duration remainingAt(DateTime now) {
    final next = nextAvailableAt();
    if (next == null || !next.isAfter(now)) {
      return Duration.zero;
    }
    return next.difference(now);
  }

  double progressAt(DateTime now) {
    final lastUse = lastUsedAt;
    final next = nextAvailableAt();
    if (lastUse == null || next == null || !next.isAfter(now)) {
      return 1;
    }

    final total = next.difference(lastUse).inSeconds;
    if (total <= 0) {
      return 1;
    }

    final elapsed = now.difference(lastUse).inSeconds.clamp(0, total);
    return elapsed / total;
  }

  LifeSkill markUsed(DateTime time, {required bool forced}) {
    return copyWith(
      lastUsedAt: time,
      history: [
        SkillUse(time: time, forced: forced),
        ...history,
      ].take(80).toList(growable: false),
    );
  }

  LifeSkill copyWith({
    String? name,
    String? note,
    String? iconKey,
    Object? imagePath = _keep,
    int? colorValue,
    CooldownRule? rule,
    DateTime? lastUsedAt,
    bool clearLastUsedAt = false,
    List<SkillUse>? history,
    bool? notificationsEnabled,
    int? notificationId,
  }) {
    return LifeSkill(
      id: id,
      name: name ?? this.name,
      note: note ?? this.note,
      iconKey: iconKey ?? this.iconKey,
      imagePath: identical(imagePath, _keep)
          ? this.imagePath
          : imagePath as String?,
      colorValue: colorValue ?? this.colorValue,
      rule: rule ?? this.rule,
      lastUsedAt: clearLastUsedAt ? null : lastUsedAt ?? this.lastUsedAt,
      history: history ?? this.history,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'iconKey': iconKey,
      'imagePath': imagePath,
      'colorValue': colorValue,
      'rule': rule.toJson(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'history': history.map((entry) => entry.toJson()).toList(),
      'notificationsEnabled': notificationsEnabled,
      'notificationId': notificationId,
    };
  }

  factory LifeSkill.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'];
    final history = <SkillUse>[];
    if (historyJson is List) {
      for (final item in historyJson) {
        if (item is Map) {
          history.add(SkillUse.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return LifeSkill(
      id: (json['id'] as String?) ?? createSkillId(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '未命名',
      note: (json['note'] as String?) ?? '',
      iconKey: (json['iconKey'] as String?) ?? 'restaurant',
      imagePath: json['imagePath'] as String?,
      colorValue: _intFromJson(json['colorValue'], 0xFF0F766E),
      rule: json['rule'] is Map
          ? CooldownRule.fromJson(
              Map<String, dynamic>.from(json['rule'] as Map),
            )
          : const CooldownRule(type: CooldownRuleType.duration),
      lastUsedAt: DateTime.tryParse((json['lastUsedAt'] as String?) ?? ''),
      history: history,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      notificationId: _intFromJson(
        json['notificationId'],
        createNotificationId(),
      ),
    );
  }
}

class SkillUse {
  const SkillUse({required this.time, required this.forced});

  final DateTime time;
  final bool forced;

  Map<String, dynamic> toJson() {
    return {'time': time.toIso8601String(), 'forced': forced};
  }

  factory SkillUse.fromJson(Map<String, dynamic> json) {
    return SkillUse(
      time:
          DateTime.tryParse((json['time'] as String?) ?? '') ?? DateTime.now(),
      forced: json['forced'] as bool? ?? false,
    );
  }
}

String createSkillId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

int createNotificationId() {
  return DateTime.now().microsecondsSinceEpoch.remainder(2147480000);
}

CooldownRuleType _parseRuleType(Object? value) {
  for (final type in CooldownRuleType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return CooldownRuleType.duration;
}

int _intFromJson(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
