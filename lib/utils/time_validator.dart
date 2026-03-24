class TimeValidator {
  static final RegExp _hhmmPattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static bool isValidHHmm(String value) {
    return _hhmmPattern.hasMatch(value);
  }

  static String normalizeOrFallback(String value, {String fallback = '23:59'}) {
    return isValidHHmm(value) ? value : fallback;
  }
}
