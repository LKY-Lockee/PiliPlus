import 'package:PiliPlus/models_new/history/history_bili/list.dart';
import 'package:PiliPlus/models_new/history/tab.dart';

class HistoryData {
  List<HistoryTab>? tab;
  List<HistoryBiliItemModel>? list;

  HistoryData({this.tab, this.list});

  factory HistoryData.fromJson(Map<String, dynamic> json) => HistoryData(
    tab: (json['tab'] as List<dynamic>?)
        ?.map((e) => HistoryTab.fromJson(e as Map<String, dynamic>))
        .toList(),
    list: (json['list'] as List<dynamic>?)
        ?.map((e) => HistoryBiliItemModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
