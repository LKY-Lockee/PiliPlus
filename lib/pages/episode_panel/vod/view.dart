import 'dart:math';

import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/marquee.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/pages/common/slide/common_slide_page.dart';
import 'package:PiliPlus/pages/video/introduction/vod/controller.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class EpisodeVodPanel extends CommonSlidePage {
  const EpisodeVodPanel({
    super.key,
    super.enableSlide,
    required this.introController,
    this.showTitle = true,
  });

  final VodIntroController introController;
  final bool showTitle;

  List<VodPlayGroup> get list => introController.playFlags;

  int get initialTabIndex => list.isEmpty
      ? 0
      : introController.flagIndex.value.clamp(
          0,
          list.length - 1,
        );

  @override
  State<EpisodeVodPanel> createState() => _EpisodeVodPanelState();
}

class _EpisodeVodPanelState extends State<EpisodeVodPanel>
    with TickerProviderStateMixin, CommonSlideMixin {
  // tab
  late final TabController _tabController;
  late final RxInt _currentTabIndex = _tabController.index.obs;

  late final showTitle = widget.showTitle;

  List<VodEpisode> get _getCurrEpisodes =>
      widget.list[_currentTabIndex.value].episodes;

  // item
  int get _currentItemIndex => widget.introController.episodeIndex.value;

  late final List<bool> _isReversed;
  late final List<ScrollController> _itemScrollController;

  double? _gridWidth;
  static const double _mainAxisSpacing = 8;
  static const double _crossAxisSpacing = 8;
  static const double _horizontalPadding = 12;
  static const double _maxCrossAxisExtent = 130;
  static const double _childAspectRatio = 2.4;

  void listener() {
    _currentTabIndex.value = _tabController.index;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: widget.initialTabIndex,
      length: widget.list.length,
      vsync: this,
    )..addListener(listener);

    _itemScrollController = List.generate(
      widget.list.length,
      (i) => ScrollController(),
      growable: false,
    );
    _isReversed = List.filled(widget.list.length, false);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    for (final e in _itemScrollController) {
      e.dispose();
    }
    super.dispose();
  }

  late final _isMulti = widget.list.length > 1;

  @override
  Widget buildPage(ThemeData theme) {
    return Material(
      color: showTitle ? theme.colorScheme.surface : null,
      type: showTitle ? MaterialType.canvas : MaterialType.transparency,
      child: Column(
        children: [
          _buildToolbar(theme),
          if (_isMulti)
            TabBar(
              controller: _tabController,
              padding: const EdgeInsets.only(right: 60),
              isScrollable: true,
              tabs: widget.list.map((item) => Tab(text: item.flag)).toList(),
              dividerHeight: 1,
              dividerColor: theme.dividerColor.withValues(alpha: 0.1),
            ),
          Expanded(child: enableSlide ? slideList(theme) : buildList(theme)),
        ],
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme) {
    if (_isMulti) {
      return TabBarView(
        controller: _tabController,
        physics: tabBarScrollPhysics,
        horizontalDragGestureRecognizer: horizontalDragGestureRecognizer,
        children: List.generate(
          widget.list.length,
          (index) => _buildBody(
            theme,
            index,
            widget.list[index].episodes,
          ),
        ),
      );
    }
    return _buildBody(theme, 0, _getCurrEpisodes);
  }

  double _calcItemOffset(int index) {
    final width = _gridWidth;
    if (width == null || width <= 0) {
      return 0;
    }
    final crossAxisExtent = width - _horizontalPadding * 2;
    final crossAxisCount = max(
      1,
      (crossAxisExtent / (_maxCrossAxisExtent + _crossAxisSpacing)).ceil(),
    );
    final usableCrossAxisExtent = max(
      0.0,
      crossAxisExtent - _crossAxisSpacing * (crossAxisCount - 1),
    );
    final childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final childMainAxisExtent = childCrossAxisExtent / _childAspectRatio;
    final mainAxisStride = childMainAxisExtent + _mainAxisSpacing;
    final row = index ~/ crossAxisCount;
    return row * mainAxisStride;
  }

  int _displayIndex(int length) => _isReversed[widget.initialTabIndex]
      ? length - 1 - _currentItemIndex
      : _currentItemIndex;

  Widget _buildBody(
    ThemeData theme,
    int tabIndex,
    List<VodEpisode> episodes,
  ) {
    final isCurrTab = tabIndex == widget.initialTabIndex;
    return KeepAliveWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _gridWidth = constraints.maxWidth;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final controller = _itemScrollController[widget.initialTabIndex];
              if (controller.hasClients) {
                controller.jumpTo(
                  _calcItemOffset(_displayIndex(episodes.length)),
                );
              }
            }
          });
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _itemScrollController[tabIndex],
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  left: _horizontalPadding,
                  top: 12,
                  right: _horizontalPadding,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _maxCrossAxisExtent,
                    mainAxisSpacing: _mainAxisSpacing,
                    crossAxisSpacing: _crossAxisSpacing,
                    childAspectRatio: _childAspectRatio,
                  ),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final dataIndex = _isReversed[tabIndex]
                        ? episodes.length - 1 - index
                        : index;
                    final episode = episodes[dataIndex];
                    final isCurrItem = isCurrTab
                        ? dataIndex == _currentItemIndex
                        : false;
                    return _buildEpisodeItem(
                      theme: theme,
                      episode: episode,
                      index: dataIndex,
                      length: episodes.length,
                      isCurrentIndex: isCurrItem,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEpisodeItem({
    required ThemeData theme,
    required VodEpisode episode,
    required int index,
    required int length,
    required bool isCurrentIndex,
  }) {
    return Material(
      color: isCurrentIndex
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.onInverseSurface,
      borderRadius: const .all(.circular(6)),
      child: InkWell(
        borderRadius: const .all(.circular(6)),
        onTap: () {
          Get.back();
          if (!isCurrentIndex) {
            widget.introController.playEpisode(_currentTabIndex.value, index);
          }
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: MarqueeText(
              episode.name,
              spacing: 16,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrentIndex ? FontWeight.bold : null,
                color: isCurrentIndex
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _animToTopOrBottom({bool top = true}) {
    final tabIndex = _currentTabIndex.value;
    final controller = _itemScrollController[tabIndex];
    final double offset;
    if (top) {
      offset = 0;
    } else if (controller.hasClients) {
      offset = controller.position.maxScrollExtent;
    } else {
      offset = _calcItemOffset(_getCurrEpisodes.length);
    }
    controller.animTo(offset, duration: const Duration(milliseconds: 200));
  }

  Widget _buildToolbar(ThemeData theme) => Container(
    height: 45,
    padding: EdgeInsets.symmetric(horizontal: showTitle ? 14 : 6),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
    ),
    child: Row(
      children: [
        if (showTitle)
          Text(
            '剧集',
            style: theme.textTheme.titleMedium,
          ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至顶部',
          icon: const Icon(Icons.vertical_align_top),
          onPressed: _animToTopOrBottom,
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至底部',
          icon: const Icon(Icons.vertical_align_bottom),
          onPressed: () => _animToTopOrBottom(top: false),
        ),
        iconButton(
          iconSize: 22,
          tooltip: '跳至当前',
          icon: const Icon(Icons.my_location),
          onPressed: () async {
            final currentTabIndex = _currentTabIndex.value;
            if (currentTabIndex != widget.initialTabIndex) {
              _tabController.animateTo(widget.initialTabIndex);
              await Future.delayed(const Duration(milliseconds: 225));
            }
            _itemScrollController[widget.initialTabIndex].animTo(
              _calcItemOffset(
                _displayIndex(
                  widget.list[widget.initialTabIndex].episodes.length,
                ),
              ),
              duration: const Duration(milliseconds: 200),
            );
          },
        ),
        const Spacer(),
        Obx(
          () {
            final currentTabIndex = _currentTabIndex.value;
            return iconButton(
              iconSize: 22,
              tooltip: _isReversed[currentTabIndex] ? '顺序' : '倒序',
              icon: !_isReversed[currentTabIndex]
                  ? const Icon(MdiIcons.sortNumericAscending)
                  : const Icon(MdiIcons.sortNumericDescending),
              onPressed: () => setState(() {
                _isReversed[currentTabIndex] = !_isReversed[currentTabIndex];
              }),
            );
          },
        ),
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
