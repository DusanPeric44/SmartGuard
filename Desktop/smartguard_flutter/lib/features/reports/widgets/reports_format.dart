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

/// Compact, filesystem-safe timestamp for use inside a file name (yyyyMMdd_HHmmss).
/// Deliberately not fmtDateTime: that format contains ':' and '.', which are invalid in
/// Windows file names. Mirrors the backend's own yyyyMMdd convention in ReportsService.
String fmtFileStamp(DateTime? dt) {
  final value = dt ?? DateTime.now();
  final y = value.year.toString().padLeft(4, '0');
  final mo = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final h = value.hour.toString().padLeft(2, '0');
  final mi = value.minute.toString().padLeft(2, '0');
  final s = value.second.toString().padLeft(2, '0');
  return '$y$mo${d}_$h$mi$s';
}
