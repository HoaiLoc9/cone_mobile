String formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
}

String compactDate(DateTime? value) {
  if (value == null) {
    return '-';
  }

  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}
