import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/fav/fav_ugreen/list.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

class FavUgreenItem extends StatelessWidget {
  const FavUgreenItem({
    super.key,
    required this.item,
    required this.cover,
    required this.onDelete,
  });

  final FavUgreenItemModel item;
  final String cover;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: () {
              PageUtils.toUgreenPage(
                ugVideoInfoId: item.videoInfo.ugVideoInfoId,
                mediaLibSetId: item.videoInfo.mediaLibSetId,
                type: item.videoInfo.type,
                initialFilePath: item.playStatus.recentlyPlayedFilePath,
                initialEpisodeId: item.playStatus.ugTelevisionEpisodeId,
                initialEpisode: item.playStatus.episode,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: Style.aspectRatio3x4,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: cover,
                              width: boxConstraints.maxWidth,
                              height: boxConstraints.maxHeight,
                              cacheWidth: false,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            PBadge(
                              right: 4,
                              top: 4,
                              text: item.videoInfo.typeText,
                              size: PBadgeSize.small,
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.videoInfo.name),
                        if (item.videoInfo.localCount > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            "共${item.videoInfo.localCount}集",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (item.playStatus.episode > 0) ...[
                          SizedBox(
                            height: item.videoInfo.localCount > 0 ? 2 : 6,
                          ),
                          Text(
                            "看到第${item.playStatus.episode}集 ${DurationUtils.formatDuration(item.playStatus.currentPlayTime)}",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 0,
            child: SizedBox(
              width: 36,
              height: 36,
              child: PopupMenuButton(
                padding: EdgeInsets.zero,
                tooltip: '功能菜单',
                iconSize: 18,
                iconColor: colorScheme.outline,
                icon: const Icon(Icons.more_vert),
                position: PopupMenuPosition.under,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: onDelete,
                    height: 38,
                    child: const Row(
                      children: [
                        Icon(Icons.close_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('取消收藏', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
