class NotificationSettings {
  final bool pushRecipe;
  final bool pushSocial;
  final bool pushReminder;
  final bool pushSystem;
  final DateTime? updatedAtClient;

  const NotificationSettings({
    required this.pushRecipe,
    required this.pushSocial,
    required this.pushReminder,
    required this.pushSystem,
    this.updatedAtClient,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    bool readBool(String key) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return true;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return NotificationSettings(
      pushRecipe: readBool('pushRecipe'),
      pushSocial: readBool('pushSocial'),
      pushReminder: readBool('pushReminder'),
      pushSystem: readBool('pushSystem'),
      updatedAtClient: parseDate(json['updatedAtClient']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushRecipe': pushRecipe,
      'pushSocial': pushSocial,
      'pushReminder': pushReminder,
      'pushSystem': pushSystem,
      'updatedAtClient': updatedAtClient?.toIso8601String(),
    };
  }

  NotificationSettings copyWith({
    bool? pushRecipe,
    bool? pushSocial,
    bool? pushReminder,
    bool? pushSystem,
    DateTime? updatedAtClient,
  }) {
    return NotificationSettings(
      pushRecipe: pushRecipe ?? this.pushRecipe,
      pushSocial: pushSocial ?? this.pushSocial,
      pushReminder: pushReminder ?? this.pushReminder,
      pushSystem: pushSystem ?? this.pushSystem,
      updatedAtClient: updatedAtClient ?? this.updatedAtClient,
    );
  }
}
