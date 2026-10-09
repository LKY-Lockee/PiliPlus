import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// com.github.tvbox.osc.bean.SourceBean
class SourceBean {
  /// com.github.tvbox.osc.bean.SourceBean.key
  final String key;

  /// com.github.tvbox.osc.bean.SourceBean.name
  final String name;

  /// com.github.tvbox.osc.bean.SourceBean.type
  final int type;

  /// com.github.tvbox.osc.bean.SourceBean.api
  final String api;

  /// com.github.tvbox.osc.bean.SourceBean.ext
  final String ext;

  /// com.github.tvbox.osc.bean.SourceBean.searchable
  final bool searchable;

  /// com.github.tvbox.osc.bean.SourceBean.quickSearch
  final bool quickSearch;

  /// com.github.tvbox.osc.bean.SourceBean.filterable
  final bool filterable;

  /// com.github.tvbox.osc.bean.SourceBean.changeable
  final bool changeable;

  /// com.github.tvbox.osc.bean.SourceBean.playerUrl
  final String playUrl;

  /// com.github.tvbox.osc.bean.SourceBean.timeout
  final int timeout;

  /// com.github.tvbox.osc.bean.SourceBean.categories
  final List<String>? categories;

  /// com.github.tvbox.osc.bean.SourceBean.playerType
  final int playerType;

  bool get isJsSource =>
      type == 3 && (api.endsWith('.js') || api.contains('.js?'));

  bool get jsEngineAvailable => !kIsWeb && !Platform.isIOS && !Platform.isMacOS;

  bool get supported =>
      type == 0 || type == 1 || type == 4 || (isJsSource && jsEngineAvailable);

  /// com.github.tvbox.osc.bean.SourceBean.getPlayTimeoutSeconds
  int get playTimeoutSeconds {
    if (timeout <= 0) return 15;
    return timeout < 5 ? 5 : (timeout > 60 ? 60 : timeout);
  }

  const SourceBean({
    required this.key,
    required this.name,
    required this.type,
    required this.api,
    this.ext = '',
    this.searchable = true,
    this.quickSearch = true,
    this.filterable = true,
    this.changeable = true,
    this.playUrl = '',
    this.timeout = 0,
    this.categories,
    this.playerType = -1,
  });

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static SourceBean? fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    final api = json['api'];
    final type = json['type'];
    if (key is! String ||
        key.isEmpty ||
        api is! String ||
        api.isEmpty ||
        type is! int) {
      return null;
    }
    final ext = json['ext'];
    return SourceBean(
      key: key,
      name: json['name'] is String ? json['name'] as String : key,
      type: type,
      api: api,
      ext: ext is String
          ? ext
          : ext == null
          ? ''
          : jsonEncode(ext),
      searchable: json['searchable'] is! int || json['searchable'] == 1,
      quickSearch: json['quickSearch'] is! int || json['quickSearch'] == 1,
      filterable: json['filterable'] is! int || json['filterable'] == 1,
      changeable: json['changeable'] is! int || json['changeable'] == 1,
      playUrl: json['playUrl'] is String ? json['playUrl'] as String : '',
      timeout: json['timeout'] is int ? json['timeout'] as int : 0,
      categories: json['categories'] is List
          ? (json['categories'] as List).whereType<String>().toList()
          : null,
      playerType: json['playerType'] is int ? json['playerType'] as int : -1,
    );
  }
}
