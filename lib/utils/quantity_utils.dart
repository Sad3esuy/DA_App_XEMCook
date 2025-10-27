class QuantityUtils {
  const QuantityUtils._();

  static double? parse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;

    final fraction = _parseFraction(normalized);
    if (fraction != null) return fraction;

    final rangeMatch = _rangePattern.firstMatch(normalized);
    if (rangeMatch != null) {
      final start = double.tryParse(rangeMatch.group(1)!);
      final end = double.tryParse(rangeMatch.group(2)!);
      if (start != null && end != null) {
        return (start + end) / 2;
      }
    }

    final numberMatch = _numberPattern.firstMatch(normalized);
    if (numberMatch != null) {
      return double.tryParse(numberMatch.group(1)!);
    }

    return null;
  }

  static String format(double value) {
    final abs = value.abs();
    final precision = abs >= 1000
        ? 0
        : abs >= 100
            ? 1
            : abs >= 1
                ? 2
                : 3;
    final formatted = value.toStringAsFixed(precision);
    return formatted.replaceAll(RegExp(r'(?<=\d)0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  static String? mergeDisplay(String? a, String? b) {
    if (a == null || a.trim().isEmpty) return b;
    if (b == null || b.trim().isEmpty) return a;
    final normalizedA = a.trim();
    final normalizedB = b.trim();
    if (normalizedA == normalizedB) return normalizedA;
    return '$normalizedA + $normalizedB';
  }

  static double? _parseFraction(String input) {
    final match = _mixedFractionPattern.firstMatch(input);
    if (match != null) {
      final whole = match.group(1);
      final numerator = match.group(2);
      final denominator = match.group(3);
      if (numerator != null && denominator != null) {
        final numValue = double.tryParse(numerator);
        final denValue = double.tryParse(denominator);
        if (numValue != null && denValue != null && denValue != 0) {
          final fraction = numValue / denValue;
          final wholeValue = whole != null ? double.tryParse(whole) ?? 0 : 0;
          return wholeValue + fraction;
        }
      }
    }

    final simple = _fractionPattern.firstMatch(input);
    if (simple != null) {
      final numerator = double.tryParse(simple.group(1)!);
      final denominator = double.tryParse(simple.group(2)!);
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }
    return null;
  }

  static final RegExp _numberPattern = RegExp(r'(-?\d+(?:\.\d+)?)');
  static final RegExp _fractionPattern = RegExp(r'^(\d+)\s*/\s*(\d+)$');
  static final RegExp _mixedFractionPattern =
      RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$');
  static final RegExp _rangePattern =
      RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$');
}
