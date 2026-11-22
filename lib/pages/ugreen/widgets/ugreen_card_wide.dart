import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 三卡布局
class UgreenCardWide extends StatelessWidget {
  const UgreenCardWide({
    super.key,
    required this.title,
    required this.covers,
    required this.subtitle,
  });

  final String title;
  final List<String> covers;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final visibleCovers = covers
        .where((cover) => cover.isNotEmpty)
        .take(3)
        .toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        borderRadius: Style.mdRadius,
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: Style.aspectRatio16x9,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double maxWidth = boxConstraints.maxWidth;
                  final double maxHeight = boxConstraints.maxHeight;
                  if (visibleCovers.isEmpty) {
                    return NetworkImgLayer(
                      src: '',
                      width: maxWidth,
                      height: maxHeight,
                      borderRadius: BorderRadius.zero,
                    );
                  }
                  final double itemWidth = maxWidth / visibleCovers.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final cover in visibleCovers)
                        Expanded(
                          child: NetworkImgLayer(
                            src: cover,
                            width: itemWidth,
                            height: maxHeight,
                            cacheWidth: false,
                            borderRadius: BorderRadius.zero,
                          ),
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
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}
