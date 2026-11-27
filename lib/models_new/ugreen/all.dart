class UgreenAllData {
  final bool canManage;
  final bool isLastPage;
  final bool isNull;
  final int totalNum;
  final List<UgreenAllVideo> videoArr;

  const UgreenAllData({
    required this.canManage,
    required this.isLastPage,
    required this.isNull,
    required this.totalNum,
    required this.videoArr,
  });

  static UgreenAllData fromJson(Map<String, dynamic> json) {
    return UgreenAllData(
      canManage: json['can_manage'],
      isLastPage: json['is_last_page'],
      isNull: json['is_null'],
      totalNum: json['total_num'],
      videoArr:
          (json['video_arr'] as List?)
              ?.whereType<Map>()
              .map((e) => UgreenAllVideo.fromJson(e.cast()))
              .whereType<UgreenAllVideo>()
              .toList() ??
          const [],
    );
  }
}

class UgreenAllVideo {
  final String name;
  final int year;
  final int localCount;
  final String posterPath;
  final String backdropPath;
  final int type;
  final String categoryId;
  final int ugVideoInfoId;
  final List<String> filePath;
  final String language;
  final bool isFavorites;
  final int mediaLibSetId;
  final List<int> countryList;
  final List<int> styleList;
  final int grading;
  final String introduction;
  final int releaseDate;
  final num score;
  final int tmdbId;
  final int doubanId;
  final int useNfo;
  final int clarity;
  final int durationSeconds;

  const UgreenAllVideo({
    required this.name,
    required this.year,
    required this.localCount,
    required this.posterPath,
    required this.backdropPath,
    required this.type,
    required this.categoryId,
    required this.ugVideoInfoId,
    required this.filePath,
    required this.language,
    required this.isFavorites,
    required this.mediaLibSetId,
    required this.countryList,
    required this.styleList,
    required this.grading,
    required this.introduction,
    required this.releaseDate,
    required this.score,
    required this.tmdbId,
    required this.doubanId,
    required this.useNfo,
    required this.clarity,
    required this.durationSeconds,
  });

  static UgreenAllVideo fromJson(Map<String, dynamic> json) {
    return UgreenAllVideo(
      name: json['name'] as String,
      year: json['year'] as int,
      localCount: json['local_count'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      type: json['type'] as int,
      categoryId: json['category_id'] as String,
      ugVideoInfoId: json['ug_video_info_id'] as int,
      filePath: (json['file_path'] as List?)?.cast() ?? const [],
      language: json['language'] as String,
      isFavorites: json['is_favorites'] as bool,
      mediaLibSetId: json['media_lib_set_id'] as int,
      countryList: (json['country_list'] as List?)?.cast() ?? const [],
      styleList: (json['style_list'] as List?)?.cast() ?? const [],
      grading: json['grading'] as int,
      introduction: json['introduction'] as String,
      releaseDate: json['release_date'] as int,
      score: json['score'] as num,
      tmdbId: json['tmdb_id'] as int,
      doubanId: json['douban_id'] as int,
      useNfo: json['use_nfo'] as int,
      clarity: json['clarity'] as int,
      durationSeconds: json['duration_seconds'] as int,
    );
  }
}
