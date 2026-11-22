import 'package:PiliPlus/models_new/ugreen/detail.dart';
import 'package:collection/collection.dart';

class UgreenPlayEpisode {
  final int index;
  final int episode;
  final String title;
  final String? overview;
  final int? ugTelevisionEpisodeId;
  final String? categoryId;
  final List<UgreenPlayFile> files;

  const UgreenPlayEpisode({
    required this.index,
    required this.episode,
    required this.title,
    this.overview,
    this.ugTelevisionEpisodeId,
    this.categoryId,
    required this.files,
  });

  factory UgreenPlayEpisode.fromTvEpisode(UgreenTvEpisode item, int index) {
    return UgreenPlayEpisode(
      index: index,
      episode: item.episode,
      title: item.epName.isEmpty ? '第${item.episode}集' : item.epName,
      overview: item.overview,
      ugTelevisionEpisodeId: item.ugTelevisionEpisodeId,
      categoryId: item.categoryId,
      files: item.fileInfo
          .map(
            (file) => UgreenPlayFile(
              fileId: file.fileId,
              path: file.path,
              showPath: file.showPath,
              duration: file.duration,
              clarity: file.clarity,
              progress: file.progress,
              currentPlayTime: file.currentPlayTime,
              watchStatus: file.watchStatus,
            ),
          )
          .toList(),
    );
  }

  factory UgreenPlayEpisode.fromMovie(UgreenMovieDetail detail, int index) {
    final info = detail.videoInfo;
    return UgreenPlayEpisode(
      index: index,
      episode: 0,
      title: info.name,
      overview: info.introduction,
      files: info.filePath
          .map(
            (path) => UgreenPlayFile(
              fileId: 0,
              path: path,
              showPath: path,
              duration: info.duration,
              clarity: info.clarity,
              progress: 0,
              currentPlayTime: 0,
              watchStatus: 0,
            ),
          )
          .toList(),
    );
  }

  UgreenPlayFile? get firstFile => files.firstOrNull;

  String get displayTitle => episode > 0 ? '第$episode集 $title' : title;
}

class UgreenPlayFile {
  final int fileId;
  final String path;
  final String showPath;
  final int duration;
  final int clarity;
  final num progress;
  final int currentPlayTime;
  final int watchStatus;

  bool get isCompleted => watchStatus == 2 || progress >= 1;

  const UgreenPlayFile({
    required this.fileId,
    required this.path,
    required this.showPath,
    required this.duration,
    required this.clarity,
    required this.progress,
    required this.currentPlayTime,
    required this.watchStatus,
  });
}
