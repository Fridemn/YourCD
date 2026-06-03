import 'dart:io';

import 'package:flutter/services.dart';

class NativeBridge {
  NativeBridge._();

  static const _channel = MethodChannel('your_cd/native');
  static String? _memoryJson;

  static Future<String?> loadSkills() async {
    try {
      final value = await _channel.invokeMethod<String>('loadSkills');
      _memoryJson = value ?? _memoryJson;
      return value ?? _memoryJson;
    } on MissingPluginException {
      return _memoryJson;
    } on PlatformException {
      return _memoryJson;
    }
  }

  static Future<void> saveSkills(String json) async {
    _memoryJson = json;
    try {
      await _channel.invokeMethod<void>('saveSkills', {'json': json});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<String?> pickImage() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      return _channel.invokeMethod<String>('pickImage');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('requestNotifications');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> scheduleReadyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime triggerAt,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('scheduleNotification', {
        'id': id,
        'title': title,
        'body': body,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> cancelNotification(int id) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('cancelNotification', {'id': id});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
