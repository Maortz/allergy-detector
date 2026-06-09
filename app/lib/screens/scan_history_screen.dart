import 'package:flutter/material.dart';
import '../models/scan_history_entry.dart';
import '../services/scan_history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/status_badge.dart';

/// Full scan history (`nav-drawer-user.md §3` row 2), backed by
/// [ScanHistoryService]. Shows the no-scans empty state until the user has
/// resolved at least one product; otherwise lists every persisted scan,
/// newest-first.
class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<ScanHistoryEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await ScanHistoryService.recentScans();
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('היסטוריית סריקה'),
          backgroundColor: AppColors.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: entries == null
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
                ? const _ScanHistoryEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        _ScanHistoryRow(entry: entries[index]),
                  ),
      ),
    );
  }
}

class _ScanHistoryEmpty extends StatelessWidget {
  const _ScanHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 72,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'אין סריקות עדיין',
              style: AppTypography.h3.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'מוצרים שתסרוק יופיעו כאן לסקירה מהירה',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHistoryRow extends StatelessWidget {
  final ScanHistoryEntry entry;

  const _ScanHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: entry.imageUrl != null
                ? Image.network(
                    entry.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.shopping_basket,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : const Icon(
                    Icons.shopping_basket,
                    color: AppColors.onSurfaceVariant,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nameHe,
                  style: AppTypography.labelBold.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                if (entry.brandNameHe != null &&
                    entry.brandNameHe!.isNotEmpty)
                  Text(
                    entry.brandNameHe!,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: entry.status),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.relativeTime(),
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
