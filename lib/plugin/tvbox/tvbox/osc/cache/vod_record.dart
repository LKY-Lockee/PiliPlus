import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:hive_ce/hive.dart';

/// com.github.tvbox.osc.cache.VodRecordDao
class VodRecord {
  static final Box _history = GStorage.vodHistory;
  static final Box<int> _progress = GStorage.vodProgress;

  VodRecord._();

  static String progressKey(
    String sourceKey,
    String vodId,
    String flag,
    int index,
    String name,
  ) => '$sourceKey-$vodId-$flag-$index-$name';

  /// com.github.tvbox.osc.cache.VodRecordDao.getAll
  static List<HistoryVodItemModel> getAll() {
    final list =
        _history.values.map(parse).whereType<HistoryVodItemModel>().toList()
          ..sort((a, b) {
            if (a.viewAt == null && b.viewAt == null) return 0;
            if (a.viewAt == null) return 1;
            if (b.viewAt == null) return -1;
            return b.viewAt!.compareTo(a.viewAt!);
          });
    return list;
  }

  /// com.github.tvbox.osc.cache.VodRecordDao.getVodRecord
  static HistoryVodItemModel? get(String sourceKey, String vodId) =>
      parse(_history.get('tvbox.$sourceKey.$vodId'));

  /// com.github.tvbox.osc.cache.VodRecordDao.insert
  static Future<void> save(HistoryVodItemModel record) async {
    if (Pref.historyPause) {
      return;
    }
    await _history.put(record.vodKey, record.toMap());
  }

  /// com.github.tvbox.osc.cache.VodRecordDao.delete
  static Future<void> delete(List<String> ids) => _history.deleteAll(ids);

  /// com.github.tvbox.osc.cache.VodRecordDao.deleteAll
  static Future<void> clear() => _history.clear();

  static HistoryVodItemModel? parse(dynamic value) {
    if (value is! Map) return null;
    try {
      return HistoryVodItemModel.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.cache.CacheManager.getCache
  static int? getProgress(String key) => _progress.get(key);

  /// com.github.tvbox.osc.cache.CacheManager.save
  static Future<void> saveProgress(String key, int ms) {
    if (Pref.historyPause) {
      return Future.value();
    }
    return _progress.put(key, ms);
  }
}
