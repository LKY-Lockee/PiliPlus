import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/related.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/controller.dart';
import 'package:PiliPlus/pages/video/related/ugreen/controller.dart';
import 'package:PiliPlus/pages/video/related/ugreen/widgets/video_card_h.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class RelatedUgreenPanel extends StatefulWidget {
  const RelatedUgreenPanel({super.key, required this.heroTag});
  final String heroTag;
  @override
  State<RelatedUgreenPanel> createState() => _RelatedUgreenPanelState();
}

class _RelatedUgreenPanelState extends State<RelatedUgreenPanel>
    with GridMixin {
  late final RelatedUgreenController _relatedController;

  @override
  void initState() {
    super.initState();
    _relatedController = Get.putOrFind(
      RelatedUgreenController.new,
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

  Widget _buildBody(LoadingState<List<UgreenRelatedVideo>?> loadingState) {
    final introController = Get.find<UgreenIntroController>(
      tag: widget.heroTag,
    );
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  final item = response[index];
                  return VideoCardH(
                    videoItem: item,
                    cover: introController.relatedCoverUrl(item),
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
