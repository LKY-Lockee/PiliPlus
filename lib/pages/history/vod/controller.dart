import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/cache_manager.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_record.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryVodController
    extends
        MultiSelectController<List<HistoryVodItemModel>, HistoryVodItemModel> {
  HistoryVodController();

  late final baseCtr = Get.put(HistoryBaseController());

  @override
  RxInt get rxCount => baseCtr.checkedCount;

  @override
  RxBool get enableMultiSelect => baseCtr.enableMultiSelect;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<HistoryVodItemModel>? getDataList(List<HistoryVodItemModel> response) {
    return response;
  }

  // 删除某条历史记录
  /// com.github.tvbox.osc.cache.RoomDataManger.deleteVodRecord
  void delHistory(HistoryVodItemModel item) {
    _onDelete({item});
  }

  // 删除已看历史记录
  void onDelViewedHistory() {
    final viewedList = loadingState.value.dataOrNull
        ?.where((e) => e.progress == -1)
        .toSet();
    if (viewedList != null && viewedList.isNotEmpty) {
      _onDelete(viewedList);
    } else {
      SmartDialog.showToast('无已看记录');
    }
  }

  Future<void> _onDelete(Set<HistoryVodItemModel> removeList) async {
    SmartDialog.showLoading(msg: '请求中');

    final ids = removeList.map((item) => item.vodKey);
    LoadingState<void> res = await CacheManager.deleteHistory(ids.toList());

    SmartDialog.dismiss();
    if (res.isSuccess) {
      afterDelete(removeList);
      SmartDialog.showToast('已删除');
    } else {
      res.toast();
    }
  }

  // 删除选中的记录
  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      title: const Text('提示'),
      content: const Text('确认删除所选历史记录吗？'),
      onConfirm: () => _onDelete(allChecked.toSet()),
    );
  }

  @override
  Future<LoadingState<List<HistoryVodItemModel>>> customGetData() async {
    isEnd = true;
    return Success(VodRecord.getAll());
  }

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }
}
