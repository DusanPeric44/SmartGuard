String formatAlarmDate(DateTime? dt) {
  if (dt == null) return '';
  final d = dt.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[d.month - 1];
  final day = d.day.toString().padLeft(2, '0');
  final year = d.year.toString();
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final hour = hour12.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  return '$month $day, $year $hour:$minute $ampm';
}
