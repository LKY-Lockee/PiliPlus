import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/pages/history/vod/controller.dart';
import 'package:PiliPlus/pages/history/vod/widgets/item.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryVodPage extends StatefulWidget {
  const HistoryVodPage({super.key});

  @override
  State<HistoryVodPage> createState() => _HistoryVodPageState();
}

class _HistoryVodPageState extends State<HistoryVodPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final HistoryVodController _historyController =
      Get.find<HistoryVodController>();

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

  Widget _buildBody(LoadingState<List<HistoryVodItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  final item = response[index];
                  return HistoryVodItem(
                    item: item,
                    ctr: _historyController,
                    onDelete: () => _historyController.delHistory(item),
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
