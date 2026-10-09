class VodQuality {
  /// com.github.tvbox.osc.ui.activity.DetailActivity.updateQualityOptions+url
  final String name;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.selectQuality+url
  final String url;

  const VodQuality({required this.name, required this.url});
}

class VodPlayInfo {
  /// com.github.tvbox.osc.ui.fragment.PlayFragment.playUrl+url
  final String url;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.selectQuality+flag
  final String flag;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.selectQuality+parse
  final bool parse;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.selectQuality+jx
  final bool jx;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.selectQuality+playUrl
  final String? parsePrefix;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.getHeaders+header
  final Map<String, String> headers;

  final List<VodQuality> qualities;
  final String? sniffUrl;

  const VodPlayInfo({
    required this.url,
    required this.flag,
    this.parse = false,
    this.jx = false,
    this.parsePrefix,
    this.headers = const {},
    this.qualities = const [],
    this.sniffUrl,
  });

  VodPlayInfo copyWith({
    String? url,
    bool? parse,
    Map<String, String>? headers,
    List<VodQuality>? qualities,
    String? sniffUrl,
  }) => VodPlayInfo(
    url: url ?? this.url,
    flag: flag,
    parse: parse ?? this.parse,
    jx: jx,
    parsePrefix: parsePrefix,
    headers: headers ?? this.headers,
    qualities: qualities ?? this.qualities,
    sniffUrl: sniffUrl,
  );
}
