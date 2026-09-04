import 'package:flutter/material.dart';

import '../models/gate.dart';
import '../models/wird.dart';
import '../notifications/notification_manager.dart';
import '../store/store_scope.dart';
import '../theme/wrd_colors.dart';
import '../util/arabic.dart';
import '../widgets/components.dart';

/// Compose your own wird — a personal duʿāʼ, a dhikr count, or an intention.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  Gate _gate = Gate.morning;
  bool _hasCount = false;
  int _targetCount = 7;
  bool _hasReminder = false;
  int _reminderMinutes = 6 * 60;

  bool get _canSave => _title.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderMinutes ~/ 60, minute: _reminderMinutes % 60),
    );
    if (picked != null) setState(() => _reminderMinutes = picked.hour * 60 + picked.minute);
  }

  void _save() {
    final store = StoreScope.read(context);
    final text = _text.text.trim();
    final wird = Wird(
      title: _title.text.trim(),
      text: text.isEmpty ? null : text,
      gate: _gate,
      targetCount: _hasCount ? (_targetCount < 1 ? 1 : _targetCount) : 1,
      isCustom: true,
      reminderMinutes: _hasReminder ? _reminderMinutes : null,
    );
    store.add(wird);
    NotificationManager.reschedule(store);
    Haptics.success();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('وِردٌ جديد', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(color: c.muted)),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text('حفظ',
                style: TextStyle(color: _canSave ? c.gold : c.faint, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const SectionLabel('الوِرد'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: WrdField(
                    placeholder: 'عنوان الوِرد — مثال: دعاءٌ لوالدتي',
                    controller: _title,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: WrdField(placeholder: 'النص (اختياري)', controller: _text, multiline: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('التوقيت'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final gate in Gate.values)
                  _Chip(
                    label: gate.arabicTitle,
                    selected: _gate == gate,
                    onTap: () => setState(() => _gate = gate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('العدد'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'وِردٌ بعدد (تسبيح)',
                  value: _hasCount,
                  onChanged: (v) => setState(() => _hasCount = v),
                ),
                if (_hasCount) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text('العدد', style: TextStyle(fontSize: 15, color: c.ink)),
                        const Spacer(),
                        WashIconButton(
                          icon: Icons.remove,
                          onTap: () => setState(() => _targetCount = (_targetCount - 1).clamp(1, 1000).toInt()),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(arabicNumber(_targetCount),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.gold)),
                        ),
                        WashIconButton(
                          icon: Icons.add,
                          onTap: () => setState(() => _targetCount = (_targetCount + 1).clamp(1, 1000).toInt()),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final v in const [3, 7, 10, 33, 100])
                          _Chip(
                            label: arabicNumber(v),
                            selected: _targetCount == v,
                            onTap: () => setState(() => _targetCount = v),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('التذكير'),
          const SizedBox(height: 8),
          Wash(
            cornerRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'ذكّرني يوميًا في وقتٍ أحدده',
                  value: _hasReminder,
                  onChanged: (v) => setState(() => _hasReminder = v),
                ),
                if (_hasReminder) ...[
                  const Divider(),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text('الوقت', style: TextStyle(fontSize: 15, color: c.ink)),
                          const Spacer(),
                          Text(minutesTimeString(_reminderMinutes),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.gold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('وِردك الخاص يبقى على جهازك — خاصٌّ بك دائمًا.',
              style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.gold : c.goldWash,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: selected ? c.ground : c.gold)),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = WrdColors.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c.ink))),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
