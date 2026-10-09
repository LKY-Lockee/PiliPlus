import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';

/// com.github.tvbox.osc.util.SearchHelper
class SearchHelper {
  SearchHelper._();

  /// com.github.tvbox.osc.util.SearchHelper.getSourcesForSearch
  static List<SourceBean> getSourcesForSearch(ApiConfig config) =>
      config.sourceBeanList.where((source) => source.searchable).toList();

  static Future<List<VodVideo>> searchSource(
    ApiConfig config,
    String sourceKey,
    String keyword, {
    bool quick = false,
  }) async {
    final bean = config.getSource(sourceKey);
    if (bean == null) {
      return const [];
    }
    try {
      final result = await SourceViewModel(config: config, sourceKey: sourceKey)
          .getSearch(keyword, quick: quick)
          .timeout(Duration(seconds: bean.playTimeoutSeconds + 5));
      if (result case Success(:final response)) {
        return response;
      }
    } catch (_) {}
    return const [];
  }
}
