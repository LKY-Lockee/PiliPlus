/// com.github.tvbox.osc.bean.MovieSort.SortData
class VodCategory {
  /// com.github.tvbox.osc.bean.MovieSort.SortData.id
  final String id;

  /// com.github.tvbox.osc.bean.MovieSort.SortData.name
  final String name;

  const VodCategory({required this.id, required this.name});
}

/// com.github.tvbox.osc.viewmodel.SourceViewModel.getSortFilter+value
class VodFilterOption {
  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getSortFilter+n
  final String label;

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getSortFilter+v
  final String value;

  const VodFilterOption({required this.label, required this.value});
}

/// com.github.tvbox.osc.bean.MovieSort.SortFilter
class VodFilter {
  /// com.github.tvbox.osc.bean.MovieSort.SortFilter.key
  final String key;

  /// com.github.tvbox.osc.bean.MovieSort.SortFilter.name
  final String name;

  /// com.github.tvbox.osc.bean.MovieSort.SortFilter.values
  final List<VodFilterOption> options;

  const VodFilter({
    required this.key,
    required this.name,
    required this.options,
  });
}
