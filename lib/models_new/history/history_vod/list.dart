import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';

/// com.github.tvbox.osc.cache.VodRecord
class HistoryVodItemModel with MultiSelectData {
  /// com.github.tvbox.osc.cache.VodRecord.sourceKey
  String sourceKey;

  /// com.github.tvbox.osc.cache.VodRecord.vodId
  String vodId;

  /// com.github.tvbox.osc.bean.VodInfo.name
  String? title;

  /// com.github.tvbox.osc.bean.VodInfo.pic
  String? cover;

  /// com.github.tvbox.osc.bean.VodInfo.note
  String? remarks;

  /// com.github.tvbox.osc.bean.VodInfo.playFlag
  String? playFlag;

  /// com.github.tvbox.osc.bean.VodInfo.playIndex
  int? playIndex;

  String? showTitle;

  /// com.github.tvbox.osc.cache.VodRecord.updateTime
  int? viewAt;

  int? duration;
  int? progress;

  String get vodKey => 'tvbox.$sourceKey.$vodId';

  bool get isFav => VodCollect.isFav(sourceKey, vodId);

  HistoryVodItemModel({
    required this.sourceKey,
    required this.vodId,
    this.title,
    this.cover,
    this.remarks,
    this.playFlag,
    this.playIndex,
    this.showTitle,
    this.viewAt,
    this.duration,
    this.progress,
  });

  factory HistoryVodItemModel.fromJson(Map<dynamic, dynamic> json) =>
      HistoryVodItemModel(
        sourceKey: json['sourceKey'] as String,
        vodId: json['vodId'] as String,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        remarks: json['remarks'] as String?,
        playFlag: json['playFlag'] as String?,
        playIndex: json['playIndex'] as int?,
        showTitle: json['showTitle'] as String?,
        viewAt: json['viewAt'] as int,
        duration: json['duration'] as int?,
        progress: json['progress'] as int?,
      );

  Map<String, dynamic> toMap() => {
    'sourceKey': sourceKey,
    'vodId': vodId,
    'title': title,
    'cover': cover,
    'remarks': remarks,
    'playFlag': playFlag,
    'playIndex': playIndex,
    'showTitle': showTitle,
    'viewAt': viewAt,
    'duration': duration,
    'progress': progress,
  };
}
