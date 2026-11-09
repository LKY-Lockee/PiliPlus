import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/all.dart';
import 'package:PiliPlus/models_new/ugreen/folder.dart';
import 'package:PiliPlus/models_new/ugreen/home.dart';
import 'package:PiliPlus/models_new/ugreen/media_lib.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_home.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_media.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class UgreenController extends GetxController with ScrollOrRefreshMixin {
  final service = UgreenService.to;

  @override
  final ScrollController scrollController = ScrollController();

  final Rx<LoadingState<UgreenHomeData>> homeState =
      LoadingState<UgreenHomeData>.loading().obs;
  final Rx<LoadingState<UgreenFolderData>> folderState =
      LoadingState<UgreenFolderData>.loading().obs;
  final Rx<LoadingState<UgreenMediaLibData>> mediaLibState =
      LoadingState<UgreenMediaLibData>.loading().obs;
  final Rx<LoadingState<UgreenAllData>> movieState =
      LoadingState<UgreenAllData>.loading().obs;
  final Rx<LoadingState<UgreenAllData>> tvState =
      LoadingState<UgreenAllData>.loading().obs;
  final Rx<LoadingState<UgreenAllData>> otherState =
      LoadingState<UgreenAllData>.loading().obs;

  Worker? _sessionWorker;
  Worker? _historyWorker;
  Worker? _favoriteWorker;
  bool _refreshing = false;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(service.session, (_) {
      if (!isClosed) {
        onRefresh();
      }
    });
    _historyWorker = ever(service.historyRevision, (_) {
      if (!isClosed) {
        onRefresh();
      }
    });
    _favoriteWorker = ever(service.favoriteRevision, (_) {
      if (!isClosed) {
        onRefresh();
      }
    });
    onRefresh();
  }

  @override
  Future<void> onRefresh() async {
    if (_refreshing) {
      return;
    }
    _refreshing = true;
    try {
      homeState.value = LoadingState.loading();
      folderState.value = LoadingState.loading();
      mediaLibState.value = LoadingState.loading();
      movieState.value = LoadingState.loading();
      tvState.value = LoadingState.loading();
      otherState.value = LoadingState.loading();
      try {
        if (service.isLogin) {
          await service.checkSession();
        }
        final current = service.session.value;
        if (current == null) {
          const error = Error('请先登录绿联云');
          homeState.value = error;
          folderState.value = error;
          mediaLibState.value = error;
          movieState.value = error;
          tvState.value = error;
          otherState.value = error;
          return;
        }
        final homeFuture = UgreenHomeHttp.homepage(current);
        final folderFuture = UgreenMediaHttp.folders(current);
        final mediaLibFuture = UgreenMediaHttp.mediaLibraries(current);
        final movieFuture = UgreenMediaHttp.allVideos(
          current,
          classification: -102,
        );
        final tvFuture = UgreenMediaHttp.allVideos(
          current,
          classification: -103,
        );
        final otherFuture = UgreenMediaHttp.allVideos(
          current,
          classification: -104,
        );
        await Future.wait([
          _apply(homeState, homeFuture),
          _apply(folderState, folderFuture),
          _apply(mediaLibState, mediaLibFuture),
          _apply(movieState, movieFuture),
          _apply(tvState, tvFuture),
          _apply(otherState, otherFuture),
        ]);
      } catch (e) {
        final error = Error('加载失败: $e');
        homeState.value = error;
        folderState.value = error;
        mediaLibState.value = error;
        movieState.value = error;
        tvState.value = error;
        otherState.value = error;
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _apply<T>(
    Rx<LoadingState<T>> state,
    Future<LoadingState<T>> future,
  ) async {
    final result = await future;
    if (!isClosed) {
      state.value = result;
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
    _historyWorker?.dispose();
    _favoriteWorker?.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
