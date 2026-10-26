import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';

// empty set = All Counties (no filter)
class CountyDropdown extends StatelessWidget {
  final Set<String> value;
  final ValueChanged<Set<String>> onChanged;

  const CountyDropdown({super.key, required this.value, required this.onChanged});

  String get _label {
    if (value.isEmpty) return 'All Counties';
    if (value.length == 1) return value.first;
    return '${value.length} counties selected';
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge))),
      builder: (context) => _CountySheet(initial: value),
    );
    // null means the sheet was dismissed without hitting "Done" - leave as is
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.surfaceLightOf(context), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: AppTheme.textSecondaryOf(context), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_label, style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimaryOf(context)))),
            Icon(Icons.expand_more_rounded, color: AppTheme.textSecondaryOf(context)),
          ],
        ),
      ),
    );
  }
}

class _CountySheet extends StatefulWidget {
  final Set<String> initial;
  const _CountySheet({required this.initial});

  @override
  State<_CountySheet> createState() => _CountySheetState();
}

class _CountySheetState extends State<_CountySheet> {
  late final Set<String> _working = Set.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spaceLarge, AppTheme.spaceMedium, AppTheme.spaceLarge, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Choose Counties', style: AppTheme.h3.copyWith(color: AppTheme.textPrimaryOf(context)))),
                  if (_working.isNotEmpty)
                    TextButton(onPressed: () => setState(_working.clear), child: const Text('Clear')),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    title: const Text('All Counties'),
                    value: _working.isEmpty,
                    onChanged: (_) => setState(_working.clear),
                  ),
                  const Divider(height: 1),
                  for (final county in AppConstants.scopedCounties)
                    CheckboxListTile(
                      title: Text(county),
                      value: _working.contains(county),
                      onChanged: (checked) => setState(() => checked == true ? _working.add(county) : _working.remove(county)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _working),
                  style: AppTheme.primaryButtonOf(context),
                  child: Text(_working.isEmpty ? 'Show All Counties' : 'Show ${_working.length} Selected'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
