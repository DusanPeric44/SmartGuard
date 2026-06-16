import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/dashboard/model/dashboard_models.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_chart_section.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_recent_activity_card.dart';

class DashboardBottomSection extends StatelessWidget {
  const DashboardBottomSection({super.key, required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final storage = DashboardChartSection(overview: overview);
        final activity = DashboardRecentActivityCard(overview: overview);

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: storage),
              const SizedBox(width: 16),
              Expanded(child: activity),
            ],
          );
        }

        return Column(
          children: [storage, const SizedBox(height: 16), activity],
        );
      },
    );
  }
}
