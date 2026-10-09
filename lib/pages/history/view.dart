import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/pages/common/multi_select/multi_select_controller.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/pages/history/bili/controller.dart';
import 'package:PiliPlus/pages/history/bili/view.dart';
import 'package:PiliPlus/pages/history/vod/controller.dart';
import 'package:PiliPlus/pages/history/vod/view.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/cache_manager.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  final HistoryBaseController _baseController = Get.put(
    HistoryBaseController(),
  );
  HistoryBiliController? _biliController;
  final HistoryVodController _vodController = Get.put(HistoryVodController());

  Worker? _tabsWorker;
  late TabController _tabController;

  bool get _isLogin => _baseController.account.isLogin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isLogin ? 2 : 1, vsync: this);
    if (_isLogin) {
      _biliController = Get.put(HistoryBiliController(null), tag: 'all');
      _tabsWorker = ever(
        _biliController!.tabs,
        (tabs) => () {
          _tabController.dispose();
          _tabController = TabController(length: tabs.length + 2, vsync: this);
        }(),
      );
      _baseController.historyStatus();
    }
  }

  MultiSelectController currCtr([int? index]) {
    index ??= _tabController.index;
    if (!_isLogin || index == _biliController!.tabs.length + 1) {
      return _vodController;
    }
    if (index == 0) {
      return _biliController!;
    }
    return Get.find<HistoryBiliController>(
      tag: _biliController!.tabs[index - 1].type,
    );
  }

  @override
  void dispose() {
    _tabsWorker?.dispose();
    _tabController.dispose();
    Get.delete<HistoryBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Obx(() {
      final enableMultiSelect = _baseController.enableMultiSelect.value;
      return popScope(
        canPop: !enableMultiSelect,
        onPopInvokedWithResult: (didPop, result) {
          if (enableMultiSelect) {
            currCtr().handleSelect();
          }
        },
        child: SimpleScaffold(
          appBar: MultiSelectAppBarWidget(
            visible: enableMultiSelect,
            ctr: currCtr(),
            child: _buildAppBar,
          ),
          body: Padding(
            padding: .only(left: padding.left, right: padding.right),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?_buildPauseTip,
                TabBar(
                  controller: _tabController,
                  onTap: (index) {
                    if (!_tabController.indexIsChanging) {
                      switch (currCtr(index)) {
                        case HistoryBiliController ctr:
                          ctr.scrollController.animToTop();
                        case HistoryVodController ctr:
                          ctr.scrollController.animToTop();
                      }
                    } else if (enableMultiSelect) {
                      currCtr(_tabController.previousIndex).handleSelect();
                    }
                  },
                  tabs: [
                    if (_isLogin) ...[
                      const Tab(text: '全部'),
                      ..._biliController!.tabs.map(
                        (item) => Tab(text: item.name),
                      ),
                    ],
                    const Tab(text: '点播'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: enableMultiSelect
                        ? const NeverScrollableScrollPhysics()
                        : tabBarScrollPhysics,
                    controller: _tabController,
                    horizontalDragGestureRecognizer:
                        CustomHorizontalDragGestureRecognizer.new,
                    children: [
                      if (_isLogin) ...[
                        const HistoryBiliPage(),
                        ..._biliController!.tabs.map(
                          (item) => HistoryBiliPage(type: item.type),
                        ),
                      ],
                      const HistoryVodPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  AppBar get _buildAppBar => AppBar(
    title: const Text('观看记录'),
    actions: [
      IconButton(
        tooltip: '搜索',
        onPressed: () => Get.toNamed('/historySearch'),
        icon: const Icon(Icons.search_outlined),
      ),
      PopupMenuButton(
        itemBuilder: (_) => [
          PopupMenuItem(
            onTap: () => _baseController.onPauseHistory(context),
            child: Text(
              !_baseController.pauseStatus.value ? '暂停观看记录' : '恢复观看记录',
            ),
          ),
          PopupMenuItem(
            onTap: () {
              _baseController.onClearHistory(
                context,
                (account) => switch (currCtr()) {
                  HistoryBiliController() => UserHttp.clearHistory(
                    account: account,
                  ),
                  HistoryVodController() => CacheManager.clearHistory(),
                  _ => throw UnimplementedError(),
                },
                () {
                  switch (currCtr()) {
                    case HistoryBiliController():
                      _biliController!.loadingState.value = const Success(null);
                      for (final item in _biliController!.tabs) {
                        if (Get.isRegistered<HistoryBiliController>(
                          tag: item.type,
                        )) {
                          Get.find<HistoryBiliController>(
                            tag: item.type,
                          ).loadingState.value = const Success(
                            null,
                          );
                        }
                      }
                      break;
                    case HistoryVodController ctr:
                      ctr.loadingState.value = const Success(null);
                      break;
                    default:
                      throw UnimplementedError();
                  }
                },
              );
            },
            child: const Text('清空观看记录'),
          ),
          PopupMenuItem(
            onTap: () => switch (currCtr()) {
              HistoryBiliController ctr => ctr.onDelViewedHistory(),
              HistoryVodController ctr => ctr.onDelViewedHistory(),
              _ => throw UnimplementedError(),
            },
            child: const Text('删除已看记录'),
          ),
        ],
      ),
      const SizedBox(width: 6),
    ],
  );

  PreferredSizeWidget? get _buildPauseTip {
    if (_baseController.pauseStatus.value) {
      final theme = Theme.of(context).colorScheme;
      return PreferredSize(
        preferredSize: const Size.fromHeight(38),
        child: Container(
          height: 38,
          color: theme.secondaryContainer.withValues(alpha: 0.8),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  strutStyle: const StrutStyle(height: 1, leading: 0),
                  style: TextStyle(
                    height: 1,
                    color: theme.onSecondaryContainer,
                  ),
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                      const TextSpan(text: ' 历史记录功能已关闭'),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _baseController.onPauseHistory(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    '点击开启',
                    strutStyle: const StrutStyle(height: 1, leading: 0),
                    style: TextStyle(height: 1, color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }
}
