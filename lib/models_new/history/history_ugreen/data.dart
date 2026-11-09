import 'package:PiliPlus/models_new/history/history_ugreen/list.dart';

class HistoryUgreenData {
  final int totalNum;
  final bool isLastPage;
  final List<HistoryUgreenItemModel> videoArr;

  const HistoryUgreenData({
    required this.totalNum,
    required this.isLastPage,
    required this.videoArr,
  });

  static HistoryUgreenData fromJson(Map<String, dynamic> json) {
    return HistoryUgreenData(
      totalNum: json['total_num'] as int,
      isLastPage: json['is_last_page'] as bool,
      videoArr: (json['video_arr'] as List)
          .whereType<Map>()
          .map((e) => HistoryUgreenItemModel.fromJson(e.cast()))
          .whereType<HistoryUgreenItemModel>()
          .toList(),
    );
  }
}
