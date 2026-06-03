import 'package:flutter/material.dart';

class PresetSkillIcon {
  const PresetSkillIcon({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const presetSkillIcons = <PresetSkillIcon>[
  PresetSkillIcon(
    key: 'restaurant',
    label: '餐饮',
    icon: Icons.restaurant_rounded,
  ),
  PresetSkillIcon(
    key: 'fitness',
    label: '运动',
    icon: Icons.fitness_center_rounded,
  ),
  PresetSkillIcon(key: 'coffee', label: '咖啡', icon: Icons.coffee_rounded),
  PresetSkillIcon(key: 'game', label: '游戏', icon: Icons.sports_esports_rounded),
  PresetSkillIcon(key: 'rest', label: '休息', icon: Icons.bedtime_rounded),
  PresetSkillIcon(key: 'book', label: '阅读', icon: Icons.menu_book_rounded),
  PresetSkillIcon(key: 'savings', label: '存钱', icon: Icons.savings_rounded),
  PresetSkillIcon(key: 'movie', label: '电影', icon: Icons.movie_filter_rounded),
  PresetSkillIcon(key: 'music', label: '音乐', icon: Icons.music_note_rounded),
  PresetSkillIcon(
    key: 'focus',
    label: '专注',
    icon: Icons.self_improvement_rounded,
  ),
  PresetSkillIcon(
    key: 'shopping',
    label: '购物',
    icon: Icons.shopping_bag_rounded,
  ),
  PresetSkillIcon(key: 'goal', label: '目标', icon: Icons.flag_rounded),
  PresetSkillIcon(key: 'heart', label: '奖励', icon: Icons.favorite_rounded),
  PresetSkillIcon(key: 'run', label: '出行', icon: Icons.directions_run_rounded),
  PresetSkillIcon(key: 'spark', label: '清单', icon: Icons.auto_awesome_rounded),
];

PresetSkillIcon presetIconByKey(String key) {
  return presetSkillIcons.firstWhere(
    (icon) => icon.key == key,
    orElse: () => presetSkillIcons.first,
  );
}
