import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/ugreen/related.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 水平布局
class VideoCardH extends StatelessWidget {
  const VideoCardH({
    super.key,
    required this.videoItem,
    required this.cover,
  });
  final UgreenRelatedVideo videoItem;
  final String cover;

  void onLongPress() => imageSaveDialog(
    title: videoItem.name,
    cover: cover,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: .transparency,
      child: Stack(
        clipBehavior: .none,
        children: [
          InkWell(
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            onTap: () => PageUtils.toUgreenPage(
              ugVideoInfoId: videoItem.ugVideoInfoId,
              mediaLibSetId: videoItem.mediaLibSetId,
              type: videoItem.type,
            ),
            child: Padding(
              padding: const .symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final double maxWidth = boxConstraints.maxWidth;
                        final double maxHeight = boxConstraints.maxHeight;
                        return Stack(
                          clipBehavior: .none,
                          children: [
                            NetworkImgLayer(
                              src: cover,
                              width: maxWidth,
                              height: maxHeight,
                              cacheWidth: false,
                            ),
                            if (videoItem.score > 0)
                              PBadge(
                                text: videoItem.typeText,
                                right: 6.0,
                                bottom: 6.0,
                                type: .gray,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget content(ThemeData theme) {
    final meta = [
      if (videoItem.year > 0) '${videoItem.year}',
      if (videoItem.type == 2 && videoItem.localCount > 0)
        '共 ${videoItem.localCount} 集',
    ].join(' · ');
    return Expanded(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Text(
              videoItem.name,
              textAlign: .start,
              style: TextStyle(
                fontSize: theme.textTheme.bodyMedium!.fontSize,
                height: 1.42,
                letterSpacing: 0.3,
              ),
              maxLines: 2,
              overflow: .ellipsis,
            ),
          ),
          Text(
            meta,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: theme.colorScheme.outline,
              overflow: .ellipsis,
            ),
          ),
          const SizedBox(height: 3),
        ],
      ),
    );
  }
}
