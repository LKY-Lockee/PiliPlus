import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/select_mask.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/history/history_ugreen/list.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class HistoryUgreenItem extends StatelessWidget {
  final HistoryUgreenItemModel item;
  final String cover;
  final MultiSelectBase ctr;
  final void Function() onDelete;

  const HistoryUgreenItem({
    super.key,
    required this.item,
    required this.cover,
    required this.ctr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuration = item.videoInfo.duration > 0;
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
                PageUtils.toUgreenPage(
                  ugVideoInfoId: item.videoInfo.ugVideoInfoId,
                  mediaLibSetId: item.videoInfo.mediaLibSetId,
                  type: item.videoInfo.type,
                  initialFilePath: item.playStatus.recentlyPlayedFilePath,
                  initialEpisodeId: item.playStatus.ugTelevisionEpisodeId,
                  initialEpisode: item.playStatus.episode,
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
                              src: cover,
                              width: maxWidth,
                              height: maxHeight,
                            ),
                            if (hasDuration)
                              PBadge(
                                text: item.playStatus.watchStatus == 2
                                    ? '已看完'
                                    : '${DurationUtils.formatDuration(item.playStatus.currentPlayTime)}/${DurationUtils.formatDuration(item.videoInfo.duration)}',
                                bottom: 8.0,
                                left: 6.0,
                                right: 6.0,
                                alignment: .right,
                                type: PBadgeType.gray,
                              ),
                            if (item.isFavorite)
                              const PBadge(
                                text: '已收藏',
                                top: 6.0,
                                left: 6.0,
                                right: 6.0,
                                alignment: .right,
                                type: PBadgeType.gray,
                              )
                            else if (item.videoInfo.score > 0)
                              PBadge(
                                text:
                                    '${item.videoInfo.score.toStringAsFixed(1)} 分',
                                top: 6.0,
                                left: 6.0,
                                right: 6.0,
                                alignment: .right,
                                type: PBadgeType.primary,
                              ),
                            if (item.playStatus.progress > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: VideoProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  progress: item.playStatus.progress
                                      .clamp(0, 1)
                                      .toDouble(),
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
            item.videoInfo.name,
            style: TextStyle(
              fontSize: theme.textTheme.bodyMedium!.fontSize,
              height: 1.42,
              letterSpacing: 0.3,
            ),
            maxLines: item.playStatus.tvName.isEmpty ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "第${item.playStatus.episode}集 ${item.playStatus.tvName}",
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          if (item.videoInfo.localCount > 0)
            Text(
              "共${item.videoInfo.localCount}集",
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
