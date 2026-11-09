import 'package:PiliPlus/pages/common/multi_select/base.dart';

class HistoryUgreenItemModel with MultiSelectData {
  final HistoryUgreenVideoInfo videoInfo;
  final HistoryUgreenPlayStatus playStatus;
  final bool isFavorite;
  final HistoryUgreenPermission userMediaLibPermission;

  HistoryUgreenItemModel({
    required this.videoInfo,
    required this.playStatus,
    required this.isFavorite,
    required this.userMediaLibPermission,
  });

  static HistoryUgreenItemModel? fromJson(Map<String, dynamic> json) {
    return HistoryUgreenItemModel(
      videoInfo: HistoryUgreenVideoInfo.fromJson(
        (json['video_info'] as Map).cast(),
      ),
      playStatus: HistoryUgreenPlayStatus.fromJson(
        (json['play_status'] as Map).cast(),
      ),
      isFavorite: json['is_favorite'] as bool,
      userMediaLibPermission: HistoryUgreenPermission.fromJson(
        (json['user_media_lib_permission'] as Map).cast(),
      ),
    );
  }
}

class HistoryUgreenVideoInfo {
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

  String get typeText {
    return switch (type) {
      1 => '电影',
      2 => '电视剧',
      3 => '合集',
      _ => '其它',
    };
  }

  const HistoryUgreenVideoInfo({
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

  static HistoryUgreenVideoInfo fromJson(Map<String, dynamic> json) {
    return HistoryUgreenVideoInfo(
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

class HistoryUgreenPlayStatus {
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

  const HistoryUgreenPlayStatus({
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

  static HistoryUgreenPlayStatus fromJson(Map<String, dynamic> json) {
    return HistoryUgreenPlayStatus(
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

class HistoryUgreenPermission {
  final int userMediaLibPermissionId;
  final int uid;
  final int mediaLibSetId;
  final bool canView;
  final bool canManage;
  final int createTime;

  const HistoryUgreenPermission({
    required this.userMediaLibPermissionId,
    required this.uid,
    required this.mediaLibSetId,
    required this.canView,
    required this.canManage,
    required this.createTime,
  });

  static HistoryUgreenPermission fromJson(Map<String, dynamic> json) {
    return HistoryUgreenPermission(
      userMediaLibPermissionId: json['user_media_lib_permission_id'] as int,
      uid: json['uid'] as int,
      mediaLibSetId: json['media_lib_set_id'] as int,
      canView: json['can_view'] as bool,
      canManage: json['can_manage'] as bool,
      createTime: json['create_time'] as int,
    );
  }
}
