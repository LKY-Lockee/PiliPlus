import 'dart:math';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodSourcePanel extends StatelessWidget {
  const VodSourcePanel({
    super.key,
    required this.sources,
    required this.currentKey,
    this.onSelected,
  });

  final List<SourceBean> sources;
  final String currentKey;
  final ValueChanged<String>? onSelected;

  static Future<void> show(
    BuildContext context, {
    required List<SourceBean> sources,
    required String currentKey,
    ValueChanged<String>? onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) => VodSourcePanel(
        sources: sources,
        currentKey: currentKey,
        onSelected: onSelected,
      ),
    );
  }

  void _select(String key) {
    Get.back();
    onSelected?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: Get.back,
          borderRadius: Style.bottomSheetRadius,
          child: SizedBox(
            height: 35,
            child: Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).outline,
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sources
                  .map(
                    (site) => ListTile(
                      title: Text(site.name),
                      subtitle: Text(
                        site.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      leading: const Icon(Icons.dns_outlined),
                      trailing: site.key == currentKey
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => _select(site.key),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
