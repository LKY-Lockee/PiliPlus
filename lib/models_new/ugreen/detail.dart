class UgreenVideoSummary {
  final int ugVideoInfoId;
  final int doubanId;
  final int tmdbId;
  final int useNfo;
  final String name;
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
  final int duration;
  final List<String> filePath;
  final String introduction;
  final int type;
  final String posterPath;
  final String backdropPath;
  final String language;
  final String categoryId;
  final String oldCategoryId;
  final int clarity;
  final String clarityShow;
  final String imageQuality;
  final String audioQuality;
  final int allSeasonEpisodeNum;
  final int localCount;
  final int mediaLibSetId;
  final String collectionId;
  final int collectionTime;
  final String lastPlayFilePath;
  final int ctime;
  final int utime;
  final String logoPath;
  final String tagline;
  final String noLangPosterPath;
  final String noLangBackdropPath;

  String get typeText => type == 2 ? '剧集' : '电影';

  const UgreenVideoSummary({
    required this.ugVideoInfoId,
    required this.doubanId,
    required this.tmdbId,
    required this.useNfo,
    required this.name,
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
    required this.duration,
    required this.filePath,
    required this.introduction,
    required this.type,
    required this.posterPath,
    required this.backdropPath,
    required this.language,
    required this.categoryId,
    required this.oldCategoryId,
    required this.clarity,
    required this.clarityShow,
    required this.imageQuality,
    required this.audioQuality,
    required this.allSeasonEpisodeNum,
    required this.localCount,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.collectionTime,
    required this.lastPlayFilePath,
    required this.ctime,
    required this.utime,
    required this.logoPath,
    required this.tagline,
    required this.noLangPosterPath,
    required this.noLangBackdropPath,
  });

  static UgreenVideoSummary fromJson(Map<String, dynamic> json) {
    return UgreenVideoSummary(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      doubanId: json['douban_id'] as int,
      tmdbId: json['tmdb_id'] as int,
      useNfo: json['use_nfo'] as int,
      name: json['name'] as String,
      pinyinFirst: json['pinyin_first'] as String,
      pinyinFull: json['pinyin_full'] as String,
      to9Digit: json['to9_digit'] as String,
      releaseDate: json['release_date'] as int,
      lastReleaseDate: json['last_release_date'] as int,
      score: json['score'] as num,
      year: json['year'] as int,
      season: json['season'] as int,
      countryList: (json['country_list'] as List).cast(),
      styleList: (json['style_list'] as List).cast(),
      grading: json['grading'] as int,
      duration: json['duration'] as int,
      filePath: (json['file_path'] as List).cast(),
      introduction: json['introduction'] as String,
      type: json['type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      oldCategoryId: json['old_category_id'] as String,
      clarity: json['clarity'] as int,
      clarityShow: json['clarity_show'] as String,
      imageQuality: json['image_quality'] as String,
      audioQuality: json['audio_quality'] as String,
      allSeasonEpisodeNum: json['all_season_episode_num'] as int,
      localCount: json['local_count'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      collectionTime: json['collection_time'] as int,
      lastPlayFilePath: json['last_play_file_path'] as String,
      ctime: json['ctime'] as int,
      utime: json['utime'] as int,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      noLangPosterPath: json['no_lang_poster_path'] as String,
      noLangBackdropPath: json['no_lang_backdrop_path'] as String,
    );
  }
}

class UgreenPlayStatus {
  final int playHistoryId;
  final int uid;
  final String categoryId;
  final int ugVideoInfoId;
  final int ugTelevisionEpisodeId;
  final int episode;
  final int mediaLibSetId;
  final int currentPlayTime;
  final int lastAccessTime;
  final String recentlyPlayedFilePath;
  final num progress;
  final int watchStatus;
  final int videoType;
  final int playType;
  final String isoTs;
  final int type;
  final String tvName;
  final String coverPath;
  final String folderPath;

  const UgreenPlayStatus({
    required this.playHistoryId,
    required this.uid,
    required this.categoryId,
    required this.ugVideoInfoId,
    required this.ugTelevisionEpisodeId,
    required this.episode,
    required this.mediaLibSetId,
    required this.currentPlayTime,
    required this.lastAccessTime,
    required this.recentlyPlayedFilePath,
    required this.progress,
    required this.watchStatus,
    required this.videoType,
    required this.playType,
    required this.isoTs,
    required this.type,
    required this.tvName,
    required this.coverPath,
    required this.folderPath,
  });

  static UgreenPlayStatus fromJson(Map<String, dynamic> json) {
    return UgreenPlayStatus(
      playHistoryId: json['play_history_id'] as int,
      uid: json['uid'] as int,
      categoryId: json['category_id'] as String,
      ugVideoInfoId: json['ug_video_info_id'] as int,
      ugTelevisionEpisodeId: json['ug_television_episode_id'] as int,
      episode: json['episode'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      currentPlayTime: json['current_play_time'] as int,
      lastAccessTime: json['last_access_time'] as int,
      recentlyPlayedFilePath: json['recently_played_file_path'] as String,
      progress: json['progress'] as num,
      watchStatus: json['watch_status'] as int,
      videoType: json['video_type'] as int,
      playType: json['PlayType'] as int,
      isoTs: json['iso_ts'] as String,
      type: json['type'] as int,
      tvName: json['tv_name'] as String,
      coverPath: json['cover_path'] as String,
      folderPath: json['folder_path'] as String,
    );
  }
}

class UgreenActorDetail {
  final int ugActorId;
  final int actorId;
  final int actorDataSource;
  final String actorOnceId;
  final String name;
  final String pinyinFirst;
  final String pinyinFull;
  final String introduction;
  final String country;
  final String alias;
  final int birthday;
  final int gender;
  final String language;
  final String avatarUrl;
  final bool lock;
  final int source;
  final int ctime;
  final int utime;
  final String role;
  final String department;

  const UgreenActorDetail({
    required this.ugActorId,
    required this.actorId,
    required this.actorDataSource,
    required this.actorOnceId,
    required this.name,
    required this.pinyinFirst,
    required this.pinyinFull,
    required this.introduction,
    required this.country,
    required this.alias,
    required this.birthday,
    required this.gender,
    required this.language,
    required this.avatarUrl,
    required this.lock,
    required this.source,
    required this.ctime,
    required this.utime,
    required this.role,
    required this.department,
  });

  static UgreenActorDetail fromJson(Map<String, dynamic> json) {
    return UgreenActorDetail(
      ugActorId: json['ug_actor_id'] as int,
      actorId: json['actor_id'] as int,
      actorDataSource: json['actor_data_source'] as int,
      actorOnceId: json['actor_once_id'] as String,
      name: json['name'] as String,
      pinyinFirst: json['pinyin_first'] as String,
      pinyinFull: json['pinyin_full'] as String,
      introduction: json['introduction'] as String,
      country: json['country'] as String,
      alias: json['alias'] as String,
      birthday: json['birthday'] as int,
      gender: json['gender'] as int,
      language: json['language'] as String,
      avatarUrl: json['avatar_url'] as String,
      lock: json['lock'] as bool,
      source: json['source'] as int,
      ctime: json['ctime'] as int,
      utime: json['utime'] as int,
      role: json['role'] as String,
      department: json['department'] as String,
    );
  }
}

class UgreenSeasonInfo {
  final int seasonNum;
  final int ugVideoInfoId;
  final String categoryId;
  final String name;

  const UgreenSeasonInfo({
    required this.seasonNum,
    required this.ugVideoInfoId,
    required this.categoryId,
    required this.name,
  });

  static UgreenSeasonInfo fromJson(Map<String, dynamic> json) {
    return UgreenSeasonInfo(
      seasonNum: json['season_num'] as int,
      ugVideoInfoId: json['ug_video_info_id'] as int,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
    );
  }
}

class UgreenMovieDetail {
  final UgreenVideoSummary videoInfo;
  final List<UgreenActorDetail> ugActorArr;
  final bool isFavorite;
  final UgreenPlayStatus playStatus;
  final int metadataLockStatus;

  const UgreenMovieDetail({
    required this.videoInfo,
    required this.ugActorArr,
    required this.isFavorite,
    required this.playStatus,
    required this.metadataLockStatus,
  });

  static UgreenMovieDetail fromJson(Map<String, dynamic> json) {
    return UgreenMovieDetail(
      videoInfo: UgreenVideoSummary.fromJson(json['video_info']),
      ugActorArr:
          (json['ug_actor_arr'] as List?)
              ?.whereType<Map>()
              .map((e) => UgreenActorDetail.fromJson((e).cast()))
              .whereType<UgreenActorDetail>()
              .toList() ??
          [],
      isFavorite: json['is_favorite'] as bool,
      playStatus: UgreenPlayStatus.fromJson(json['play_status']),
      metadataLockStatus: json['metadata_lock_status'] as int,
    );
  }
}

class UgreenTvDetail {
  final UgreenVideoSummary videoInfo;
  final List<UgreenActorDetail> ugActorArr;
  final bool isFavorite;
  final UgreenPlayStatus playStatus;
  final List<UgreenTvEpisode> tvInfo;
  final List<String> folderPaths;
  final String selectFolder;
  final int metadataLockStatus;
  final List<UgreenSeasonInfo> seasonInfo;

  const UgreenTvDetail({
    required this.videoInfo,
    required this.ugActorArr,
    required this.isFavorite,
    required this.playStatus,
    required this.tvInfo,
    required this.folderPaths,
    required this.selectFolder,
    required this.metadataLockStatus,
    required this.seasonInfo,
  });

  static UgreenTvDetail fromJson(Map<String, dynamic> json) {
    return UgreenTvDetail(
      videoInfo: UgreenVideoSummary.fromJson(json['video_info']),
      ugActorArr: (json['ug_actor_arr'] as List)
          .whereType<Map>()
          .map((e) => UgreenActorDetail.fromJson((e).cast()))
          .whereType<UgreenActorDetail>()
          .toList(),
      isFavorite: json['is_favorite'] as bool,
      playStatus: UgreenPlayStatus.fromJson(json['play_status']),
      tvInfo: (json['tv_info'] as List)
          .whereType<Map>()
          .map((e) => UgreenTvEpisode.fromJson((e).cast()))
          .whereType<UgreenTvEpisode>()
          .toList(),
      folderPaths: (json['folder_paths'] as List).cast(),
      selectFolder: json['select_folder'] as String,
      metadataLockStatus: json['metadata_lock_status'] as int,
      seasonInfo: (json['season_info'] as List)
          .whereType<Map>()
          .map((e) => UgreenSeasonInfo.fromJson((e).cast()))
          .whereType<UgreenSeasonInfo>()
          .toList(),
    );
  }
}

class UgreenTvEpisode {
  final int ugTelevisionEpisodeId;
  final String epName;
  final String categoryId;
  final String coverPath;
  final int episode;
  final String episodeFlag;
  final String recentlyPlayedFilePath;
  final List<UgreenTvEpisodeFile> fileInfo;
  final String overview;

  const UgreenTvEpisode({
    required this.ugTelevisionEpisodeId,
    required this.epName,
    required this.categoryId,
    required this.coverPath,
    required this.episode,
    required this.episodeFlag,
    required this.recentlyPlayedFilePath,
    required this.fileInfo,
    required this.overview,
  });

  static UgreenTvEpisode fromJson(Map<String, dynamic> json) {
    return UgreenTvEpisode(
      ugTelevisionEpisodeId: json['ug_television_episode_id'] as int,
      epName: json['ep_name'] as String,
      categoryId: json['category_id'] as String,
      coverPath: json['cover_path'] as String,
      episode: json['episode'] as int,
      episodeFlag: json['episode_flag'] as String,
      recentlyPlayedFilePath: json['recently_played_file_path'] as String,
      fileInfo: (json['file_info'] as List)
          .whereType<Map>()
          .map((e) => UgreenTvEpisodeFile.fromJson(e.cast()))
          .whereType<UgreenTvEpisodeFile>()
          .toList(),
      overview: json['overview'] as String,
    );
  }
}

class UgreenTvEpisodeFile {
  final int fileId;
  final String path;
  final String showPath;
  final num progress;
  final int duration;
  final int size;
  final int clarity;
  final int currentPlayTime;
  final int watchStatus;
  final String isoTs;
  final int ctime;
  final int lastPlayTime;

  const UgreenTvEpisodeFile({
    required this.fileId,
    required this.path,
    required this.showPath,
    required this.progress,
    required this.duration,
    required this.size,
    required this.clarity,
    required this.currentPlayTime,
    required this.watchStatus,
    required this.isoTs,
    required this.ctime,
    required this.lastPlayTime,
  });

  static UgreenTvEpisodeFile fromJson(Map<String, dynamic> json) {
    return UgreenTvEpisodeFile(
      fileId: json['file_id'] as int,
      path: json['path'] as String,
      showPath: json['show_path'] as String,
      progress: json['progress'] as num,
      duration: json['duration'] as int,
      size: json['size'] as int,
      clarity: json['clarity'] as int,
      currentPlayTime: json['current_play_time'] as int,
      watchStatus: json['watch_status'] as int,
      isoTs: json['iso_ts'] as String,
      ctime: json['ctime'] as int,
      lastPlayTime: json['LastPlayTime'] as int,
    );
  }
}
