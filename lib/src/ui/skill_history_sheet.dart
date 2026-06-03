import 'package:flutter/material.dart';

import '../models/life_skill.dart';
import '../utils/time_format.dart';
import 'skill_icon_view.dart';

class SkillHistorySheet extends StatelessWidget {
  const SkillHistorySheet({required this.skill, required this.now, super.key});

  final LifeSkill skill;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = skill.nextAvailableAt();
    final remaining = skill.remainingAt(now);
    final available = skill.isAvailableAt(now);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 18),
            Row(
              children: [
                SkillIconView(skill: skill, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        available ? '现在可用' : '${formatRemaining(remaining)}后可用',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: available
                              ? const Color(0xFF168358)
                              : const Color(0xFFB45B2A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoLine(icon: Icons.tune_rounded, text: skill.rule.label),
            if (next != null) ...[
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.event_available_rounded,
                text: formatFullDateTime(next),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              '使用记录',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (skill.history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '暂无记录',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF74817D),
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.48,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: skill.history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = skill.history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.forced
                            ? Icons.warning_amber_rounded
                            : Icons.flash_on_rounded,
                        color: entry.forced
                            ? const Color(0xFFE76F51)
                            : const Color(0xFF0F766E),
                      ),
                      title: Text(entry.forced ? '强制使用' : '正常使用'),
                      subtitle: Text(formatFullDateTime(entry.time)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF50615D)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF50615D)),
          ),
        ),
      ],
    );
  }
}
