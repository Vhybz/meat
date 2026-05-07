enum WeightUnit { kg, lb }

class WeightConverter {
  static const double kgToLb = 2.20462;

  static double toLb(double kg) => kg * kgToLb;
  static double toKg(double lb) => lb / kgToLb;

  /// Returns a formatted string with both units: "X kg / Y lb"
  static String format(double kg) {
    return "${kg.toStringAsFixed(2)} kg / ${toLb(kg).toStringAsFixed(2)} lb";
  }

  /// Returns only the values and units in a concise way
  static String formatShort(double kg) {
    return "${kg.toStringAsFixed(1)}kg | ${toLb(kg).toStringAsFixed(1)}lb";
  }
}
