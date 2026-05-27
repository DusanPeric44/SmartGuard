extension JsonDateParsing on dynamic {
  DateTime? toLocalDateTime() {
    if (this == null) return null;

    return DateTime.tryParse(toString())?.toLocal();
  }
}
