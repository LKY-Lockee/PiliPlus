import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:xml/xml.dart';

/// com.github.tvbox.osc.bean.MovieSort
class MovieSort {
  MovieSort._();

  /// com.github.tvbox.osc.bean.AbsSortJson.toAbsSortXml
  static VodCategory? sortDataFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final id = json['type_id'] ?? json['id'];
    final name = json['type_name'] ?? json['name'];
    if (id == null || name == null) {
      return null;
    }
    return VodCategory(id: id.toString(), name: name.toString());
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.sortXml
  static VodCategory? sortDataFromXml(XmlElement ty) {
    final id = ty.getAttribute('id');
    final name = ty.innerText.trim();
    if (id == null || name.isEmpty) {
      return null;
    }
    return VodCategory(id: id, name: name);
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getSortFilter
  static VodFilter? sortFilterFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final key = json['key'];
    final name = json['name'];
    final value = json['value'];
    if (key is! String || name is! String || value is! List) {
      return null;
    }
    return VodFilter(
      key: key,
      name: name,
      options: [
        for (final option in value)
          if (option is Map<String, dynamic>)
            VodFilterOption(
              label: option['n'] is String ? option['n'] as String : '',
              value: option['v'] is String ? option['v'] as String : '',
            ),
      ],
    );
  }
}
