import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// com.github.catvod.crawler.js.local
class Local {
  Local._();

  static String _localKey(dynamic ns, dynamic key) =>
      'jsRuntime_${ns ?? ''}_${key ?? ''}';

  static Future<Box> _localBox() async {
    if (Hive.isBoxOpen('jsRuntime')) return Hive.box('jsRuntime');
    return Hive.openBox('jsRuntime');
  }

  /// com.github.catvod.crawler.js.local.get
  static Future<Object?> get(String ns, String key) async {
    final box = await _localBox();
    return box.get(_localKey(ns, key));
  }

  /// com.github.catvod.crawler.js.local.set
  static Future<Object?> set(String ns, String key, Object? value) async {
    final box = await _localBox();
    await box.put(
      _localKey(ns, key),
      value is Map || value is List ? jsonEncode(value) : value?.toString(),
    );
    return null;
  }

  /// com.github.catvod.crawler.js.local.delete
  static Future<Object?> delete(String ns, String key) async {
    final box = await _localBox();
    await box.delete(_localKey(ns, key));
    return null;
  }
}
