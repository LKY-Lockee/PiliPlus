import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class HistoryVodItem extends StatelessWidget {
  final HistoryVodItemModel item;
  final MultiSelectBase ctr;
  final void Function() onDelete;

  const HistoryVodItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuration = item.duration != null && item.duration != 0;
    final enableMultiSelect = ctr.enableMultiSelect.value;

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(item);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enableMultiSelect
            ? () => ctr.onSelect(item)
            : () {
                PageUtils.toVodPage(
                  sourceKey: item.sourceKey,
                  vodId: item.vodId,
                  title: item.title,
                  cover: item.cover,
                );
              },
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        double maxWidth = boxConstraints.maxWidth;
                        double maxHeight = boxConstraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: item.cover,
                              width: maxWidth,
                              height: maxHeight,
                            ),
                            if (hasDuration)
                              PBadge(
                                text: item.progress == -1
                                    ? '已看完'
                                    : '${DurationUtils.formatDuration(item.progress)}/${DurationUtils.formatDuration(item.duration)}',
                                right: 6.0,
                                bottom: 8.0,
                                type: PBadgeType.gray,
                              ),
                            if (item.isFav)
                              const PBadge(
                                text: '已收藏',
                                top: 6.0,
                                right: 6.0,
                                type: PBadgeType.gray,
                              )
                            else if (item.remarks?.isNotEmpty == true)
                              PBadge(
                                text: item.remarks,
                                top: 6.0,
                                right: 6.0,
                                type: PBadgeType.primary,
                              ),
                            if (hasDuration &&
                                item.progress != null &&
                                item.progress != 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: VideoProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  progress: item.progress == -1
                                      ? 1
                                      : item.progress! / item.duration!,
                                ),
                              ),
                            Positioned.fill(
                              child: selectMask(
                                theme.colorScheme,
                                item.checked,
                              ),
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
            Positioned(
              right: 12,
              bottom: 0,
              width: 29,
              height: 29,
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                tooltip: '功能菜单',
                icon: Icon(
                  Icons.more_vert_outlined,
                  color: theme.colorScheme.outline,
                  size: 18,
                ),
                position: PopupMenuPosition.under,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: onDelete,
                    height: 38,
                    child: const Row(
                      children: [
                        Icon(Icons.close_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('删除记录', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget content(ThemeData theme) {
    return Expanded(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title!,
            style: TextStyle(
              fontSize: theme.textTheme.bodyMedium!.fontSize,
              height: 1.42,
              letterSpacing: 0.3,
            ),
            maxLines: item.showTitle.isNullOrEmpty ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.showTitle?.isNotEmpty == true)
            Text(
              item.showTitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          Text(
            DateFormatUtils.chatFormat(item.viewAt!, isHistory: true),
            style: TextStyle(
              fontSize: theme.textTheme.labelMedium!.fontSize,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
