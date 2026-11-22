import 'dart:math';

import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/controller.dart';
import 'package:material_ui/material_ui.dart';

class SeasonPanel extends StatelessWidget {
  const SeasonPanel({
    super.key,
    required this.ugreenController,
  });

  final UgreenIntroController ugreenController;

  @override
  Widget build(BuildContext context) {
    final seasons = ugreenController.seasons;
    final currIndex = max(0, ugreenController.currentSeasonIndex);
    final controller = ugreenController.seasonController(currIndex);
    final colorScheme = ColorScheme.of(context);
    return SizedBox(
      height: 35,
      child: ListView.builder(
        padding: .zero,
        itemExtent: 150,
        controller: controller,
        itemCount: seasons.length,
        scrollDirection: .horizontal,
        key: const PageStorageKey(SeasonPanel),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = seasons[index];
          final isCurr = index == currIndex;
          return Container(
            width: 150,
            margin: index != seasons.length - 1 ? const .only(right: 10) : null,
            child: Material(
              color: colorScheme.onInverseSurface,
              borderRadius: const .all(.circular(6)),
              child: InkWell(
                borderRadius: const .all(.circular(6)),
                onTap: () {
                  if (isCurr || ugreenController.changingSeason) return;
                  ugreenController.changeSeason(index);
                },
                child: Padding(
                  padding: const .symmetric(horizontal: 8),
                  child: Align(
                    alignment: .centerLeft,
                    child: MarqueeText(
                      item.name,
                      spacing: 16,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCurr
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      strutStyle: const .new(height: 1, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
