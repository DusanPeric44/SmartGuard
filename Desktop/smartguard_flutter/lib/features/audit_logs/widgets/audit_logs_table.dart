import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/audit_logs/model/audit_log_models.dart';
import 'package:smartguard_flutter/features/audit_logs/widgets/audit_logs_format.dart';

class AuditLogsTable extends StatelessWidget {
  const AuditLogsTable({
    super.key,
    required this.rows,
    required this.rowBusy,
    required this.onOpenDetails,
  });

  final List<AuditLogRow> rows;
  final Map<String, bool> rowBusy;
  final ValueChanged<AuditLogRow> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Resource')),
            DataColumn(label: Text('Details')),
            DataColumn(label: Text('IP')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: [for (final r in rows) _row(context, r)],
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, AuditLogRow r) {
    final key = r.id.toString();
    final busy = rowBusy[key] == true;
    return DataRow(
      cells: [
        DataCell(Text(_timestampLabel(r.timestamp))),
        DataCell(Text(r.user)),
        DataCell(Text(r.action)),
        DataCell(Text(r.resource)),
        DataCell(
          SizedBox(
            width: 360,
            child: Text(
              r.details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(r.ipAddress)),
        DataCell(Text(r.status)),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: 'Details',
                onPressed: busy ? null : () => onOpenDetails(r),
                icon: busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _timestampLabel(DateTime? dt) {
  if (dt == null) return '-';
  return '${yyyyMmDd(dt)} ${_hhMm(dt)}';
}

String _hhMm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
