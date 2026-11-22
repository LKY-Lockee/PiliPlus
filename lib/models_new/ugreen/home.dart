class UgreenHomeData {
  final UgreenHomeSection<UgreenHomeHistory> recentlyPlayedArr;
  final UgreenHomeSection<UgreenHomeVideo> recentlyUpdateArr;
  final UgreenHomeSection<UgreenHomeVideo> favoritesArr;

  const UgreenHomeData({
    required this.recentlyPlayedArr,
    required this.recentlyUpdateArr,
    required this.favoritesArr,
  });

  static UgreenHomeData fromJson(Map<String, dynamic> json) {
    return UgreenHomeData(
      recentlyPlayedArr: UgreenHomeSection<UgreenHomeHistory>.fromJson(
        (json['recently_played_arr'] as Map).cast(),
        UgreenHomeHistory.fromJson,
      ),
      recentlyUpdateArr: UgreenHomeSection<UgreenHomeVideo>.fromJson(
        (json['recently_update_arr'] as Map).cast(),
        UgreenHomeVideo.fromJson,
      ),
      favoritesArr: UgreenHomeSection<UgreenHomeVideo>.fromJson(
        (json['favorites_arr'] as Map).cast(),
        UgreenHomeVideo.fromJson,
      ),
    );
  }
}

class UgreenHomeSection<T> {
  final int totalNum;
  final List<T> videoArr;

  const UgreenHomeSection({
    required this.totalNum,
    required this.videoArr,
  });

  factory UgreenHomeSection.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return UgreenHomeSection<T>(
      totalNum: json['total_num'] as int,
      videoArr: (json['video_arr'] as List)
          .whereType<Map>()
          .map((e) => itemFromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class UgreenHomeVideo {
  final int ugVideoInfoId;
  final String name;
  final int releaseDate;
  final num score;
  final int year;
  final int localCount;
  final int episodeCount;
  final List<int> countryList;
  final List<int> styleList;
  final int grading;
  final List<String> filePath;
  final String introduction;
  final int type;
  final String posterPath;
  final String backdropPath;
  final String language;
  final String categoryId;
  final int clarity;
  final int mediaLibSetId;
  final String collectionId;
  final int useNfo;
  final bool isFavorites;
  final int ctime;
  final int utime;
  final String logoPath;
  final String tagline;
  final String noLangPosterPath;
  final String noLangBackdropPath;
  final int tmdbId;
  final int doubanId;

  const UgreenHomeVideo({
    required this.ugVideoInfoId,
    required this.name,
    required this.releaseDate,
    required this.score,
    required this.year,
    required this.localCount,
    required this.episodeCount,
    required this.countryList,
    required this.styleList,
    required this.grading,
    required this.filePath,
    required this.introduction,
    required this.type,
    required this.posterPath,
    required this.backdropPath,
    required this.language,
    required this.categoryId,
    required this.clarity,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.useNfo,
    required this.isFavorites,
    required this.ctime,
    required this.utime,
    required this.logoPath,
    required this.tagline,
    required this.noLangPosterPath,
    required this.noLangBackdropPath,
    required this.tmdbId,
    required this.doubanId,
  });

  static UgreenHomeVideo fromJson(Map<String, dynamic> json) {
    return UgreenHomeVideo(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      name: json['name'] as String,
      releaseDate: json['release_date'] as int,
      score: json['score'] as num,
      year: json['year'] as int,
      localCount: json['local_count'] as int,
      episodeCount: json['episode_count'] as int,
      countryList: (json['country_list'] as List).cast(),
      styleList: (json['style_list'] as List).cast(),
      grading: json['grading'] as int,
      filePath: (json['file_path'] as List).cast(),
      introduction: json['introduction'] as String,
      type: json['type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      clarity: json['clarity'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      useNfo: json['use_nfo'] as int,
      isFavorites: json['is_favorites'] as bool,
      ctime: json['ctime'] as int,
      utime: json['utime'] as int,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      noLangPosterPath: json['no_lang_poster_path'] as String,
      noLangBackdropPath: json['no_lang_backdrop_path'] as String,
      tmdbId: json['TmdbID'] as int,
      doubanId: json['DoubanID'] as int,
    );
  }
}

class UgreenHomeHistory {
  final int ugVideoInfoId;
  final String name;
  final int releaseDate;
  final num score;
  final int year;
  final int localCount;
  final int episodeCount;
  final List<int> countryList;
  final List<int> styleList;
  final int grading;
  final List<String> filePath;
  final String introduction;
  final int type;
  final String posterPath;
  final String backdropPath;
  final String language;
  final String categoryId;
  final int clarity;
  final int mediaLibSetId;
  final String collectionId;
  final int useNfo;
  final bool isFavorites;
  final int ctime;
  final int utime;
  final String logoPath;
  final String tagline;
  final String noLangPosterPath;
  final String noLangBackdropPath;
  final int tmdbId;
  final int doubanId;
  final int seasonNum;
  final String epName;
  final int episode;
  final String coverPath;
  final int currentPlayTime;
  final double progress;
  final int duration;
  final String isoTs;
  final String recentlyPlayedFilePath;

  const UgreenHomeHistory({
    required this.ugVideoInfoId,
    required this.name,
    required this.releaseDate,
    required this.score,
    required this.year,
    required this.localCount,
    required this.episodeCount,
    required this.countryList,
    required this.styleList,
    required this.grading,
    required this.filePath,
    required this.introduction,
    required this.type,
    required this.posterPath,
    required this.backdropPath,
    required this.language,
    required this.categoryId,
    required this.clarity,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.useNfo,
    required this.isFavorites,
    required this.ctime,
    required this.utime,
    required this.logoPath,
    required this.tagline,
    required this.noLangPosterPath,
    required this.noLangBackdropPath,
    required this.tmdbId,
    required this.doubanId,
    required this.seasonNum,
    required this.epName,
    required this.episode,
    required this.coverPath,
    required this.currentPlayTime,
    required this.progress,
    required this.duration,
    required this.isoTs,
    required this.recentlyPlayedFilePath,
  });

  static UgreenHomeHistory fromJson(Map<String, dynamic> json) {
    return UgreenHomeHistory(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      name: json['name'] as String,
      releaseDate: json['release_date'] as int,
      score: json['score'] as num,
      year: json['year'] as int,
      localCount: json['local_count'] as int,
      episodeCount: json['episode_count'] as int,
      countryList: (json['country_list'] as List).cast(),
      styleList: (json['style_list'] as List).cast(),
      grading: json['grading'] as int,
      filePath: (json['file_path'] as List).cast(),
      introduction: json['introduction'] as String,
      type: json['type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      clarity: json['clarity'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      useNfo: json['use_nfo'] as int,
      isFavorites: json['is_favorites'] as bool,
      ctime: json['ctime'] as int,
      utime: json['utime'] as int,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      noLangPosterPath: json['no_lang_poster_path'] as String,
      noLangBackdropPath: json['no_lang_backdrop_path'] as String,
      tmdbId: json['TmdbID'] as int,
      doubanId: json['DoubanID'] as int,
      seasonNum: json['season_num'] as int,
      epName: json['ep_name'] as String,
      episode: json['episode'] as int,
      coverPath: json['cover_path'] as String,
      currentPlayTime: json['current_play_time'] as int,
      progress: (json['progress'] as num).toDouble(),
      duration: json['duration'] as int,
      isoTs: json['iso_ts'] as String,
      recentlyPlayedFilePath: json['recently_played_file_path'] as String,
    );
  }
}
