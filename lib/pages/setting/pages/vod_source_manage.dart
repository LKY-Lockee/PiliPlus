import 'dart:math';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/http_helper.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/plugin/tvbox/widgets/vod_parse_panel.dart';
import 'package:PiliPlus/plugin/tvbox/widgets/vod_source_panel.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class VodSourceManagePage extends StatefulWidget {
  const VodSourceManagePage({super.key});

  @override
  State<VodSourceManagePage> createState() => _VodSourceManagePageState();
}

class _VodSourceManagePageState extends State<VodSourceManagePage> {
  List<SourceBean> sites = const [];
  ApiConfig? config;
  bool _loading = true;
  late List<String> enabledKeys;
  late List<String> configUrls;

  @override
  void initState() {
    super.initState();
    enabledKeys = List.of(Pref.vodEnabledSites);
    configUrls = List.of(Pref.vodConfigUrls);
    if (Pref.vodConfigUrl.isNotEmpty &&
        !configUrls.contains(Pref.vodConfigUrl)) {
      configUrls.insert(0, Pref.vodConfigUrl);
    }
    _reload();
  }

  Future<void> _reload({bool useCache = false}) async {
    if (!_loading && mounted) {
      setState(() => _loading = true);
    }
    try {
      await TVBoxService.to.loadSources(useCache: useCache);
      if (!mounted) return;
      final state = TVBoxService.to.sourcesState.value;
      if (state is! Error) {
        config = TVBoxService.to.config;
        sites = config?.sourceBeanList ?? const [];
        if (enabledKeys.isEmpty) {
          enabledKeys = sites
              .where((e) => e.supported)
              .map((e) => e.key)
              .toList();
        } else {
          enabledKeys.removeWhere(
            (key) => !sites.any((e) => e.key == key && e.supported),
          );
        }
      } else {
        config = null;
        sites = const [];
        enabledKeys = List.of(Pref.vodEnabledSites);
        SmartDialog.showToast(state.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showConfigUrlDialog() async {
    String url = Pref.vodConfigUrl;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: Style.dialogFixedConstraints,
        title: const Text('订阅地址'),
        content: TextFormField(
          autofocus: true,
          initialValue: url,
          textInputAction: TextInputAction.newline,
          minLines: 1,
          maxLines: 3,
          onChanged: (value) => url = value,
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: ColorScheme.of(context).outline),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == true && url.trim().isNotEmpty) {
      final newUrl = url.trim();
      Pref.setVodConfigUrl = newUrl;
      await Pref.clearVodEnabledSites();
      enabledKeys.clear();
      if (!configUrls.contains(newUrl)) {
        configUrls.insert(0, newUrl);
        Pref.setVodConfigUrls = configUrls;
      }
      await _reload();
    }
  }

  void _showConfigUrlsPicker() {
    if (configUrls.isEmpty) {
      _showConfigUrlDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) => Column(
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
                    title: const Text('添加新订阅'),
                    leading: const Icon(Icons.add),
                    onTap: () {
                      Get.back();
                      _showConfigUrlDialog();
                    },
                  ),
                  ...configUrls.map(
                    (url) => ListTile(
                      title: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: url == Pref.vodConfigUrl
                              ? ColorScheme.of(context).primary
                              : null,
                        ),
                      ),
                      leading: const Icon(Icons.link),
                      trailing: url == Pref.vodConfigUrl
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () async {
                        Get.back();
                        if (url != Pref.vodConfigUrl) {
                          Pref.setVodConfigUrl = url;
                          await Pref.clearVodEnabledSites();
                          enabledKeys.clear();
                          await _reload();
                        }
                      },
                      onLongPress: () async {
                        Get.back();
                        configUrls.remove(url);
                        Pref.setVodConfigUrls = configUrls;
                        if (url == Pref.vodConfigUrl) {
                          Pref.setVodConfigUrl = configUrls.firstOrNull ?? '';
                          await Pref.clearVodEnabledSites();
                          await _reload();
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSite(SourceBean site) async {
    if (!site.supported) {
      SmartDialog.showToast('该源不受支持');
      return;
    }
    setState(() {
      if (enabledKeys.contains(site.key)) {
        enabledKeys.remove(site.key);
      } else {
        enabledKeys.add(site.key);
      }
      Pref.setVodEnabledSites = enabledKeys;
    });
    await TVBoxService.to.loadSources(useCache: true);
  }

  void _showParsePicker() {
    VodParsePanel.show(
      context,
      parses: config?.parseBeanList ?? const [],
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _showUaDialog() async {
    String ua = Pref.vodUA;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: Style.dialogFixedConstraints,
        title: const Text('请求 UA'),
        content: TextFormField(
          autofocus: true,
          initialValue: ua,
          textInputAction: TextInputAction.newline,
          minLines: 1,
          maxLines: 3,
          onChanged: (value) => ua = value,
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: ColorScheme.of(context).outline),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == true) {
      Pref.setVodUA = ua.trim();
      TVBoxHttpHelper.updateUserAgent(Pref.vodUA);
      await TVBoxService.to.loadSources(useCache: true);
      SmartDialog.showToast('已保存');
    }
  }

  String get _homeSourceName {
    final key = TVBoxService.to.homeSourceKey.value;
    if (key.isEmpty) {
      return '未设置';
    }
    final match = TVBoxService.to.sources
        .where((site) => site.key == key)
        .firstOrNull;
    return match?.name ?? key;
  }

  void _showHomeSourcePicker() {
    final sources = TVBoxService.to.sources;
    if (sources.isEmpty) {
      SmartDialog.showToast('无可用点播源，请先启用源');
      return;
    }
    VodSourcePanel.show(
      context,
      sources: sources,
      currentKey: TVBoxService.to.homeSourceKey.value,
      onSelected: (key) {
        TVBoxService.to.setHomeSource(key);
        setState(() {});
      },
    );
  }

  Future<void> _showHomeRecPicker() async {
    final current = TVBoxService.to.homeRec.value;
    const options = <(int, String, String)>[
      (TVBoxService.homeRecDouban, '豆瓣热播', '网络热映榜单，点击进入点播搜索'),
      (TVBoxService.homeRecSite, '站点推荐', '使用首页站源的推荐内容'),
    ];
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) => Column(
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
                children: options
                    .map(
                      (option) => ListTile(
                        title: Text(option.$2),
                        subtitle: Text(
                          option.$3,
                          style: const TextStyle(fontSize: 12),
                        ),
                        leading: Icon(
                          option.$1 == TVBoxService.homeRecDouban
                              ? Icons.local_fire_department_outlined
                              : Icons.dns_outlined,
                        ),
                        trailing: option.$1 == current
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () {
                          TVBoxService.to.setHomeRec(option.$1);
                          Get.back();
                          setState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('源设置')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          ListTile(
            leading: const Icon(Icons.rss_feed),
            title: const Text('订阅地址'),
            subtitle: Text(
              Pref.vodConfigUrl.isEmpty ? '点击配置' : Pref.vodConfigUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: _showConfigUrlDialog,
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: const Text('已存订阅'),
            subtitle: Text('共 ${configUrls.length} 个订阅'),
            onTap: _showConfigUrlsPicker,
          ),
          ListTile(
            leading: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('默认解析'),
            subtitle: Text(
              Pref.vodDefaultParse.isEmpty ? '自动选择' : Pref.vodDefaultParse,
            ),
            onTap: _showParsePicker,
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_outlined),
            title: const Text('请求 UA'),
            subtitle: Text(Pref.vodUA, maxLines: 1),
            onTap: _showUaDialog,
          ),
          ListTile(
            leading: const Icon(Icons.recommend_outlined),
            title: const Text('首页推荐'),
            subtitle: Text(
              TVBoxService.to.homeRec.value == TVBoxService.homeRecDouban
                  ? '豆瓣热播'
                  : '站点推荐',
            ),
            onTap: _showHomeRecPicker,
          ),
          if (!_loading &&
              TVBoxService.to.homeRec.value == TVBoxService.homeRecSite)
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('首页站源'),
              subtitle: Text(
                _homeSourceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: _showHomeSourcePicker,
            ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('刷新配置'),
            subtitle: const Text('忽略缓存重新拉取'),
            onTap: _reload,
          ),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: m3eLoading,
            )
          else ...[
            Padding(
              padding: const .fromLTRB(16, 12, 16, 4),
              child: Text(
                '共${sites.length}个点播源，已启用${enabledKeys.length}个',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            if (sites.isEmpty)
              Padding(
                padding: const .all(24),
                child: Center(
                  child: Text(
                    '未加载到站点，请先配置订阅地址',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              )
            else
              ...sites.map((site) {
                final enabled = enabledKeys.contains(site.key);
                return ListTile(
                  dense: true,
                  title: Text(
                    site.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: site.supported ? null : theme.colorScheme.outline,
                    ),
                  ),
                  leading: Icon(
                    enabled ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  trailing: !site.supported
                      ? Text(
                          '不支持',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.error,
                          ),
                        )
                      : null,
                  onTap: () => _toggleSite(site),
                );
              }),
          ],
        ],
      ),
    );
  }
}
