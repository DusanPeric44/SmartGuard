import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_status.dart';

class AlarmsControlsRow extends StatelessWidget {
  const AlarmsControlsRow({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleButtons(
              isSelected: [
                tabIndex == 0,
                tabIndex == 1,
                tabIndex == 2,
                tabIndex == 3,
                tabIndex == 4,
              ],
              onPressed: onTabChanged,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(AlertStatusNames.pending),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(AlertStatusNames.confirmed),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(AlertStatusNames.resolved),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(AlertStatusNames.dismissed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
