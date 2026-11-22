import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/image_viewer/hero.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/models/common/image_preview_type.dart';
import 'package:PiliPlus/models_new/ugreen/detail.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/widgets/season.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/widgets/ugreen_panel.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenIntroPage extends StatefulWidget {
  final String heroTag;
  final bool isLandscape;

  const UgreenIntroPage({
    super.key,
    required this.heroTag,
    required this.isLandscape,
  });

  @override
  State<UgreenIntroPage> createState() => _UgreenIntroPageState();
}

class _UgreenIntroPageState extends State<UgreenIntroPage> {
  late final UgreenIntroController introController;

  @override
  void initState() {
    super.initState();
    introController = Get.putOrFind(
      UgreenIntroController.new,
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isLandscape = widget.isLandscape;
    final sliver = SliverToBoxAdapter(
      child: Obx(
        () {
          final item = introController.video.value;
          if (item == null) {
            if (introController.isDetailLoading.value) {
              return const Padding(
                padding: .symmetric(vertical: 40),
                child: m3eLoading,
              );
            }
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  _buildCover(item),
                  Expanded(
                    child: _buildInfoPanel(
                      isLandscape,
                      colorScheme,
                      item,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (introController.seasons.length > 1) ...[
                const SizedBox(height: 5),
                UgreenSeasonPanel(ugreenController: introController),
              ],
              if (introController.episodes.isNotEmpty)
                UgreenPanel(introController: introController),
            ],
          );
        },
      ),
    );
    return SliverPadding(
      padding: const .fromLTRB(
        Style.safeSpace,
        Style.safeSpace,
        Style.safeSpace,
        Style.safeSpace + 50,
      ),
      sliver: sliver,
    );
  }

  Widget _buildCover(UgreenVideoSummary video) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (introController.coverUrl.isNotEmpty) {
              PageUtils.imageView(
                imgList: [SourceModel(url: introController.coverUrl)],
              );
            }
          },
          child: fromHero(
            tag: introController.coverUrl,
            child: NetworkImgLayer(
              width: 115,
              height: 153,
              src: introController.coverUrl,
              cacheWidth: false,
            ),
          ),
        ),
        if (video.score > 0)
          PBadge(
            text: '评分 ${video.score.toStringAsFixed(1)}',
            top: null,
            right: 6,
            bottom: 6,
            left: null,
          ),
      ],
    );
  }

  Widget _buildInfoPanel(
    bool isLandscape,
    ColorScheme colorScheme,
    UgreenVideoSummary item,
  ) {
    Widget title() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    List<Widget> desc() => [
      if (item.year > 0)
        Text(
          '${item.year}',
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
    ];
    Widget stat() => Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (isLandscape) ...desc(),
      ],
    );
    return GestureDetector(
      onTap: introController.showIntroDetail,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 153,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title(),
            stat(),
            const SizedBox(height: 5),
            if (!isLandscape) ...desc(),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                '简介：${item.introduction.isEmpty ? '暂无' : item.introduction}',
                style: TextStyle(fontSize: 13, color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
