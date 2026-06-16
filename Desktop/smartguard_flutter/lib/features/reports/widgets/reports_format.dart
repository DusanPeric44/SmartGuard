String? fmtDate(DateTime? dt) {
  if (dt == null) return null;
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$d.$m.$y';
}

String? fmtDateTime(DateTime? dt) {
  if (dt == null) return null;
  final date = fmtDate(dt);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$date $h:$m';
}
