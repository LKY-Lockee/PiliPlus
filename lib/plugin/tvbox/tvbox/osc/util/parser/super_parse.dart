import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/play.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/proxy.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/parser/json_parallel.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/parser/utils.dart';

/// com.github.tvbox.osc.util.parser.SuperParse
class SuperParse {
  SuperParse._();

  /// com.github.tvbox.osc.util.parser.SuperParse.parse
  static List<ParseBean> candidates(ApiConfig cfg, String flag) {
    final matched = cfg.parseBeanList
        .where((p) => p.flags.contains(flag))
        .toList();
    if (matched.isNotEmpty) return matched;
    return cfg.parseBeanList.toList();
  }

  /// com.github.tvbox.osc.util.parser.SuperParse.parse
  static Future<LoadingState<VodPlayInfo>> resolve(
    ApiConfig cfg,
    VodPlayInfo info,
    String flag,
  ) async {
    final cands = candidates(
      cfg,
      flag,
    ).where((p) => p.type == 0 || p.type == 1).toList();
    final jsonParses = cands.where((p) => p.type == 1).toList();
    final webParses = cands.where((p) => p.type == 0).toList();

    if (jsonParses.isNotEmpty) {
      final hit = await JsonParallel.parse(jsonParses, info.url);
      if (hit != null) {
        return Success(
          info.copyWith(
            url: hit.url,
            headers: {...info.headers, ...hit.headers},
            parse: false,
            sniffUrl: Utils.isVideoFormat(hit.url) ? null : hit.url,
          ),
        );
      }
    }

    if (webParses.isNotEmpty) {
      final urls = webParses
          .map((p) => p.url)
          .where((u) => u.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) {
        final sniffUrl = Proxy.superParseUrl(urls, info.url);
        return Success(
          info.copyWith(parse: false, sniffUrl: sniffUrl),
        );
      }
    }

    return const Error('未配置可用解析');
  }

  /// com.github.tvbox.osc.util.parser.SuperParse.loadHtml
  static String loadHtml(List<String> jxs, String url) {
    return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width">
</head>
<body>
<script>
var apiArray=${jsonEncode(jxs)};
var urlPs=${jsonEncode(url)};
var iframeHtml="";
for(var i=0;i<apiArray.length;i++){
  var URL=apiArray[i]+urlPs;
  iframeHtml=iframeHtml+"<iframe sandbox='allow-scripts allow-same-origin allow-forms' frameborder='0' allowfullscreen='true' webkitallowfullscreen='true' mozallowfullscreen='true' src="+URL+"></iframe>";
}
document.write(iframeHtml);
</script>
</body>
</html>
''';
  }
}
