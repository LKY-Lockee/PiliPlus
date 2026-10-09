import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/image_viewer/hero.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/models/common/image_preview_type.dart';
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliPlus/pages/video/introduction/vod/controller.dart';
import 'package:PiliPlus/pages/video/introduction/vod/widgets/vod_panel.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodIntroPage extends StatefulWidget {
  final String heroTag;
  final bool isLandscape;

  const VodIntroPage({
    super.key,
    required this.heroTag,
    required this.isLandscape,
  });

  @override
  State<VodIntroPage> createState() => _VodIntroPageState();
}

class _VodIntroPageState extends State<VodIntroPage> {
  late final VodIntroController introController;

  @override
  void initState() {
    super.initState();
    introController = Get.putOrFind(
      VodIntroController.new,
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isLandscape = widget.isLandscape;
    Widget sliver = SliverToBoxAdapter(
      child: Obx(
        () {
          final item = introController.detail.value;
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
                      item.video,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              actionGrid(item),
              if (item.playFlags.isNotEmpty)
                VodPanel(introController: introController),
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

  Widget _buildCover(VodInfoModel item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (!item.video.cover.isNullOrEmpty) {
              PageUtils.imageView(
                imgList: [SourceModel(url: item.video.cover!)],
              );
            }
          },
          child: fromHero(
            tag: item.video.cover!,
            child: NetworkImgLayer(
              width: 115,
              height: 153,
              src: item.video.cover!,
            ),
          ),
        ),
        if (item.video.score != null)
          PBadge(
            text: '评分 ${item.video.score}',
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
    VodVideo item,
  ) {
    Widget title() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        Expanded(
          child: Text(
            item.title,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    List<Widget> desc() => [
      if (item.remarks?.isNotEmpty == true)
        Text(
          item.remarks!,
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      Text(
        [
          item.area,
          item.year,
        ].whereType<String>().where((e) => e.isNotEmpty).join(' '),
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
                '简介：${item.description ?? '暂无'}',
                style: TextStyle(fontSize: 13, color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionGrid(VodInfoModel item) {
    final info = item.video;
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionItem(
            icon: const Icon(FontAwesomeIcons.arrowRightArrowLeft),
            onTap: introController.onChangeSource,
            selectStatus: false,
            semanticsLabel: '换源',
            text: '换源',
          ),
          ActionItem(
            icon: const Icon(FontAwesomeIcons.wandMagicSparkles),
            onTap: introController.onChangeParse,
            selectStatus: false,
            semanticsLabel: '更换解析',
            text: '更换解析',
          ),
          Obx(
            () => ActionItem(
              icon: const Icon(FontAwesomeIcons.star),
              selectIcon: const Icon(FontAwesomeIcons.solidStar),
              onTap: introController.toggleFav,
              selectStatus: introController.isFav.value,
              semanticsLabel: '收藏',
              text: introController.isFav.value ? '已收藏' : '收藏',
            ),
          ),
          ActionItem(
            icon: const Icon(FontAwesomeIcons.copy),
            onTap: () {
              Utils.copyText(info.title);
              SmartDialog.showToast('已复制');
            },
            selectStatus: false,
            semanticsLabel: '复制片名',
            text: '复制片名',
          ),
          ActionItem(
            icon: const Icon(FontAwesomeIcons.link),
            onTap: () {
              final videoUrl = introController.videoDetailCtr.videoUrl;
              if (videoUrl == null || videoUrl.isEmpty) {
                SmartDialog.showToast('暂无播放地址');
                return;
              }
              Utils.copyText(videoUrl);
              SmartDialog.showToast('已复制');
            },
            selectStatus: false,
            semanticsLabel: '复制播放链接',
            text: '复制播放链接',
          ),
        ],
      ),
    );
  }
}
