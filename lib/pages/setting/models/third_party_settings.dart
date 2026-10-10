import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get thirdPartySettings => [
  NormalModel(
    title: '点播设置',
    subtitle: '源设置、去广告',
    leading: const Icon(MdiIcons.movieOpenOutline),
    onTap: (context, setState) => Get.toNamed('/vodSettings'),
  ),
];
