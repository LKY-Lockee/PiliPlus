import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:hive_ce/hive.dart';

/// com.github.tvbox.osc.cache.VodCollectDao
class VodCollect {
  static final Box _fav = GStorage.vodFav;

  VodCollect._();

  /// com.github.tvbox.osc.cache.VodCollectDao.getAll
  static List<FavVodItemModel> getAll() {
    final list = _fav.values.map(parse).whereType<FavVodItemModel>().toList()
      ..sort(
        (a, b) => (b.updateTime ?? 0).compareTo(a.updateTime ?? 0),
      );
    return list;
  }

  static FavVodItemModel? parse(dynamic value) {
    if (value is! Map) return null;
    try {
      return FavVodItemModel.fromJson(value);
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.cache.VodCollectDao.getVodCollect
  static bool isFav(String sourceKey, String vodId) =>
      _fav.containsKey('tvbox.$sourceKey.$vodId');

  /// com.github.tvbox.osc.cache.VodCollectDao.insert
  static Future<void> toggle(
    String sourceKey,
    String vodId,
    String title,
    String? cover,
    String? remarks,
    String? type,
  ) async {
    final id = 'tvbox.$sourceKey.$vodId';
    if (_fav.containsKey(id)) {
      await _fav.delete(id);
    } else {
      final item = FavVodItemModel(
        sourceKey: sourceKey,
        vodId: vodId,
        title: title,
        cover: cover,
        remarks: remarks,
        type: type,
        updateTime: DateTime.now().millisecondsSinceEpoch,
      );
      await _fav.put(item.vodKey, item.toMap());
    }
  }

  /// com.github.tvbox.osc.cache.VodCollectDao.delete
  static Future<void> delete(String ids) => _fav.delete(ids);
}
