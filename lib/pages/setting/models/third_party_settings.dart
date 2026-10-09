import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get thirdPartySettings => [
  NormalModel(
    title: '点播设置',
    subtitle: '订阅地址、点播源管理、解析、UA、首页源',
    leading: const Icon(MdiIcons.movieOpenOutline),
    onTap: (context, setState) => Get.toNamed('/vodSourceManage'),
  ),
];
