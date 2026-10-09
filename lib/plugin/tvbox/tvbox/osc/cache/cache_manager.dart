import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_record.dart';

/// com.github.tvbox.osc.cache.CacheManager
class CacheManager {
  CacheManager._();

  static Future<LoadingState<void>> deleteHistory(List<String> ids) async {
    try {
      await VodRecord.delete(ids);
      return const Success(null);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState<void>> clearHistory() async {
    try {
      await VodRecord.clear();
      return const Success(null);
    } catch (e) {
      return Error(e.toString());
    }
  }

  static Future<LoadingState<String>> deleteFav(String ids) async {
    await VodCollect.delete(ids);
    return const Success('已取消点播');
  }
}
