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
  UgreenSearchGroup({
    super.numResults,
    super.list,
    this.cursor = 0,
  });

  int cursor;

  factory UgreenSearchGroup.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    if (json is! Map || json.isEmpty) {
      return UgreenSearchGroup<T>(numResults: 0, list: const [], cursor: 0);
    }
    final map = json.cast<String, dynamic>();
    final rawList = map['list'];
    return UgreenSearchGroup<T>(
      numResults: map['total_num'] as int,
      list: (rawList as List)
          .whereType<Map>()
          .map((e) => itemFromJson(e.cast<String, dynamic>()))
          .toList(),
      cursor: map['cursor'] as int,
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
  final String ugMediaId;
  final String name;
  final String jpName;
  final int type;
  final int year;
  final int releaseDate;
  final num score;
  final int duration;
  final String posterPath;
  final String backdropPath;
  final String logoPath;
  final String tagline;
  final String language;
  final String categoryId;
  final int mediaLibSetId;
  final String collectionId;
  final int localCount;
  final int episodeCount;
  final List<String> filePath;
  final int clarity;
  final bool isFavorite;
  final List<String> styleNames;
  final List<String> directors;
  final List<String> actors;
  final int doubanId;
  final int tmdbId;

  const UgreenSearchMedia({
    required this.ugVideoInfoId,
    required this.ugMediaId,
    required this.name,
    required this.jpName,
    required this.type,
    required this.year,
    required this.releaseDate,
    required this.score,
    required this.duration,
    required this.posterPath,
    required this.backdropPath,
    required this.logoPath,
    required this.tagline,
    required this.language,
    required this.categoryId,
    required this.mediaLibSetId,
    required this.collectionId,
    required this.localCount,
    required this.episodeCount,
    required this.filePath,
    required this.clarity,
    required this.isFavorite,
    required this.styleNames,
    required this.directors,
    required this.actors,
    required this.doubanId,
    required this.tmdbId,
  });

  static UgreenSearchMedia fromJson(Map<String, dynamic> json) {
    return UgreenSearchMedia(
      ugVideoInfoId: json['ug_video_info_id'] as int,
      ugMediaId: json['ug_media_id'] as String,
      name: json['name'] as String,
      jpName: json['jp_name'] as String,
      type: json['type'] as int,
      year: json['year'] as int,
      releaseDate: json['release_date'] as int,
      score: json['score'] as num,
      duration: json['duration'] as int,
      posterPath: json['poster_path'] as String,
      backdropPath: json['backdrop_path'] as String,
      logoPath: json['logo_path'] as String,
      tagline: json['tagline'] as String,
      language: json['language'] as String,
      categoryId: json['category_id'] as String,
      mediaLibSetId: json['media_lib_set_id'] as int,
      collectionId: json['collection_id'] as String,
      localCount: json['local_count'] as int,
      episodeCount: json['episode_count'] as int,
      filePath: (json['file_path'] as List).cast(),
      clarity: json['clarity'] as int,
      isFavorite: json['is_favorite'] as bool,
      styleNames: (json['style_names'] as List?)?.cast() ?? [],
      directors: (json['directors'] as List?)?.cast() ?? [],
      actors: (json['actors'] as List?)?.cast() ?? [],
      doubanId: json['douban_id'] as int,
      tmdbId: json['tmdb_id'] as int,
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
  final String name;
  final String alias;
  final String avatarUrl;
  final int creditsCount;

  const UgreenSearchPeople({
    required this.actorOnceId,
    required this.name,
    required this.alias,
    required this.avatarUrl,
    required this.creditsCount,
  });

  static UgreenSearchPeople fromJson(Map<String, dynamic> json) {
    return UgreenSearchPeople(
      actorOnceId: json['actor_once_id'] as String,
      name: json['name'] as String,
      alias: json['alias'] as String,
      avatarUrl: json['avatar_url'] as String,
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
  const UgreenSearchMediaEntry(this.item);

  final UgreenSearchMedia item;
}

class UgreenSearchCollectionEntry extends UgreenSearchEntry {
  const UgreenSearchCollectionEntry(this.item);

  final UgreenSearchCollection item;
}

class UgreenSearchPeopleEntry extends UgreenSearchEntry {
  const UgreenSearchPeopleEntry(this.item);

  final UgreenSearchPeople item;
}

class UgreenSearchFileEntry extends UgreenSearchEntry {
  const UgreenSearchFileEntry(this.item);

  final UgreenSearchFile item;
}
