import 'package:PiliPlus/models_new/history/history_bili/data.dart';
import 'package:PiliPlus/models_new/history/history_bili/list.dart';
import 'package:PiliPlus/pages/common/search/common_search_page.dart';
import 'package:PiliPlus/pages/history/bili/widgets/item.dart';
import 'package:PiliPlus/pages/history_search/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState
    extends
        CommonSearchPageState<
          HistorySearchPage,
          HistoryData,
          HistoryBiliItemModel
        >
    with GridMixin {
  @override
  final HistorySearchController controller = Get.put(
    HistorySearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget buildList(List<HistoryBiliItemModel> list) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final item = list[index];
        return HistoryBiliItem(
          item: item,
          ctr: controller,
          onDelete: (kid, business) =>
              controller.onDelHistory(index, kid, business),
        );
      },
      itemCount: list.length,
    );
  }
}
