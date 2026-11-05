/// Completed calendar months between birth and the date being displayed.
int? completedAgeMonths(DateTime birth, DateTime date) {
  var months = (date.year - birth.year) * 12 + date.month - birth.month;
  if (date.day < birth.day) months--;
  return months < 0 ? null : months;
}

String ageInMonths(DateTime birth, DateTime date) {
  final months = completedAgeMonths(birth, date);
  if (months == null) return 'Age unavailable';
  return '$months ${months == 1 ? 'month' : 'months'}';
}
