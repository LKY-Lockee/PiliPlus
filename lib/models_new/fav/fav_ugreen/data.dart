import 'package:PiliPlus/models_new/fav/fav_ugreen/list.dart';

class FavUgreenData {
  final int totalNum;
  final List<FavUgreenItemModel> videoArr;

  const FavUgreenData({
    required this.totalNum,
    required this.videoArr,
  });

  static FavUgreenData fromJson(Map<String, dynamic> json) {
    return FavUgreenData(
      totalNum: json['total_num'] as int,
      videoArr: (json['video_arr'] as List)
          .whereType<Map>()
          .map((e) => FavUgreenItemModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
