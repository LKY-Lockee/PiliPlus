class UgreenRelatedVideo {
  final int ugVideoInfoId;
  final int doubanId;
  final int tmdbId;
  final String ugMediaId;
  final int useNfo;
  final String name;
  final String jpName;
  final String pinyinFirst;
  final String pinyinFull;
  final String to9Digit;
  final int releaseDate;
  final int lastReleaseDate;
  final num score;
  final int year;
  final int season;
  final List<int> countryList;
  final List<int> styleList;
  final int grading;
  final String introduction;
  final int type;
  final String posterPath;
  final String backdropPath;
  final String logoPath;
  final String tagline;
  final String noLangPosterPath;
  final String noLangBackdropPath;
  final String language;
  final String categoryId;
  final String oldCategoryId;
  final int allSeasonEpisodeNum;
  final int mediaLibSetId;
  final String collectionId;
  final int collectionTime;
  final String lastPlayFilePath;
  final int ctime;
  final int utime;
  final int clarity;
  final int localCount;

  const UgreenRelatedVideo({
    required this.ugVideoInfoId,
    required this.doubanId,
    required this.tmdbId,
    required this.ugMediaId,
    required this.useNfo,
    required this.name,
    required this.jpName,
    required this.pinyinFirst,
    required this.pinyinFull,
    required this.to9Digit,
    required this.releaseDate,
    required this.lastReleaseDate,
    required this.score,
    required this.year,
    required this.season,
    required this.countryList,
    required this.styleList,
    required this.grading,
    required this.introduction,
    required this.type,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.tagline,
    required this.noLangPosterPath,
    required this.noLangBackdropPath,
    required this.language,
    required this.categoryId,
    required this.oldCategoryId,
    required this.allSeasonEpisodeNum,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.collectionTime,
    required this.lastPlayFilePath,
    required this.ctime,
    required this.utime,
    required this.clarity,
    required this.localCount,
  });

  String get typeText => type == 2 ? '剧集' : '电影';

  String get coverPath => backdropPath.isNotEmpty ? backdropPath : posterPath;

  static UgreenRelatedVideo fromJson(Map<String, dynamic> json) {
    return UgreenRelatedVideo(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      doubanId: json['douban_id'] as int,
      tmdbId: json['tmdb_id'] as int,
      ugMediaId: json['ug_media_id'] as String,
      useNfo: json['use_nfo'] as int,
      name: json['name'] as String,
      jpName: json['jp_name'] as String,
      pinyinFirst: json['pinyin_first'] as String,
      pinyinFull: json['pinyin_full'] as String,
      to9Digit: json['to9_digit'] as String,
      releaseDate: json['release_date'] as int,
      lastReleaseDate: json['last_release_date'] as int,
      score: json['score'] as num,
      year: json['year'] as int,
      season: json['season'] as int,
      countryList: (json['country_list'] as List?)?.cast() ?? const [],
      styleList: (json['style_list'] as List?)?.cast() ?? const [],
      grading: json['grading'] as int,
      introduction: json['introduction'] as String,
      type: json['type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      noLangPosterPath: json['no_lang_poster_path'] as String,
      noLangBackdropPath: json['no_lang_backdrop_path'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      oldCategoryId: json['old_category_id'] as String,
      allSeasonEpisodeNum: json['all_season_episode_num'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      collectionTime: json['collection_time'] as int,
      lastPlayFilePath: json['last_play_file_path'] as String,
      ctime: json['ctime'] as int,
      utime: json['utime'] as int,
      clarity: json['clarity'] as int,
      localCount: json['local_count'] as int,
    );
  }
}
