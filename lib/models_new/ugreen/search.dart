import 'package:PiliPlus/models/search/result.dart';

enum UgreenSearchType {
  all('全部', 1),
  media('影视', 7),
  people('演员', 5),
  collection('合集', 4),
  file('文件', 6);

  final String label;
  final int value;

  const UgreenSearchType(this.label, this.value);

  static const List<UgreenSearchType> actives = [
    all,
    media,
    people,
    collection,
    file,
  ];
}

class UgreenSearchGroup<T> extends SearchNumData<T> {
  int cursor;

  UgreenSearchGroup({
    super.numResults,
    super.list,
    this.cursor = 0,
  });

  factory UgreenSearchGroup.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    if (json.isEmpty) {
      return UgreenSearchGroup<T>(numResults: 0, list: const [], cursor: 0);
    }
    return UgreenSearchGroup<T>(
      numResults: json['total_num'] as int,
      list:
          (json['list'] as List?)
              ?.whereType<Map>()
              .map((e) => itemFromJson(e.cast<String, dynamic>()))
              .toList() ??
          const [],
      cursor: json['cursor'] as int,
    );
  }
}

class UgreenSearchData {
  final UgreenSearchGroup<UgreenSearchMedia> media;
  final UgreenSearchGroup<UgreenSearchCollection> collection;
  final UgreenSearchGroup<UgreenSearchPeople> people;
  final UgreenSearchGroup<Map<String, dynamic>> folder;
  final UgreenSearchGroup<UgreenSearchFile> file;

  const UgreenSearchData({
    required this.media,
    required this.collection,
    required this.people,
    required this.folder,
    required this.file,
  });

  factory UgreenSearchData.empty() => UgreenSearchData(
    media: UgreenSearchGroup<UgreenSearchMedia>(),
    collection: UgreenSearchGroup<UgreenSearchCollection>(),
    people: UgreenSearchGroup<UgreenSearchPeople>(),
    folder: UgreenSearchGroup<Map<String, dynamic>>(),
    file: UgreenSearchGroup<UgreenSearchFile>(),
  );

  static UgreenSearchData fromJson(Map<String, dynamic> json) {
    return UgreenSearchData(
      media: UgreenSearchGroup.fromJson(
        json['media'],
        UgreenSearchMedia.fromJson,
      ),
      collection: UgreenSearchGroup.fromJson(
        json['collection'],
        UgreenSearchCollection.fromJson,
      ),
      people: UgreenSearchGroup.fromJson(
        json['people'],
        UgreenSearchPeople.fromJson,
      ),
      folder: UgreenSearchGroup.fromJson(
        json['folder'],
        (e) => e,
      ),
      file: UgreenSearchGroup.fromJson(
        json['file'],
        UgreenSearchFile.fromJson,
      ),
    );
  }
}

class UgreenSearchMedia {
  final int ugVideoInfoId;
  final int doubanId;
  final int tmdbId;
  final int useNfo;
  final String ugMediaId;
  final String name;
  final String jpName;
  final String pinyinFirst;
  final String pinyinFull;
  final String to9Digit;
  final int releaseDate;
  final int type;
  final int year;
  final String posterPath;
  final String backdropPath;
  final String logoPath;
  final String tagline;
  final String noLangPosterPath;
  final String noLangBackdropPath;
  final String language;
  final String categoryId;
  final String oldCategoryId;
  final int mediaLibSetId;
  final String collectionId;
  final int collectionTime;
  final String lastPlayFilePath;
  final num score;
  final List<String> filePath;
  final int clarity;
  final int duration;
  final String videoQuality;
  final String audioQuality;
  final int localCount;
  final int episodeCount;
  final bool isFavorite;
  final List<int> styleList;
  final List<String> styleNames;
  final List<String> directors;
  final List<String> actors;

  const UgreenSearchMedia({
    required this.ugVideoInfoId,
    required this.doubanId,
    required this.tmdbId,
    required this.useNfo,
    required this.ugMediaId,
    required this.name,
    required this.jpName,
    required this.pinyinFirst,
    required this.pinyinFull,
    required this.to9Digit,
    required this.releaseDate,
    required this.type,
    required this.year,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.tagline,
    required this.noLangPosterPath,
    required this.noLangBackdropPath,
    required this.language,
    required this.categoryId,
    required this.oldCategoryId,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.collectionTime,
    required this.lastPlayFilePath,
    required this.score,
    required this.filePath,
    required this.clarity,
    required this.duration,
    required this.videoQuality,
    required this.audioQuality,
    required this.localCount,
    required this.episodeCount,
    required this.isFavorite,
    required this.styleList,
    required this.styleNames,
    required this.directors,
    required this.actors,
  });

