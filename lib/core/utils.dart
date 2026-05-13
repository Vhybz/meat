enum WeightUnit { kg, lb, unit }

class WeightConverter {
  static const double kgToLb = 2.20462;

  static double toLb(double kg) => kg * kgToLb;
  static double toKg(double lb) => lb / kgToLb;

  /// Returns a formatted string with both units: "X kg / Y lb"
  static String format(double value, {WeightUnit unit = WeightUnit.kg}) {
    if (unit == WeightUnit.unit) return "${value.toInt()} unit(s)";
    return "${value.toStringAsFixed(2)} kg / ${toLb(value).toStringAsFixed(2)} lb";
  }

  /// Returns only the values and units in a concise way
  static String formatShort(double value, {WeightUnit unit = WeightUnit.kg}) {
    if (unit == WeightUnit.unit) return "${value.toInt()} pcs";
    return "${value.toStringAsFixed(1)}kg | ${toLb(value).toStringAsFixed(1)}lb";
  }
}
