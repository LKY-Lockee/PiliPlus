import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/video/related/bili/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RelatedBiliPanel extends StatefulWidget {
  const RelatedBiliPanel({super.key, required this.heroTag});
  final String heroTag;
  @override
  State<RelatedBiliPanel> createState() => _RelatedBiliPanelState();
}

class _RelatedBiliPanelState extends State<RelatedBiliPanel> with GridMixin {
  late final RelatedBiliController _relatedController;

  @override
  void initState() {
    super.initState();
    _relatedController = Get.putOrFind(
      RelatedBiliController.new,
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 7, bottom: 100),
      sliver: Obx(() => _buildBody(_relatedController.loadingState.value)),
    );
  }

  Widget _buildBody(LoadingState<List<HotVideoItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  return VideoCardH(
                    videoItem: response[index],
                    onRemove: () => _relatedController.loadingState
                      ..value.data!.removeAt(index)
                      ..refresh(),
                  );
                },
                itemCount: response.length,
              )
            : const SliverToBoxAdapter(),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _relatedController.onReload,
      ),
    };
  }
}
