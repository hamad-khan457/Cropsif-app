class NotificationPrefsModel {
  final bool pushAlerts;
  final bool emailDigest;
  final bool smsAlerts;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  const NotificationPrefsModel({
    this.pushAlerts = true,
    this.emailDigest = true,
    this.smsAlerts = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPrefsModel.fromJson(Map<String, dynamic> json) =>
      NotificationPrefsModel(
        pushAlerts:      json['push_alerts']       as bool? ?? true,
        emailDigest:     json['email_digest']       as bool? ?? true,
        smsAlerts:       json['sms_alerts']         as bool? ?? false,
        quietHoursStart: json['quiet_hours_start']  as String?,
        quietHoursEnd:   json['quiet_hours_end']    as String?,
      );

  Map<String, dynamic> toJson() => {
        'pushAlerts':      pushAlerts,
        'emailDigest':     emailDigest,
        'smsAlerts':       smsAlerts,
        if (quietHoursStart != null) 'quietHoursStart': quietHoursStart,
        if (quietHoursEnd   != null) 'quietHoursEnd':   quietHoursEnd,
      };

  NotificationPrefsModel copyWith({
    bool? pushAlerts,
    bool? emailDigest,
    bool? smsAlerts,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool clearQuietHours = false,
  }) =>
      NotificationPrefsModel(
        pushAlerts:      pushAlerts      ?? this.pushAlerts,
        emailDigest:     emailDigest     ?? this.emailDigest,
        smsAlerts:       smsAlerts       ?? this.smsAlerts,
        quietHoursStart: clearQuietHours ? null : quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd:   clearQuietHours ? null : quietHoursEnd   ?? this.quietHoursEnd,
      );
}