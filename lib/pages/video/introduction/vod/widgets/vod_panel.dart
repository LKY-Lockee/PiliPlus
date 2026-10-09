import 'dart:async';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/pages/video/introduction/vod/controller.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:material_ui/material_ui.dart';

class VodPanel extends StatefulWidget {
  const VodPanel({
    super.key,
    required this.introController,
  });

  final VodIntroController introController;

  @override
  State<VodPanel> createState() => _VodPanelState();
}

class _VodPanelState extends State<VodPanel> {
  late int currentIndex;
  late final ScrollController listViewScrollCtr;

  late final VodIntroController introController;
  late final StreamSubscription<int> _listener;

  @override
  void initState() {
    super.initState();
    introController = widget.introController;
    currentIndex = introController.episodeIndex.value;
    listViewScrollCtr = ScrollController(
      initialScrollOffset: currentIndex * 150.0,
    );

    _listener = introController.episodeIndex.listen((int p0) {
      currentIndex = p0;
      if (!mounted) return;
      setState(() {});
      scrollToIndex();
    });
  }

  @override
  void dispose() {
    _listener.cancel();
    listViewScrollCtr.dispose();
    super.dispose();
  }

  void scrollToIndex() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listViewScrollCtr.animateTo(
        currentIndex * 150.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final currEpisode = introController.currentEpisode;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('合集 '),
              Expanded(
                child: Text(
                  ' 正在播放：${currEpisode?.name ?? '未播放'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.outline),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: TextButton(
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  ),
                  onPressed: introController.showEpisodePanel,
                  child: const Text(
                    '查看全部',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            key: const PageStorageKey(_VodPanelState),
            padding: EdgeInsets.zero,
            controller: listViewScrollCtr,
            scrollDirection: Axis.horizontal,
            itemCount: introController.episodes.length,
            itemExtent: 150,
            itemBuilder: (BuildContext context, int index) =>
                _buildItem(theme, index),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(ColorScheme theme, int index) {
    final item = introController.episodes[index];
    final color = index == currentIndex ? theme.primary : theme.onSurface;
    return Container(
      width: 150,
      height: 60,
      margin: index != introController.episodes.length - 1
          ? const EdgeInsets.only(right: 10)
          : null,
      child: Material(
        color: theme.onInverseSurface,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          onTap: () => introController.playEpisode(
            introController.flagIndex.value,
            index,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              spacing: 3,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        maxLines: 1,
                        TextSpan(
                          children: [
                            if (index == currentIndex)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Image.asset(
                                    Assets.livingStatic,
                                    color: theme.primary,
                                    height: 12,
                                    cacheHeight: 12.cacheSize(context),
                                    semanticLabel: "正在播放：",
                                  ),
                                ),
                              ),
                            TextSpan(
                              text: '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                MarqueeText(
                  item.name,
                  spacing: 16,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
