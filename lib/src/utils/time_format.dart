String twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

String formatClock(int hour, int minute) {
  return '${twoDigits(hour)}:${twoDigits(minute)}';
}

String weekdayLabel(int weekday) {
  return switch (weekday) {
    DateTime.monday => '一',
    DateTime.tuesday => '二',
    DateTime.wednesday => '三',
    DateTime.thursday => '四',
    DateTime.friday => '五',
    DateTime.saturday => '六',
    DateTime.sunday => '日',
    _ => '六',
  };
}

String formatShortDateTime(DateTime value) {
  return '${value.month}月${value.day}日 ${formatClock(value.hour, value.minute)}';
}

String formatFullDateTime(DateTime value) {
  return '${value.year}年${value.month}月${value.day}日 ${formatClock(value.hour, value.minute)}';
}

String formatRemaining(Duration duration) {
  if (duration.inSeconds <= 0) {
    return '已就绪';
  }

  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (days > 0) {
    return hours > 0 ? '$days天 $hours小时' : '$days天';
  }
  if (hours > 0) {
    return minutes > 0 ? '$hours小时 $minutes分' : '$hours小时';
  }
  if (minutes > 0) {
    return '$minutes分 $seconds秒';
  }
  return '$seconds秒';
}

String formatMinutesAsDuration(int minutes) {
  if (minutes % (7 * 24 * 60) == 0) {
    final weeks = minutes ~/ (7 * 24 * 60);
    return '$weeks周';
  }
  if (minutes % (24 * 60) == 0) {
    final days = minutes ~/ (24 * 60);
    return '$days天';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours小时';
  }
  return '$minutes分钟';
}
