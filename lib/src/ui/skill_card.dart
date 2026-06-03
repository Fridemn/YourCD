import 'package:flutter/material.dart';

import '../models/life_skill.dart';
import '../utils/time_format.dart';
import 'skill_icon_view.dart';

enum SkillCardAction { history, edit, reset, delete }

class SkillCard extends StatelessWidget {
  const SkillCard({
    required this.skill,
    required this.now,
    required this.onUse,
    required this.onAction,
    super.key,
  });

  final LifeSkill skill;
  final DateTime now;
  final VoidCallback onUse;
  final ValueChanged<SkillCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = skill.isAvailableAt(now);
    final remaining = skill.remainingAt(now);
    final next = skill.nextAvailableAt();
    final skillColor = Color(skill.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E7E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkillIconView(skill: skill, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        _StatusMark(available: available),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.rule.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667571),
                      ),
                    ),
                    if (skill.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        skill.note.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7B6F69),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<SkillCardAction>(
                tooltip: '更多',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: onAction,
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: SkillCardAction.history,
                      child: _MenuRow(icon: Icons.history_rounded, label: '记录'),
                    ),
                    PopupMenuItem(
                      value: SkillCardAction.edit,
                      child: _MenuRow(icon: Icons.edit_rounded, label: '编辑'),
                    ),
                    PopupMenuItem(
                      value: SkillCardAction.reset,
                      child: _MenuRow(icon: Icons.refresh_rounded, label: '重置'),
                    ),
                    PopupMenuItem(
                      value: SkillCardAction.delete,
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: '删除',
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: skill.progressAt(now).clamp(0, 1).toDouble(),
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            color: available ? const Color(0xFF1B9A73) : skillColor,
            backgroundColor: skillColor.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeLine(
                  icon: available
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_bottom_rounded,
                  text: available ? '现在可用' : formatRemaining(remaining),
                  color: available ? const Color(0xFF168358) : skillColor,
                ),
              ),
              if (next != null && !available)
                Expanded(
                  child: _TimeLine(
                    icon: Icons.event_available_rounded,
                    text: formatShortDateTime(next),
                    color: const Color(0xFF50615D),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: available
                ? FilledButton.icon(
                    onPressed: onUse,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('使用'),
                  )
                : OutlinedButton.icon(
                    onPressed: onUse,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('强制使用'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xFF168358) : const Color(0xFFB45B2A);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          available ? Icons.bolt_rounded : Icons.timelapse_rounded,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 3),
        Text(
          available ? '可用' : '冷却',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(label)],
    );
  }
}