  static UgreenSearchMedia fromJson(Map<String, dynamic> json) {
    return UgreenSearchMedia(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      doubanId: json['douban_id'] as int,
      tmdbId: json['tmdb_id'] as int,
      useNfo: json['use_nfo'] as int,
      ugMediaId: json['ug_media_id'] as String,
      name: json['name'] as String,
      jpName: json['jp_name'] as String,
      pinyinFirst: json['pinyin_first'] as String,
      pinyinFull: json['pinyin_full'] as String,
      to9Digit: json['to9_digit'] as String,
      releaseDate: json['release_date'] as int,
      type: json['type'] as int,
      year: json['year'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      noLangPosterPath: json['no_lang_poster_path'] as String,
      noLangBackdropPath: json['no_lang_backdrop_path'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      oldCategoryId: json['old_category_id'] as String,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      collectionTime: json['collection_time'] as int,
      lastPlayFilePath: json['last_play_file_path'] as String,
      score: json['score'] as num,
      filePath: (json['file_path'] as List?)?.cast() ?? const [],
      clarity: json['clarity'] as int,
      duration: json['duration'] as int,
      videoQuality: json['video_quality'] as String,
      audioQuality: json['audio_quality'] as String,
      localCount: json['local_count'] as int,
      episodeCount: json['episode_count'] as int,
      isFavorite: json['is_favorite'] as bool,
      styleList: (json['style_list'] as List?)?.cast() ?? const [],
      styleNames: (json['style_names'] as List?)?.cast() ?? const [],
      directors: (json['directors'] as List?)?.cast() ?? const [],
      actors: (json['actors'] as List?)?.cast() ?? const [],
    );
  }
}

class UgreenSearchCollection {
  final String name;
  final int releaseDate;
  final num score;
  final int localCount;
  final String introduction;
  final int type;
  final String posterPath;
  final String backdropPath;
  final String language;
  final int mediaLibSetId;
  final String collectionId;
  final String tmdbId;

  const UgreenSearchCollection({
    required this.name,
    required this.releaseDate,
    required this.score,
    required this.localCount,
    required this.introduction,
    required this.type,
    required this.posterPath,
    required this.backdropPath,
    required this.language,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.tmdbId,
  });

  static UgreenSearchCollection fromJson(Map<String, dynamic> json) {
    return UgreenSearchCollection(
      name: json['name'] as String,
      releaseDate: json['release_date'] as int,
      score: json['score'] as num,
      localCount: json['local_count'] as int,
      introduction: json['introduction'] as String,
      type: json['type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      language: json['language'] as String,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      tmdbId: json['tmdb_id'] as String,
    );
  }
}

class UgreenSearchPeople {
  final String actorOnceId;
  final String avatarUrl;
  final String alias;
  final String name;
  final int creditsCount;

  const UgreenSearchPeople({
    required this.actorOnceId,
    required this.avatarUrl,
    required this.alias,
    required this.name,
    required this.creditsCount,
  });

  static UgreenSearchPeople fromJson(Map<String, dynamic> json) {
    return UgreenSearchPeople(
      actorOnceId: json['actor_once_id'] as String,
      avatarUrl: json['avatar_url'] as String,
      alias: json['alias'] as String,
      name: json['name'] as String,
      creditsCount: json['credits_count'] as int,
    );
  }
}

class UgreenSearchFile {
  final int fileId;
  final String videoName;
  final String fileName;
  final String filePath;
  final String folderPath;
  final int clarity;
  final String clarityShow;
  final int mediaLibSetId;
  final int ugVideoInfoId;
  final int videoType;
  final String posterPath;
  final String backdropPath;

  const UgreenSearchFile({
    required this.fileId,
    required this.videoName,
    required this.fileName,
    required this.filePath,
    required this.folderPath,
    required this.clarity,
    required this.clarityShow,
    required this.mediaLibSetId,
    required this.ugVideoInfoId,
    required this.videoType,
    required this.posterPath,
    required this.backdropPath,
  });

  static UgreenSearchFile fromJson(Map<String, dynamic> json) {
    return UgreenSearchFile(
      fileId: json['file_id'] as int,
      videoName: json['video_name'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      folderPath: json['folder_path'] as String,
      clarity: json['clarity'] as int,
      clarityShow: json['clarity_show'] as String,
      mediaLibSetId: json['media_lib_set_id'] as int,
      ugVideoInfoId: json['ug_video_info_id'] as int,
      videoType: json['video_type'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
    );
  }
}

sealed class UgreenSearchEntry {
  const UgreenSearchEntry();
}

class UgreenSearchMediaEntry extends UgreenSearchEntry {
  final UgreenSearchMedia item;

  const UgreenSearchMediaEntry(this.item);
}

class UgreenSearchCollectionEntry extends UgreenSearchEntry {
  final UgreenSearchCollection item;

  const UgreenSearchCollectionEntry(this.item);
}

class UgreenSearchPeopleEntry extends UgreenSearchEntry {
  final UgreenSearchPeople item;

  const UgreenSearchPeopleEntry(this.item);
}

class UgreenSearchFileEntry extends UgreenSearchEntry {
  final UgreenSearchFile item;

  const UgreenSearchFileEntry(this.item);
}
