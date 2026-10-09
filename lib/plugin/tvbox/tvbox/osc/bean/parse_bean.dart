import 'dart:convert';

/// com.github.tvbox.osc.bean.ParseBean
class ParseBean {
  /// com.github.tvbox.osc.bean.ParseBean.name
  final String name;

  /// com.github.tvbox.osc.bean.ParseBean.url
  final String url;

  /// com.github.tvbox.osc.bean.ParseBean.type
  final int type;

  /// com.github.tvbox.osc.bean.ParseBean.ext
  final Map<String, dynamic> ext;

  /// com.github.tvbox.osc.util.parser.JsonParallel.getReqHeader+header
  Map<String, String> get headers {
    final header = ext['header'];
    if (header is Map) {
      return header.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return {};
  }

  /// com.github.tvbox.osc.util.parser.SuperParse.parse+flag
  List<String> get flags {
    final flag = ext['flag'];
    if (flag is List) {
      return flag.map((e) => e.toString()).toList();
    }
    if (flag is String && flag.isNotEmpty) {
      return [flag];
    }
    return const [];
  }

  const ParseBean({
    required this.name,
    required this.url,
    this.type = 0,
    this.ext = const {},
  });

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static ParseBean? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final name = json['name'];
    final url = json['url'];
    if (name is! String || url is! String) {
      return null;
    }
    return ParseBean(
      name: name,
      url: url,
      type: json['type'] is int ? json['type'] as int : 0,
      ext: json['ext'] is Map<String, dynamic>
          ? json['ext'] as Map<String, dynamic>
          : {},
    );
  }

  bool supportsFlag(String flag) {
    final list = flags;
    if (list.isEmpty) return true;
    return list.contains(flag);
  }

  /// com.github.tvbox.osc.bean.ParseBean.mixUrl
  String mixUrl() {
    if (ext.isEmpty) return url;
    final idx = url.indexOf('?');
    if (idx <= 0) return url;
    final b64 = base64UrlEncode(utf8.encode(jsonEncode(ext)));
    return '${url.substring(0, idx + 1)}cat_ext=$b64&'
        '${url.substring(idx + 1)}';
  }
}
