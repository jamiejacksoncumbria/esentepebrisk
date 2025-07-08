import 'package:timezone/timezone.dart' as tz;

class TZ {
  /// Convert a native Dart DateTime (assumed in local zone) into UTC,
  /// by first interpreting it as Europe/Nicosia time.
  static DateTime toUtc(DateTime local) {
    final loc = tz.local; // we've set this to Nicosia
    final tzDt = tz.TZDateTime(loc,
        local.year, local.month, local.day, local.hour, local.minute, local.second);
    return tzDt.toUtc();
  }

  /// Convert a UTC DateTime from Firestore into a Nicosia-local DateTime
  static DateTime fromUtc(DateTime utc) {
    final loc = tz.local; // Nicosia
    final tzDt = tz.TZDateTime.from(utc, loc);
    return DateTime(
        tzDt.year, tzDt.month, tzDt.day,
        tzDt.hour, tzDt.minute, tzDt.second, tzDt.millisecond);
  }
}
