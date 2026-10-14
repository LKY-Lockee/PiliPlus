import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/widgets/select_dialog.dart';
import 'package:PiliPlus/pages/setting/widgets/slider_dialog.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/doh.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/http_helper.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

List<SettingsModel> get vodSettings => [
  NormalModel(
    title: '源设置',
    subtitle: '订阅地址、点播源管理、解析、UA、首页源',
    leading: const Icon(Icons.dns_outlined),
    onTap: (context, setState) => Get.toNamed('/vodSourceManage'),
  ),
  const SwitchModel(
    title: '视频广告过滤',
    subtitle: '播放点播视频时过滤 m3u8 广告切片',
    setKey: SettingBoxKey.vodM3u8Purify,
    defaultVal: true,
    leading: Icon(Icons.movie_filter_outlined),
  ),
  const SwitchModel(
    title: '网页广告拦截',
    subtitle: '嗅探播放地址时拦截配置内的广告域名',
    setKey: SettingBoxKey.vodWebAdBlock,
    leading: Icon(Icons.block_outlined),
  ),
  const SwitchModel(
    title: '移除广告时显示通知',
    subtitle: '去广告后提示移除的广告条数',
    setKey: SettingBoxKey.vodAdRemoveToast,
    defaultVal: true,
    leading: Icon(Icons.notifications_active_outlined),
  ),
  const SwitchModel(
    title: '自动换源',
    subtitle: '当前源所有线路不可用时自动切换到其它同名源',
    setKey: SettingBoxKey.vodAutoChangeSource,
    defaultVal: true,
    leading: Icon(Icons.swap_horiz_outlined),
  ),
  const NormalModel(
    title: '自动换源重试上限',
    subtitle: '为0时尝试所有可用源',
    leading: Icon(Icons.loop_outlined),
    onTap: _showAutoChangeSourceRetryDialog,
  ),
  const SwitchModel(
    title: '自动换线',
    subtitle: '播放失败时自动切换到下一条线路',
    setKey: SettingBoxKey.vodAutoSwitchLine,
    defaultVal: true,
    leading: Icon(Icons.swap_horiz_outlined),
  ),
  const NormalModel(
    title: '自动换线重试上限',
    subtitle: '为0时无限重试',
    leading: Icon(Icons.loop_outlined),
    onTap: _showAutoSwitchRetryDialog,
  ),
  NormalModel(
    title: '安全DNS',
    getSubtitle: () {
      final names = Doh.names;
      final index = Pref.vodDohUrl;
      return index >= 0 && index < names.length ? names[index] : '关闭';
    },
    leading: const Icon(Icons.security_outlined),
    onTap: _showDohDialog,
  ),
];

Future<void> _showDohDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final names = Doh.names;
  final res = await showDialog<int>(
    context: context,
    builder: (context) => SelectDialog<int>(
      title: '请选择安全DNS',
      value: Pref.vodDohUrl,
      values: [for (var i = 0; i < names.length; i++) (i, names[i])],
    ),
  );
  if (res != null && res != Pref.vodDohUrl) {
    Pref.setVodDohUrl = res;
    TVBoxHttpHelper.reloadDns();
    setState();
  }
}

Future<void> _showAutoChangeSourceRetryDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('自动换源重试上限'),
      min: 0,
      max: 8,
      divisions: 8,
      precise: 0,
      value: Pref.vodAutoChangeSourceRetry.toDouble(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.vodAutoChangeSourceRetry,
      res.toInt(),
    );
    setState();
  }
}

Future<void> _showAutoSwitchRetryDialog(
  BuildContext context,
  VoidCallback setState,
) async {
  final res = await showDialog<double>(
    context: context,
    builder: (context) => SliderDialog(
      title: const Text('自动换线重试上限'),
      min: 0,
      max: 8,
      divisions: 8,
      precise: 0,
      value: Pref.vodAutoSwitchLineRetry.toDouble(),
    ),
  );
  if (res != null) {
    await GStorage.setting.put(
      SettingBoxKey.vodAutoSwitchLineRetry,
      res.toInt(),
    );
    setState();
  }
}
