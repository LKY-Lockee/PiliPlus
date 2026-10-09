import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_record.dart';

/// com.github.tvbox.osc.cache.VodCollect
class FavVodItemModel with MultiSelectData {
  /// com.github.tvbox.osc.cache.VodCollect.sourceKey
  String sourceKey;

  /// com.github.tvbox.osc.cache.VodCollect.vodId
  String vodId;

  /// com.github.tvbox.osc.cache.VodCollect.name
  String? title;

  /// com.github.tvbox.osc.cache.VodCollect.pic
  String? cover;

  String? remarks;
  String? type;

  /// com.github.tvbox.osc.cache.VodCollect.updateTime
  int? updateTime;

  String get vodKey => 'tvbox.$sourceKey.$vodId';

  String? get showTitle => VodRecord.get(sourceKey, vodId)?.showTitle;

  FavVodItemModel({
    required this.sourceKey,
    required this.vodId,
    required this.title,
    this.cover,
    this.remarks,
    this.type,
    this.updateTime,
  });

  factory FavVodItemModel.fromJson(Map<dynamic, dynamic> json) =>
      FavVodItemModel(
        sourceKey: json['sourceKey'] as String,
        vodId: json['vodId'] as String,
        title: json['title'] as String?,
        cover: json['cover'] as String?,
        remarks: json['remarks'] as String?,
        type: json['type'] as String?,
        updateTime: json['updateTime'] as int?,
      );

  Map<String, dynamic> toMap() => {
    'sourceKey': sourceKey,
    'vodId': vodId,
    'title': title,
    'cover': cover,
    'remarks': remarks,
    'type': type,
    'updateTime': updateTime,
  };
}
