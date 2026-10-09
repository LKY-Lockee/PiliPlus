import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/movie_sort.dart';
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

class AbsSortXml {
  AbsSortXml._();

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.sortXml
  static LoadingState<VodHomeData> parse(
    String body, {
    List<String>? sourceCategories,
  }) {
    try {
      final doc = XmlDocument.parse(body);
      final listEl = doc.findAllElements('list').firstOrNull;
      if (listEl == null) {
        return const Error('配置解析失败');
      }
      final categories = <VodCategory>[];
      for (final ty
          in listEl.findElements('class').firstOrNull?.findElements('ty') ??
              const <XmlElement>[]) {
        final category = MovieSort.sortDataFromXml(ty);
        if (category != null) {
          categories.add(category);
        }
      }
      if (sourceCategories != null && sourceCategories.isNotEmpty) {
        categories.removeWhere((e) => !sourceCategories.contains(e.name));
      }
      return Success(VodHomeData(categories: categories));
    } catch (_) {
      return const Error('配置解析失败');
    }
  }
}
