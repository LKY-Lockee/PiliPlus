import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_bili/list.dart';
import 'package:PiliPlus/pages/history/bili/controller.dart';
import 'package:PiliPlus/pages/history/bili/widgets/item.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryBiliPage extends StatefulWidget {
  const HistoryBiliPage({super.key, this.type});

  final String? type;

  @override
  State<HistoryBiliPage> createState() => _HistoryBiliPageState();
}

class _HistoryBiliPageState extends State<HistoryBiliPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final HistoryBiliController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = Get.put(
      HistoryBiliController(widget.type),
      tag: widget.type ?? 'all',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return refreshIndicator(
      onRefresh: _historyController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 7,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(_historyController.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<HistoryBiliItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _historyController.onLoadMore();
                  }
                  final item = response[index];
                  return HistoryBiliItem(
                    item: item,
                    ctr: _historyController,
                    onDelete: (kid, business) =>
                        _historyController.delHistory(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _historyController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
