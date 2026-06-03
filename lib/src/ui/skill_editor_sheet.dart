import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/life_skill.dart';
import '../models/preset_icons.dart';
import '../services/native_bridge.dart';
import '../utils/time_format.dart';

class SkillEditorSheet extends StatefulWidget {
  const SkillEditorSheet({this.skill, super.key});

  final LifeSkill? skill;

  @override
  State<SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends State<SkillEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;

  late String _iconKey;
  String? _imagePath;
  late int _colorValue;
  late CooldownRuleType _ruleType;
  late int _durationAmount;
  late _DurationUnit _durationUnit;
  late int _resetHour;
  late int _resetMinute;
  late int _weekday;
  late bool _notificationsEnabled;
  bool _pickingImage = false;

  static const _colors = <int>[
    0xFF0F766E,
    0xFFE76F51,
    0xFF5B5F97,
    0xFF2A9D8F,
    0xFF9B5DE5,
    0xFF457B9D,
    0xFFD62828,
    0xFF2D6A4F,
  ];

  @override
  void initState() {
    super.initState();
    final skill = widget.skill;
    final rule = skill?.rule;
    _nameController = TextEditingController(text: skill?.name ?? '');
    _noteController = TextEditingController(text: skill?.note ?? '');
    _iconKey = skill?.iconKey ?? presetSkillIcons.first.key;
    _imagePath = skill?.imagePath;
    _colorValue = skill?.colorValue ?? _colors.first;
    _ruleType = rule?.type ?? CooldownRuleType.duration;
    _resetHour = rule?.resetHour ?? 6;
    _resetMinute = rule?.resetMinute ?? 0;
    _weekday = rule?.weekday ?? DateTime.saturday;
    _notificationsEnabled = skill?.notificationsEnabled ?? false;

    final durationFields = _durationToFields(
      rule?.durationMinutes ?? 7 * 24 * 60,
    );
    _durationAmount = durationFields.amount;
    _durationUnit = durationFields.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DEDB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.skill == null ? '新建技能' : '编辑技能',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 24,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                  maxLength: 80,
                ),
                const SizedBox(height: 8),
                _SectionTitle(label: '图标'),
                const SizedBox(height: 10),
                _buildIconPicker(),
                const SizedBox(height: 18),
                _SectionTitle(label: '颜色'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final colorValue in _colors)
                      _ColorSwatch(
                        color: Color(colorValue),
                        selected: colorValue == _colorValue,
                        onTap: () => setState(() => _colorValue = colorValue),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(label: 'CD 规则'),
                const SizedBox(height: 10),
                SegmentedButton<CooldownRuleType>(
                  showSelectedIcon: false,
                  selected: {_ruleType},
                  onSelectionChanged: (selection) {
                    setState(() => _ruleType = selection.first);
                  },
                  segments: const [
                    ButtonSegment(
                      value: CooldownRuleType.duration,
                      icon: Icon(Icons.timer_rounded),
                      label: Text('时长'),
                    ),
                    ButtonSegment(
                      value: CooldownRuleType.dailyReset,
                      icon: Icon(Icons.today_rounded),
                      label: Text('每天'),
                    ),
                    ButtonSegment(
                      value: CooldownRuleType.weeklyReset,
                      icon: Icon(Icons.date_range_rounded),
                      label: Text('每周'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildRuleFields(),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('冷却结束通知'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.skill == null ? '创建' : '保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    final selectedColor = Color(_colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in presetSkillIcons)
              Tooltip(
                message: preset.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _iconKey = preset.key;
                      _imagePath = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        width: preset.key == _iconKey && _imagePath == null
                            ? 2
                            : 1,
                        color: preset.key == _iconKey && _imagePath == null
                            ? selectedColor
                            : const Color(0xFFDCE4E1),
                      ),
                    ),
                    child: Icon(preset.icon, color: selectedColor),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickingImage ? null : _pickImage,
                icon: _pickingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_rounded),
                label: const Text('本地图片'),
              ),
            ),
            if (_imagePath != null) ...[
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: '改用预置图标',
                onPressed: () => setState(() => _imagePath = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRuleFields() {
    return switch (_ruleType) {
      CooldownRuleType.duration => Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const ValueKey('durationAmount'),
              initialValue: _durationAmount.toString(),
              decoration: const InputDecoration(
                labelText: '数值',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                _durationAmount = int.tryParse(value) ?? _durationAmount;
              },
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return '请输入正整数';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 124,
            child: DropdownButtonFormField<_DurationUnit>(
              initialValue: _durationUnit,
              decoration: const InputDecoration(labelText: '单位'),
              items: const [
                DropdownMenuItem(
                  value: _DurationUnit.minutes,
                  child: Text('分钟'),
                ),
                DropdownMenuItem(value: _DurationUnit.hours, child: Text('小时')),
                DropdownMenuItem(value: _DurationUnit.days, child: Text('天')),
                DropdownMenuItem(value: _DurationUnit.weeks, child: Text('周')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _durationUnit = value);
                }
              },
            ),
          ),
        ],
      ),
      CooldownRuleType.dailyReset => _TimeButton(
        label: '重置时间',
        value: formatClock(_resetHour, _resetMinute),
        onPressed: _pickTime,
      ),
      CooldownRuleType.weeklyReset => Row(
        children: [
          SizedBox(
            width: 124,
            child: DropdownButtonFormField<int>(
              initialValue: _weekday,
              decoration: const InputDecoration(labelText: '星期'),
              items: const [
                DropdownMenuItem(value: DateTime.monday, child: Text('周一')),
                DropdownMenuItem(value: DateTime.tuesday, child: Text('周二')),
                DropdownMenuItem(value: DateTime.wednesday, child: Text('周三')),
                DropdownMenuItem(value: DateTime.thursday, child: Text('周四')),
                DropdownMenuItem(value: DateTime.friday, child: Text('周五')),
                DropdownMenuItem(value: DateTime.saturday, child: Text('周六')),
                DropdownMenuItem(value: DateTime.sunday, child: Text('周日')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _weekday = value);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TimeButton(
              label: '重置时间',
              value: formatClock(_resetHour, _resetMinute),
              onPressed: _pickTime,
            ),
          ),
        ],
      ),
    };
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final path = await NativeBridge.pickImage();
    if (!mounted) {
      return;
    }
    setState(() {
      _pickingImage = false;
      if (path != null && path.isNotEmpty) {
        _imagePath = path;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _resetHour, minute: _resetMinute),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _resetHour = picked.hour;
      _resetMinute = picked.minute;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final old = widget.skill;
    final rule = switch (_ruleType) {
      CooldownRuleType.duration => CooldownRule(
        type: CooldownRuleType.duration,
        durationMinutes: _durationAmount * _durationUnit.minuteFactor,
      ),
      CooldownRuleType.dailyReset => CooldownRule(
        type: CooldownRuleType.dailyReset,
        resetHour: _resetHour,
        resetMinute: _resetMinute,
      ),
      CooldownRuleType.weeklyReset => CooldownRule(
        type: CooldownRuleType.weeklyReset,
        resetHour: _resetHour,
        resetMinute: _resetMinute,
        weekday: _weekday,
      ),
    };

    Navigator.of(context).pop(
      LifeSkill(
        id: old?.id ?? createSkillId(),
        name: _nameController.text.trim(),
        note: _noteController.text.trim(),
        iconKey: _iconKey,
        imagePath: _imagePath,
        colorValue: _colorValue,
        rule: rule,
        lastUsedAt: old?.lastUsedAt,
        history: old?.history ?? const [],
        notificationsEnabled: _notificationsEnabled,
        notificationId: old?.notificationId ?? createNotificationId(),
      ),
    );
  }

  _DurationFields _durationToFields(int minutes) {
    if (minutes % _DurationUnit.weeks.minuteFactor == 0) {
      return _DurationFields(
        amount: minutes ~/ _DurationUnit.weeks.minuteFactor,
        unit: _DurationUnit.weeks,
      );
    }
    if (minutes % _DurationUnit.days.minuteFactor == 0) {
      return _DurationFields(
        amount: minutes ~/ _DurationUnit.days.minuteFactor,
        unit: _DurationUnit.days,
      );
    }
    if (minutes % _DurationUnit.hours.minuteFactor == 0) {
      return _DurationFields(
        amount: minutes ~/ _DurationUnit.hours.minuteFactor,
        unit: _DurationUnit.hours,
      );
    }
    return _DurationFields(amount: minutes, unit: _DurationUnit.minutes);
  }
}

enum _DurationUnit {
  minutes(1),
  hours(60),
  days(24 * 60),
  weeks(7 * 24 * 60);

  const _DurationUnit(this.minuteFactor);

  final int minuteFactor;
}

class _DurationFields {
  const _DurationFields({required this.amount, required this.unit});

  final int amount;
  final _DurationUnit unit;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: const Color(0xFF263A36),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            width: selected ? 3 : 1,
            color: selected ? Colors.black87 : Colors.white,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label $value'),
    );
  }
}
