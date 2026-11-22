import 'package:PiliPlus/models_new/history/history_ugreen/list.dart';

class FavUgreenItemModel {
  final HistoryUgreenVideoInfo videoInfo;
  final HistoryUgreenPlayStatus playStatus;
  final bool isFavorite;

  const FavUgreenItemModel({
    required this.videoInfo,
    required this.playStatus,
    required this.isFavorite,
  });

  static FavUgreenItemModel fromJson(Map<String, dynamic> json) {
    return FavUgreenItemModel(
      videoInfo: HistoryUgreenVideoInfo.fromJson(
        (json['video_info'] as Map).cast(),
      ),
      playStatus: HistoryUgreenPlayStatus.fromJson(
        (json['play_status'] as Map).cast(),
      ),
      isFavorite: json['is_favorite'] as bool,
    );
  }
}
