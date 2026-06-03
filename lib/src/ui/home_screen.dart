import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/life_skill.dart';
import '../services/native_bridge.dart';
import 'skill_card.dart';
import 'skill_editor_sheet.dart';
import 'skill_history_sheet.dart';

enum _SkillFilter { all, ready, cooling }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _skills = <LifeSkill>[];
  var _now = DateTime.now();
  var _filter = _SkillFilter.all;
  var _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    unawaited(_loadSkills());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSkills();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YourCD',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建'),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_SkillFilter>(
                        showSelectedIcon: false,
                        selected: {_filter},
                        onSelectionChanged: (selection) {
                          setState(() => _filter = selection.first);
                        },
                        segments: const [
                          ButtonSegment(
                            value: _SkillFilter.all,
                            icon: Icon(Icons.dashboard_rounded),
                            label: Text('全部'),
                          ),
                          ButtonSegment(
                            value: _SkillFilter.ready,
                            icon: Icon(Icons.bolt_rounded),
                            label: Text('可用'),
                          ),
                          ButtonSegment(
                            value: _SkillFilter.cooling,
                            icon: Icon(Icons.timelapse_rounded),
                            label: Text('冷却'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyState(
                            hasAnySkill: _skills.isNotEmpty,
                            onCreate: () => _openEditor(),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final skill = filtered[index];
                              return SkillCard(
                                key: ValueKey(skill.id),
                                skill: skill,
                                now: _now,
                                onUse: () => _useSkill(skill),
                                onAction: (action) {
                                  _handleCardAction(skill, action);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadSkills() async {
    final raw = await NativeBridge.loadSkills();
    final loaded = _decodeSkills(raw);
    if (!mounted) {
      return;
    }
    setState(() {
      _skills = loaded;
      _loading = false;
    });
    await _syncAllNotifications(loaded);
  }

  List<LifeSkill> _decodeSkills(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      final skills = <LifeSkill>[];
      for (final item in decoded) {
        if (item is Map) {
          skills.add(LifeSkill.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return skills;
    } on FormatException {
      return [];
    }
  }

  Future<void> _persistSkills() {
    final raw = jsonEncode(_skills.map((skill) => skill.toJson()).toList());
    return NativeBridge.saveSkills(raw);
  }

  List<LifeSkill> _filteredSkills() {
    final filtered = _skills.where((skill) {
      return switch (_filter) {
        _SkillFilter.all => true,
        _SkillFilter.ready => skill.isAvailableAt(_now),
        _SkillFilter.cooling => !skill.isAvailableAt(_now),
      };
    }).toList();

    filtered.sort((left, right) {
      final leftReady = left.isAvailableAt(_now);
      final rightReady = right.isAvailableAt(_now);
      if (leftReady != rightReady) {
        return leftReady ? -1 : 1;
      }

      final leftNext = left.nextAvailableAt();
      final rightNext = right.nextAvailableAt();
      if (leftNext == null && rightNext == null) {
        return left.name.compareTo(right.name);
      }
      if (leftNext == null) {
        return -1;
      }
      if (rightNext == null) {
        return 1;
      }
      return leftNext.compareTo(rightNext);
    });

    return filtered;
  }

  Future<void> _openEditor([LifeSkill? skill]) async {
    final result = await showModalBottomSheet<LifeSkill>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SkillEditorSheet(skill: skill),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() => _upsertSkill(result));
    await _persistSkills();
    await _syncNotificationFor(result);
  }

  Future<void> _useSkill(LifeSkill skill) async {
    final current = _findSkill(skill.id);
    if (current == null) {
      return;
    }

    final forced = !current.isAvailableAt(DateTime.now());
    if (forced) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('仍在冷却'),
            content: const Text('这次会记录为强制使用。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('继续'),
              ),
            ],
          );
        },
      );
      if (!mounted || confirmed != true) {
        return;
      }
    }

    final updated = current.markUsed(DateTime.now(), forced: forced);
    setState(() => _upsertSkill(updated));
    await _persistSkills();
    await _syncNotificationFor(updated);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(forced ? '已记录强制使用' : '已使用 ${updated.name}')),
    );
  }

  Future<void> _resetSkill(LifeSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置 CD'),
          content: const Text('当前冷却状态会被清除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重置'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final current = _findSkill(skill.id);
    if (current == null) {
      return;
    }
    final updated = current.copyWith(clearLastUsedAt: true);
    setState(() => _upsertSkill(updated));
    await _persistSkills();
    await NativeBridge.cancelNotification(updated.notificationId);
  }

  Future<void> _deleteSkill(LifeSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除技能'),
          content: Text('删除“${skill.name}”？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _skills.removeWhere((item) => item.id == skill.id));
    await _persistSkills();
    await NativeBridge.cancelNotification(skill.notificationId);
  }

  void _showHistory(LifeSkill skill) {
    final current = _findSkill(skill.id);
    if (current == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SkillHistorySheet(skill: current, now: _now),
    );
  }

  void _handleCardAction(LifeSkill skill, SkillCardAction action) {
    switch (action) {
      case SkillCardAction.history:
        _showHistory(skill);
        break;
      case SkillCardAction.edit:
        unawaited(_openEditor(skill));
        break;
      case SkillCardAction.reset:
        unawaited(_resetSkill(skill));
        break;
      case SkillCardAction.delete:
        unawaited(_deleteSkill(skill));
        break;
    }
  }

  LifeSkill? _findSkill(String id) {
    for (final skill in _skills) {
      if (skill.id == id) {
        return skill;
      }
    }
    return null;
  }

  void _upsertSkill(LifeSkill skill) {
    final index = _skills.indexWhere((item) => item.id == skill.id);
    if (index == -1) {
      _skills = [..._skills, skill];
    } else {
      _skills = [..._skills.take(index), skill, ..._skills.skip(index + 1)];
    }
  }

  Future<void> _syncAllNotifications(List<LifeSkill> skills) async {
    for (final skill in skills) {
      await _syncNotificationFor(skill);
    }
  }

  Future<void> _syncNotificationFor(LifeSkill skill) async {
    await NativeBridge.cancelNotification(skill.notificationId);
    if (!skill.notificationsEnabled) {
      return;
    }

    final next = skill.nextAvailableAt();
    if (next == null || !next.isAfter(DateTime.now())) {
      return;
    }

    await NativeBridge.requestNotificationPermission();
    await NativeBridge.scheduleReadyNotification(
      id: skill.notificationId,
      title: '可以 ${skill.name} 了',
      body: 'CD 已结束',
      triggerAt: next,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAnySkill, required this.onCreate});

  final bool hasAnySkill;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnySkill ? Icons.filter_alt_off_rounded : Icons.bolt_rounded,
              size: 52,
              color: const Color(0xFF0F766E),
            ),
            const SizedBox(height: 12),
            Text(
              hasAnySkill ? '没有匹配项' : '还没有技能',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (!hasAnySkill) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建技能'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
