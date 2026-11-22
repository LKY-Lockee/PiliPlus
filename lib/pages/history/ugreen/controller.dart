import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_ugreen/data.dart';
import 'package:PiliPlus/models_new/history/history_ugreen/list.dart';
import 'package:PiliPlus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_history.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_media.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryUgreenController
    extends MultiSelectController<HistoryUgreenData, HistoryUgreenItemModel> {
  final service = UgreenService.to;
  late final baseCtr = Get.put(HistoryBaseController());

  @override
  RxInt get rxCount => baseCtr.checkedCount;

  @override
  RxBool get enableMultiSelect => baseCtr.enableMultiSelect;

  Worker? _sessionWorker;
  bool _refreshing = false;
  bool _pendingRefresh = false;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(service.session, (_) {
      if (!isClosed) {
        onRefresh();
      }
    });
    onRefresh();
  }

  @override
  Future<void> onRefresh() async {
    if (_refreshing) {
      _pendingRefresh = true;
      return;
    }
    _refreshing = true;
    try {
      if (!service.isLogin) {
        loadingState.value = const Success(<HistoryUgreenItemModel>[]);
        return;
      }
      final check = await service.checkSession();
      if (check is Error) {
        loadingState.value = Error(check.errMsg);
        return;
      }
      if (check is Success<bool> && !check.response) {
        loadingState.value = const Success(<HistoryUgreenItemModel>[]);
        return;
      }
      await super.onRefresh();
    } finally {
      _refreshing = false;
      if (_pendingRefresh && !isClosed) {
        _pendingRefresh = false;
        onRefresh();
      }
    }
  }

  @override
  Future<LoadingState<HistoryUgreenData>> customGetData() {
    final current = service.session.value;
    if (current == null) {
      return Future.value(const Error('请先登录绿联云'));
    }
    return UgreenHistoryHttp.recentlyPlayed(current, page: page);
  }

  @override
  List<HistoryUgreenItemModel>? getDataList(
    HistoryUgreenData response,
  ) {
    isEnd = response.isLastPage;
    return response.videoArr;
  }

  void deleteItem(HistoryUgreenItemModel item) {
    _deleteItems({item});
  }

  void onDelViewedHistory() {
    final viewed = loadingState.value.dataOrNull?.where((item) {
      return item.playStatus.progress >= 1;
    }).toSet();
    if (viewed == null || viewed.isEmpty) {
      SmartDialog.showToast('无已看记录');
      return;
    }
    _deleteItems(viewed);
  }

  @override
  void onRemove() {
    if (allChecked.isEmpty) {
      return;
    }
    showConfirmDialog(
      context: Get.context!,
      title: const Text('提示'),
      content: const Text('确认删除所选历史记录吗？'),
      onConfirm: () => _deleteItems(allChecked.toSet()),
    );
  }

  Future<LoadingState<void>> clearHistory() async {
    final current = service.session.value;
    if (current == null) {
      return const Error('请先登录绿联云');
    }
    final result = await UgreenHistoryHttp.deleteRecentlyPlayed(
      current,
      delType: 1,
    );
    return result;
  }

  Future<void> _deleteItems(Set<HistoryUgreenItemModel> items) async {
    final ids = items
        .map((item) => item.videoInfo.ugVideoInfoId)
        .whereType<int>()
        .toList();
    if (ids.isEmpty) {
      SmartDialog.showToast('无有效记录');
      return;
    }
    final current = service.session.value;
    if (current == null) {
      SmartDialog.showToast('请先登录绿联云');
      return;
    }
    SmartDialog.showLoading(msg: '请求中');
    final result = await UgreenHistoryHttp.deleteRecentlyPlayed(
      current,
      delType: 2,
      ids: ids,
    );
    SmartDialog.dismiss();
    if (result.isSuccess) {
      afterDelete(items);
      SmartDialog.showToast('已删除');
    } else {
      result.toast();
    }
  }

  String coverUrl({
    String? categoryId,
    String? posterPath,
  }) {
    final current = service.session.value;
    if (current == null) {
      return '';
    }
    return UgreenMediaHttp.coverUrl(
      current,
      categoryId: categoryId,
      posterPath: posterPath,
    );
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }
}
