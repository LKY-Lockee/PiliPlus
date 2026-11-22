import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

class SearchUgreenItem extends StatelessWidget {
  const SearchUgreenItem({
    super.key,
    required this.cover,
    required this.title,
    this.badge,
    this.subtitle,
    this.meta,
    this.coverWidth = 111,
    this.coverHeight = 148,
    this.onTap,
  });

  final String cover;
  final String title;
  final String? badge;
  final String? subtitle;
  final String? meta;
  final double coverWidth;
  final double coverHeight;
  final VoidCallback? onTap;

  void onLongPress() => showPgcCover(title: title, cover: cover);

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontSize: 13);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  NetworkImgLayer(
                    width: coverWidth,
                    height: coverHeight,
                    src: cover,
                    cacheWidth: false,
                  ),
                  PBadge(
                    text: badge,
                    top: 6.0,
                    right: 6.0,
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
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (!subtitle.isNullOrEmpty)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: style,
                      ),
                    if (!meta.isNullOrEmpty)
                      Text(
                        meta!,
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: style,
                      ),
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
