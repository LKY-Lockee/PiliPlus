import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

class FavVodItem extends StatelessWidget {
  const FavVodItem({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final FavVodItemModel item;
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
              PageUtils.toVodPage(
                sourceKey: item.sourceKey,
                vodId: item.vodId,
                title: item.title,
                cover: item.cover,
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
                    aspectRatio: 3 / 4,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: item.cover,
                              width: boxConstraints.maxWidth,
                              height: boxConstraints.maxHeight,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            PBadge(
                              right: 4,
                              top: 4,
                              text: item.type,
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
                        Text(item.title!),
                        if (item.remarks != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.remarks!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (item.showTitle != null) ...[
                          SizedBox(
                            height: item.remarks != null ? 2 : 6,
                          ),
                          Text(
                            "看到${item.showTitle}",
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
            width: 29,
            height: 29,
            child: PopupMenuButton(
              padding: EdgeInsets.zero,
              tooltip: '功能菜单',
              icon: Icon(
                Icons.more_vert_outlined,
                color: colorScheme.outline,
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
                      Text('取消点播', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
