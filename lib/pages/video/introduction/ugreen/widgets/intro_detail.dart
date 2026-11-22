import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/selection_text.dart';
import 'package:PiliPlus/models_new/ugreen/detail.dart';
import 'package:PiliPlus/pages/common/slide/common_slide_page.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenIntroPanel extends CommonSlidePage {
  final UgreenVideoSummary item;

  const UgreenIntroPanel({
    super.key,
    required this.item,
  });

  @override
  State<UgreenIntroPanel> createState() => _UgreenIntroDetailState();
}

class _UgreenIntroDetailState extends State<UgreenIntroPanel>
    with TickerProviderStateMixin, CommonSlideMixin {
  late final ScrollController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  dividerHeight: 0,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '详情'),
                  ],
                  onTap: (index) {
                    if (!_tabController.indexIsChanging) {
                      if (index == 0) {
                        _controller.animToTop();
                      }
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: '关闭',
                icon: const Icon(Icons.close, size: 20),
                onPressed: Get.back,
              ),
              const SizedBox(width: 2),
            ],
          ),
          Expanded(
            child: enableSlide ? slideList(theme) : buildList(theme),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme) {
    return TabBarView(
      controller: _tabController,
      physics: tabBarScrollPhysics,
      horizontalDragGestureRecognizer: horizontalDragGestureRecognizer,
      children: [
        KeepAliveWrapper(child: _buildInfo(theme)),
      ],
    );
  }

  Widget _buildInfo(ThemeData theme) {
    final TextStyle smallTitle = TextStyle(
      fontSize: 12,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle textStyle = TextStyle(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 14,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
      ),
      children: [
        SelectionText(
          widget.item.name,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 6,
          children: [
            if (widget.item.year > 0)
              Text('${widget.item.year}', style: smallTitle),
            if (widget.item.score > 0)
              Text(
                '${widget.item.score.toStringAsFixed(1)} 分',
                style: smallTitle,
              ),
            if (widget.item.localCount > 0)
              Text('共${widget.item.localCount}集', style: smallTitle),
          ],
        ),
        if (widget.item.introduction.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '简介：',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          SelectionText(
            widget.item.introduction,
            style: textStyle,
          ),
        ],
      ],
    );
  }
}
