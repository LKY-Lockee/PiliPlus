import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/storage_key.dart';
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
];
