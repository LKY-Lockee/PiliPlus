import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_ugreen/data.dart';
import 'package:PiliPlus/models_new/fav/fav_ugreen/list.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_fav.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_media.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FavUgreenController
    extends CommonListController<FavUgreenData, FavUgreenItemModel> {
  final service = UgreenService.to;

  static const pageSize = 100;

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
        loadingState.value = const Success(<FavUgreenItemModel>[]);
        return;
      }
      final check = await service.checkSession();
      if (check is Error) {
        loadingState.value = Error(check.errMsg);
        return;
      }
      if (check is Success<bool> && !check.response) {
        loadingState.value = const Success(<FavUgreenItemModel>[]);
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
  Future<LoadingState<FavUgreenData>> customGetData() {
    final current = service.session.value;
    if (current == null) {
      return Future.value(const Error('请先登录绿联云'));
    }
    return UgreenFavHttp.favoriteVideos(
      current,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  List<FavUgreenItemModel>? getDataList(FavUgreenData response) {
    final loaded = (page - 1) * pageSize + response.videoArr.length;
    isEnd = response.videoArr.isEmpty || loaded >= response.totalNum;
    return response.videoArr;
  }

  Future<void> removeFavorite(FavUgreenItemModel item) async {
    final current = service.session.value;
    if (current == null) {
      SmartDialog.showToast('请先登录绿联云');
      return;
    }
    final result = await UgreenFavHttp.deleteFavorite(
      current,
      categoryId: item.videoInfo.categoryId,
      mediaLibSetId: item.videoInfo.mediaLibSetId,
      type: item.videoInfo.type,
    );
    if (result.isSuccess) {
      final data = loadingState.value.dataOrNull;
      if (data != null) {
        data.remove(item);
        loadingState.refresh();
      }
      SmartDialog.showToast('已取消收藏');
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
