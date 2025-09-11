import 'package:flutter/material.dart';

import '../../domain/repositories/gmail_repository.dart';

class GmailSyncDialog extends StatefulWidget {
  final Function(SyncOptions) onSyncSelected;

  const GmailSyncDialog({super.key, required this.onSyncSelected});

  @override
  State<GmailSyncDialog> createState() => _GmailSyncDialogState();
}

class _GmailSyncDialogState extends State<GmailSyncDialog> {
  SyncDuration _selectedDuration = SyncDuration.oneMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final fg = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white70 : Colors.black54;
    // Intentionally not used at root level; borders are set per-section

    return AlertDialog(
      backgroundColor: bg,
      title: const Text(
        'Gmail Sync Settings',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      titleTextStyle: TextStyle(
        color: fg,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How much email data would you like to store?',
              style: TextStyle(fontSize: 14, color: subtle),
            ),
            const SizedBox(height: 16),
            ..._buildDurationOptions(),
            if (_selectedDuration == SyncDuration.custom) ...[
              const SizedBox(height: 16),
              _buildCustomDatePicker(),
            ],
            const SizedBox(height: 16),
            _buildStorageInfo(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: subtle)),
        ),
        ElevatedButton(
          onPressed: _isValidSelection() ? _onSyncPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.white : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
          child: const Text('Start Sync'),
        ),
      ],
    );
  }

  List<Widget> _buildDurationOptions() {
    return SyncDuration.values.map((duration) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final fg = isDark ? Colors.white : Colors.black;
      final subtle = isDark ? Colors.white70 : Colors.black54;

      return RadioListTile<SyncDuration>(
        value: duration,
        groupValue: _selectedDuration,
        onChanged: (value) {
          setState(() {
            _selectedDuration = value!;
            if (value != SyncDuration.custom) {
              _customStartDate = null;
              _customEndDate = null;
            }
          });
        },
        title: Text(duration.displayName, style: TextStyle(color: fg)),
        subtitle: duration != SyncDuration.custom
            ? Text(
                _getDurationSubtitle(duration),
                style: TextStyle(color: subtle),
              )
            : Text('Select custom date range', style: TextStyle(color: subtle)),
        contentPadding: EdgeInsets.zero,
        activeColor: isDark ? Colors.white : Colors.black,
      );
    }).toList();
  }

  Widget _buildCustomDatePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final border = isDark ? Colors.white24 : Colors.black26;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Date Range',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: fg,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'From',
                  date: _customStartDate,
                  onPressed: () => _selectStartDate(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: 'To',
                  date: _customEndDate,
                  onPressed: () => _selectEndDate(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final subtle = isDark ? Colors.white70 : Colors.black54;
    final border = isDark ? Colors.white38 : Colors.black38;

    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: subtle)),
            const SizedBox(height: 2),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: TextStyle(fontSize: 14, color: date != null ? fg : subtle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final icon = isDark ? Colors.white70 : Colors.black54;
    final text = isDark ? Colors.white70 : Colors.black87;

    int estimatedDays = _selectedDuration.days;
    if (_selectedDuration == SyncDuration.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      estimatedDays = _customEndDate!.difference(_customStartDate!).inDays;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Approximately $estimatedDays days of email data will be synced. '
              'This includes subject, sender, and content for PDA analysis.',
              style: TextStyle(fontSize: 12, color: text),
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationSubtitle(SyncDuration duration) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: duration.days));
    return 'From ${startDate.day}/${startDate.month}/${startDate.year} to today';
  }

  bool _isValidSelection() {
    if (_selectedDuration == SyncDuration.custom) {
      return _customStartDate != null &&
          _customEndDate != null &&
          _customStartDate!.isBefore(_customEndDate!);
    }
    return true;
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _customEndDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _customStartDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? DateTime.now(),
      firstDate:
          _customStartDate ??
          DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _customEndDate = date;
      });
    }
  }

  void _onSyncPressed() {
    final syncOptions = SyncOptions(
      duration: _selectedDuration,
      customStartDate: _customStartDate,
      customEndDate: _customEndDate,
    );

    widget.onSyncSelected(syncOptions);
    Navigator.of(context).pop();
  }
}

// Convenience function to show the dialog
Future<void> showGmailSyncDialog(
  BuildContext context, {
  required Function(SyncOptions) onSyncSelected,
}) {
  return showDialog(
    context: context,
    builder: (context) => GmailSyncDialog(onSyncSelected: onSyncSelected),
  );
}
