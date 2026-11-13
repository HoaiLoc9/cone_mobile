String formatScore(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}
