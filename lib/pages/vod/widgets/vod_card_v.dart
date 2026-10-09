import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class VodCardV extends StatelessWidget {
  const VodCardV({
    super.key,
    required this.item,
    this.onTap,
    this.coverHeaders,
  });

  final VodVideo item;
  final VoidCallback? onTap;
  final Map<String, String>? coverHeaders;

  @override
  Widget build(BuildContext context) {
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        borderRadius: Style.mdRadius,
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        onTap:
            onTap ??
            () => PageUtils.toVodPage(
              sourceKey: item.sourceKey,
              vodId: item.id,
              title: item.title,
              cover: item.cover,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double maxWidth = boxConstraints.maxWidth;
                  final double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: item.cover,
                        width: maxWidth,
                        height: maxHeight,
                        httpHeaders: coverHeaders,
                      ),
                      PBadge(
                        text: item.remarks,
                        top: 6,
                        right: 6,
                        bottom: null,
                        left: null,
                      ),
                    ],
                  );
                },
              ),
            ),
            content(context),
          ],
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            if (item.type != null)
              Text(
                item.type!,
                maxLines: 1,
                style: style,
              ),
          ],
        ),
      ),
    );
  }
}
