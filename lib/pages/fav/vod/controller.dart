import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/cache_manager.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class FavVodController
    extends CommonListController<List<FavVodItemModel>, FavVodItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<FavVodItemModel>? getDataList(List<FavVodItemModel> response) {
    return response;
  }

  @override
  Future<LoadingState<List<FavVodItemModel>>> customGetData() async {
    isEnd = true;
    return Success(VodCollect.getAll());
  }

  // 取消点播
  /// com.github.tvbox.osc.cache.RoomDataManger.deleteVodCollect
  Future<void> vodDel(FavVodItemModel item) async {
    LoadingState<String> result = await CacheManager.deleteFav(item.vodKey);

    if (result case Success(:final response)) {
      loadingState
        ..value.data!.remove(item)
        ..refresh();
      SmartDialog.showToast(response);
    } else {
      result.toast();
    }
  }
}
