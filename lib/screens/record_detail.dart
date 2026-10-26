import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/official_record.dart';
import '../services/user_profile.dart';
import '../utils/formatters.dart';
import '../widgets/common/bookmark_button.dart';
import '../widgets/common/status_badge.dart';
import 'ecoguide_chat.dart';

class RecordDetailScreen extends StatelessWidget {
  final OfficialRecord record;

  const RecordDetailScreen({super.key, required this.record});

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(record.sourceUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the source link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Detail'),
        actions: [
          SaveToggleButton(
            isSavedStream: UserProfileService().isRecordSavedStream(record.id),
            onToggle: (save) =>
                UserProfileService().setRecordSaved(record.id, save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.officialBadge.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  record.icon,
                  color: AppTheme.officialBadge,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge(isOfficial: true),
                    const SizedBox(height: 6),
                    Text(
                      record.siteName,
                      style: AppTheme.h2.copyWith(
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EcoGuideScreen(item: record)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask EcoGuide AI about this'),
              style: AppTheme.primaryButtonOf(context).copyWith(
                backgroundColor: const WidgetStatePropertyAll(AppTheme.ai),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: AppTheme.spaceLarge,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          _DetailCard(
            title: 'Location',
            rows: [
              _DetailRow(
                icon: Icons.place_outlined,
                label: 'Address',
                value: record.address,
              ),
              _DetailRow(
                icon: Icons.location_city_outlined,
                label: 'City / ZIP',
                value: record.cityStateZip,
              ),
              _DetailRow(
                icon: Icons.map_outlined,
                label: 'County',
                value: record.county,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          _DetailCard(
            title: 'Inspection',
            rows: [
              _DetailRow(
                icon: Icons.assignment_outlined,
                label: 'Type',
                value: record.inspectionType,
              ),
              _DetailRow(
                icon: Icons.event_outlined,
                label: 'Date',
                value: formatDate(record.date),
              ),
              if (record.inspectionReason.isNotEmpty)
                _DetailRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Reason',
                  value: record.inspectionReason,
                ),
              _DetailRow(
                icon: Icons.fact_check_outlined,
                label: 'Status',
                value: record.siteStatus,
              ),
              if (record.siteCondition.isNotEmpty)
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Condition',
                  value: record.siteCondition,
                ),
              if (record.recommendedActions.isNotEmpty)
                _DetailRow(
                  icon: Icons.checklist_rounded,
                  label: 'Recommended Actions',
                  value: record.recommendedActions,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          _DetailCard(
            title: 'Permits',
            rows: [
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'Permit No.',
                value: record.permitNo,
              ),
              _DetailRow(
                icon: Icons.numbers_rounded,
                label: 'NPDES No.',
                value: record.npdesNo,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLightOf(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.source_outlined,
                  color: AppTheme.textSecondaryOf(context),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Source: ${AppConstants.dataSourceName}',
                    style: AppTheme.subtitle.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openSource(context),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          if (record.locationApproximate) ...[
            const SizedBox(height: AppTheme.spaceSmall),
            Row(
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  size: 15,
                  color: AppTheme.textTertiaryOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "This record's map location is approximate — MDE's address for "
                    "this site couldn't be matched to an exact point.",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textTertiaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;

  const _DetailCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowOf(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.caption.copyWith(
              color: AppTheme.textTertiaryOf(context),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryOf(context)),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textTertiaryOf(context),
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
