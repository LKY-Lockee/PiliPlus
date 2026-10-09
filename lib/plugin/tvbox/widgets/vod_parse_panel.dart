import 'dart:math';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodParsePanel extends StatelessWidget {
  const VodParsePanel({super.key, required this.parses, this.onChanged});

  final List<ParseBean> parses;
  final ValueChanged<String>? onChanged;

  static Future<void> show(
    BuildContext context, {
    required List<ParseBean> parses,
    ValueChanged<String>? onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) => VodParsePanel(
        parses: parses,
        onChanged: onChanged,
      ),
    );
  }

  void _select(String value) {
    Pref.setVodDefaultParse = value;
    Get.back();
    onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final current = Pref.vodDefaultParse;
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
              children: [
                ListTile(
                  title: const Text('自动选择'),
                  subtitle: const Text(
                    '按源与解析规则自动决定',
                    style: TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Icons.auto_awesome_outlined),
                  trailing: current.isEmpty ? const Icon(Icons.check) : null,
                  onTap: () => _select(''),
                ),
                ...parses.map(
                  (parse) => ListTile(
                    title: Text(parse.name),
                    subtitle: Text(
                      parse.type == 1 ? 'Json解析' : '网页嗅探',
                      style: const TextStyle(fontSize: 12),
                    ),
                    leading: Icon(
                      parse.type == 1
                          ? Icons.data_object_outlined
                          : Icons.travel_explore_outlined,
                    ),
                    trailing: parse.name == current
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => _select(parse.name),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
