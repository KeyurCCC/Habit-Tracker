class NotificationPreference {
  final bool enabledReminders;
  final int eveningReminderHour; // 0-23
  final int eveningReminderMinute; // 0-59
  final int lateReminderHour; // 0-23
  final int lateReminderMinute; // 0-59

  NotificationPreference({
    this.enabledReminders = true,
    this.eveningReminderHour = 21,
    this.eveningReminderMinute = 0,
    this.lateReminderHour = 23,
    this.lateReminderMinute = 55,
  });

  Map<String, dynamic> toMap() => {
    'enabledReminders': enabledReminders,
    'eveningReminderHour': eveningReminderHour,
    'eveningReminderMinute': eveningReminderMinute,
    'lateReminderHour': lateReminderHour,
    'lateReminderMinute': lateReminderMinute,
  };

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      enabledReminders: map['enabledReminders'] ?? true,
      eveningReminderHour: map['eveningReminderHour'] ?? 21,
      eveningReminderMinute: map['eveningReminderMinute'] ?? 0,
      lateReminderHour: map['lateReminderHour'] ?? 23,
      lateReminderMinute: map['lateReminderMinute'] ?? 55,
    );
  }

  NotificationPreference copyWith({
    bool? enabledReminders,
    int? eveningReminderHour,
    int? eveningReminderMinute,
    int? lateReminderHour,
    int? lateReminderMinute,
  }) {
    return NotificationPreference(
      enabledReminders: enabledReminders ?? this.enabledReminders,
      eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
      eveningReminderMinute: eveningReminderMinute ?? this.eveningReminderMinute,
      lateReminderHour: lateReminderHour ?? this.lateReminderHour,
      lateReminderMinute: lateReminderMinute ?? this.lateReminderMinute,
    );
  }
}
