import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/movie_sort.dart';

/// com.github.tvbox.osc.bean.AbsSortJson
class AbsSortJson {
  AbsSortJson._();

  /// com.github.tvbox.osc.bean.AbsSortJson.toAbsSortXml
  static VodHomeData toAbsSortXml(
    Map<String, dynamic> json, {
    List<String>? sourceCategories,
  }) {
    final categories = <VodCategory>[];
    final classJson = json['class'];
    if (classJson is List) {
      for (final item in classJson) {
        final category = MovieSort.sortDataFromJson(item);
        if (category != null) {
          categories.add(category);
        }
      }
    }

    final filters = <String, List<VodFilter>>{};
    final filtersJson = json['filters'];
    if (filtersJson is Map<String, dynamic>) {
      filtersJson.forEach((tid, value) {
        final list = <VodFilter>[];
        if (value is Map<String, dynamic>) {
          final f = MovieSort.sortFilterFromJson(value);
          if (f != null) {
            list.add(f);
          }
        } else if (value is List) {
          for (final ele in value) {
            final f = MovieSort.sortFilterFromJson(ele);
            if (f != null) {
              list.add(f);
            }
          }
        }
        if (list.isNotEmpty) {
          filters[tid] = list;
        }
      });
    }

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

    var ordered = categories;
    if (sourceCategories != null && sourceCategories.isNotEmpty) {
      ordered = [
        ...categories.where((e) => sourceCategories.contains(e.name)),
      ];
    }

    return VodHomeData(categories: ordered, filters: filters, videoList: cards);
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.sortJson
  static LoadingState<VodHomeData> parse(
    String body, {
    List<String>? sourceCategories,
  }) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        return const Error('配置解析失败');
      }
      return Success(toAbsSortXml(json, sourceCategories: sourceCategories));
    } catch (_) {
      return const Error('配置解析失败');
    }
  }
}
