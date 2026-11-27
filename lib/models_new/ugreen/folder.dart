class UgreenFolderData {
  final int totalNum;
  final bool isLastPage;
  final List<UgreenFolderItem> folderArr;

  const UgreenFolderData({
    required this.totalNum,
    required this.isLastPage,
    required this.folderArr,
  });

  static UgreenFolderData fromJson(Map<String, dynamic> json) {
    return UgreenFolderData(
      totalNum: json['total_num'] as int,
      isLastPage: json['is_last_page'] as bool,
      folderArr:
          (json['folder_arr'] as List?)
              ?.whereType<Map>()
              .map((e) => UgreenFolderItem.fromJson(e.cast()))
              .whereType<UgreenFolderItem>()
              .toList() ??
          const [],
    );
  }
}

class UgreenFolderItem {
  final bool invalid;
  final String path;
  final String cover;
  final List<String> covers;
  final String backdropPath;
  final int mediaLibSetId;
  final int count;
  final String showPath;

  const UgreenFolderItem({
    required this.invalid,
    required this.path,
    required this.cover,
    required this.covers,
    required this.backdropPath,
    required this.mediaLibSetId,
    required this.count,
    required this.showPath,
  });

  static UgreenFolderItem fromJson(Map<String, dynamic> json) {
    return UgreenFolderItem(
      invalid: json['invalid'] as bool,
      path: json['path'] as String,
      cover: json['cover'] as String,
      covers: (json['covers'] as List?)?.cast() ?? const [],
      backdropPath: json['backdrop_path'] as String,
      mediaLibSetId: json['media_lib_set_id'] as int,
      count: json['count'] as int,
      showPath: json['show_path'] as String,
    );
  }
}
