import 'dart:io';

import 'package:flutter/material.dart';

import '../models/life_skill.dart';
import '../models/preset_icons.dart';

class SkillIconView extends StatelessWidget {
  const SkillIconView({required this.skill, required this.size, super.key});

  final LifeSkill skill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(skill.colorValue);
    final icon = presetIconByKey(skill.iconKey);
    final imagePath = skill.imagePath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: imagePath == null || imagePath.isEmpty
          ? _FallbackIcon(icon: icon.icon, color: color, size: size)
          : ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _FallbackIcon(
                    icon: icon.icon,
                    color: color,
                    size: size,
                  );
                },
              ),
            ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color, size: size * 0.5);
  }
}
