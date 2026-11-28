import 'dart:async' show StreamSubscription;

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/ugreen/play.dart';
import 'package:PiliPlus/pages/common/slide/common_slide_page.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/controller.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/scroll_offset_helper.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class EpisodeUgreenPanel extends CommonSlidePage {
  const EpisodeUgreenPanel({
    super.key,
    super.enableSlide,
    required this.introController,
  });

  final UgreenIntroController introController;

  @override
  State<EpisodeUgreenPanel> createState() => _EpisodeUgreenPanelState();
}

class _EpisodeUgreenPanelState extends State<EpisodeUgreenPanel>
    with TickerProviderStateMixin, CommonSlideMixin {
  ColorScheme get colorScheme => theme.colorScheme;
  late final _introController = widget.introController;

  static const double _itemExtent = 112;

  final _scrollController = ScrollController();
  late bool _reverse;
  late List<UgreenPlayEpisode> _episodes;
  late int _lastItemIndex;
  late final int Function() _itemIndex;

  StreamSubscription<int>? _indexListener;

  void _addIndexListener() {
    _indexListener = _introController.episodeIndex.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback(_refresh);
    });
  }

  void _removeIndexListener() {
    _indexListener?.cancel();
    _indexListener = null;
  }

  void _refresh([_]) {
    if (!mounted) return;

    final itemIndex = _itemIndex();
    final itemIndexChanged = _lastItemIndex != itemIndex;
    _lastItemIndex = itemIndex;

    _syncEpisodes();

    setState(() {});

    if (itemIndexChanged) {
      _jumpToCurrent();
    }
  }

  void _syncEpisodes() {
    _episodes = _introController.episodes.toList();
  }

  late EdgeInsets padding;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  void initState() {
    super.initState();
    _reverse = false;
    _itemIndex = () => _introController.episodeIndex.value;
    _episodes = _introController.episodes.toList();
    _lastItemIndex = _itemIndex();
    _addIndexListener();
    if (_lastItemIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jumpToIndex(index: _lastItemIndex),
      );
    }
  }

  void _jumpToTop() => _jumpToIndex(top: true);

  void _jumpToBottom() => _jumpToIndex(top: false);

  Future<void> _jumpToCurrent() async {
    final itemIndex = _itemIndex();
    if (itemIndex == -1) return;

    _jumpToIndex(index: itemIndex);
  }

  void _jumpToIndex({int? index, bool? top}) {
    if (!_scrollController.hasClients) {
      if (kDebugMode) assert(false);
      return;
    }

    final episodes = _episodes;
    final isReversed = _reverse;
    final itemIndex = index ?? (top! ^ isReversed ? 0 : episodes.length - 1);

    final (double offset, double remain) = calcFixedItemOffset(
      index: itemIndex,
      itemCount: episodes.length,
      extent: _itemExtent,
      topPadding: isReversed ? padding.bottom + 100 : 7,
      bottomPadding: isReversed ? 7 : padding.bottom + 100,
    );

    final position = _scrollController.position;
    final adjustOffset = adjustScrollOffset(
      extent: _itemExtent,
      offset: offset,
      remain: remain,
      viewportDimension: position.viewportDimension,
      isReversed: isReversed,
    );
    position.jumpTo(adjustOffset);
  }

  @override
  void dispose() {
    _removeIndexListener();
    _scrollController.dispose();
    super.dispose();
  }

  void _pop() {
    _removeIndexListener();
    Get.back();
  }

  @override
  Widget buildPage() {
    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: enableSlide ? slideList() : buildList()),
        ],
      ),
    );
  }

  @override
  Widget buildList() {
    return _buildBody(_episodes);
  }

  Widget _buildBody(List<UgreenPlayEpisode> episodes) {
    Widget child;
    child = SliverVariedExtentList.builder(
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        return _buildEpisodeItem(
          episode: episodes[index],
          index: index,
          isCurrItem: index == _itemIndex(),
        );
      },
      itemExtentBuilder: (index, _) => _itemExtent,
    );

    child = CustomScrollView(
      controller: _scrollController,
      reverse: _reverse,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: 7,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
          ),
          sliver: child,
        ),
      ],
    );

    return child;
  }

  void _onChangeEpisode(
    int index,
  ) {
    _pop();
    _introController.playEpisode(index);
  }

  Widget _buildEpisodeItem({
    required UgreenPlayEpisode episode,
    required int index,
    required bool isCurrItem,
  }) {
    late String title;
    String? cover;
    num? duration;
    String? overview;
    const cacheWidth = false;

    title = episode.title;
    cover = _introController.episodeCoverUrl(episode);
    duration = episode.duration;
    overview = episode.overview;

    late final Color primary = colorScheme.primary;

    void onLongPress() {
      if (cover?.isNotEmpty == true) {
        imageSaveDialog(title: title, cover: cover);
      }
    }

    return Padding(
      padding: const .only(bottom: 2),
      child: SizedBox(
        height: 110,
        child: Material(
          type: .transparency,
          child: InkWell(
            onTap: () {
              if (isCurrItem) return;
              EasyDebounce.debounce(
                'onChangeEpisode',
                const Duration(milliseconds: 200),
                () => _onChangeEpisode(index),
              );
            },
            onLongPress: onLongPress,
            onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
            child: Padding(
              padding: const .symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                spacing: 10,
                children: [
                  if (cover.isNotEmpty)
                    Stack(
                      clipBehavior: .none,
                      children: [
                        NetworkImgLayer(
                          src: cover,
                          width: 160,
                          height: 100,
                          cacheWidth: cacheWidth,
                        ),
                        if (duration != null && duration > 0)
                          PBadge(
                            text: DurationUtils.formatDuration(duration),
                            right: 6.0,
                            bottom: 6.0,
                            type: .gray,
                          ),
                      ],
                    )
                  else if (isCurrItem)
                    Image.asset(
                      Assets.livingStatic,
                      color: primary,
                      height: 12,
                      cacheHeight: 12.cacheSize(context),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .start,
                      children: [
                        Expanded(
                          child: Text(
                            '第$index集 $title',
                            textAlign: .start,
                            style: TextStyle(
                              height: 1.42,
                              letterSpacing: 0.3,
                              fontWeight: isCurrItem ? .bold : null,
                              color: isCurrItem ? primary : null,
                            ),
                            maxLines: 2,
                            overflow: .ellipsis,
                          ),
                        ),
                        if (overview?.isNotEmpty ?? false)
                          Text(
                            overview!,
                            maxLines: 4,
                            overflow: .ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget get _buildUiReverseBtn {
    final reversed = _reverse;
    return iconButton(
      iconSize: 22,
      tooltip: reversed ? '顺序' : '倒序',
      icon: reversed
          ? const Icon(MdiIcons.sortNumericDescending)
          : const Icon(MdiIcons.sortNumericAscending),
      onPressed: () => setState(() => _reverse = !reversed),
    );
  }

  Widget _buildToolbar() => Container(
    height: 45,
    padding: const .symmetric(horizontal: 14),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
    ),
    child: Row(
      children: [
        const Text(
          '剧集',
          style: TextStyle(fontSize: 16),
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至顶部',
          icon: const Icon(Icons.vertical_align_top),
          onPressed: _jumpToTop,
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至底部',
          icon: const Icon(Icons.vertical_align_bottom),
          onPressed: _jumpToBottom,
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至当前',
          icon: const Icon(Icons.my_location),
          onPressed: _jumpToCurrent,
        ),
        const Spacer(),
        _buildUiReverseBtn,
        iconButton(
          iconSize: 22,
          tooltip: '关闭',
          icon: const Icon(Icons.close),
          onPressed: Get.back,
        ),
      ],
    ),
  );
}
