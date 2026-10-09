import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class SearchVodItem extends StatelessWidget {
  const SearchVodItem({
    super.key,
    required this.item,
  });

  final VodVideo item;

  @override
  Widget build(BuildContext context) {
    final sourceName = TVBoxService.to.config?.getSource(item.sourceKey)?.name;
    const TextStyle style = TextStyle(fontSize: 13);
    final meta1 = [
      item.year,
      item.area,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    final meta2 = [
      item.type,
      item.remarks,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => PageUtils.toVodPage(
          sourceKey: item.sourceKey,
          vodId: item.id,
          title: item.title,
          cover: item.cover,
        ),
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: Style.cardSpace,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  NetworkImgLayer(
                    width: 111,
                    height: 148,
                    src: item.cover,
                  ),
                  if (sourceName != null)
                    PBadge(
                      text: sourceName,
                      top: 6.0,
                      right: 4.0,
                      bottom: null,
                      left: null,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (item.score != null && item.score!.isNotEmpty)
                      Text('评分:${item.score}', style: style),
                    if (meta1.isNotEmpty) Text(meta1, style: style),
                    if (meta2.isNotEmpty) Text(meta2, style: style),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
