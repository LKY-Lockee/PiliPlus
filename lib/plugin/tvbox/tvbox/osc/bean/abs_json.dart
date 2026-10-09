import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';

/// com.github.tvbox.osc.bean.AbsJson
class AbsJson {
  AbsJson._();

  /// com.github.tvbox.osc.bean.AbsJson.toAbsXml
  static VodListData toAbsXml(Map<String, dynamic> json) {
    final cards = <VodVideo>[];
    final listJson = json['list'];
    if (listJson is List) {
      for (final item in listJson) {
        if (item is Map<String, dynamic>) {
          final card = VodVideo.fromJson(item);
          if (card != null) {
            cards.add(card);
          }
        }
      }
    }
    return VodListData(
      videoList: cards,
      page: DefaultConfig.safeJsonInt(json['page'], 1),
      pageCount: DefaultConfig.safeJsonInt(json['pagecount'], 1),
    );
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.json
  static LoadingState<VodListData> parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        return const Error('数据解析失败');
      }
      return Success(toAbsXml(json));
    } catch (_) {
      return const Error('数据解析失败');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getDetail
  static LoadingState<VodInfoModel> parseDetail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        return const Error('数据解析失败');
      }
      final list = json['list'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        final detail = VodInfoModel.fromJson(
          list.first as Map<String, dynamic>,
        );
        if (detail != null) {
          return Success(detail);
        }
      }
      return const Error('未找到相关内容');
    } catch (_) {
      return const Error('数据解析失败');
    }
  }
}
