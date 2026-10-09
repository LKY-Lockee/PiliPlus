import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/search_helper.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

class TVBoxService extends GetxService {
  /// com.github.tvbox.osc.api.ApiConfig.instance
  ApiConfig? config;

  final Rx<LoadingState<List<SourceBean>>> sourcesState =
      LoadingState<List<SourceBean>>.loading().obs;

  /// com.github.tvbox.osc.api.ApiConfig.mHomeSource
  final RxString homeSourceKey = Pref.vodDefaultSite.obs;

  /// com.github.tvbox.osc.util.HawkConfig.HOME_REC
  final RxInt homeRec = Pref.vodHomeRec.obs;

  Future<ApiConfig?>? _configFuture;

  static const int homeRecDouban = 0;
  static const int homeRecSite = 1;

  List<SourceBean> get sources => sourcesState.value.dataOrNull ?? const [];

  List<SourceBean> get searchableSources {
    final cfg = config;
    if (cfg == null) return const [];
    return SearchHelper.getSourcesForSearch(cfg);
  }

  static TVBoxService get to => Get.find();

  /// com.github.tvbox.osc.api.ApiConfig.setSourceBean
  void setHomeSource(String key) {
    if (Pref.vodDefaultSite != key) {
      Pref.setVodDefaultSite = key;
    }
    if (homeSourceKey.value != key) {
      homeSourceKey.value = key;
    }
  }

  void setHomeRec(int value) {
    if (Pref.vodHomeRec != value) {
      Pref.setVodHomeRec = value;
    }
    if (homeRec.value != value) {
      homeRec.value = value;
    }
  }

  SourceBean? sourceByKey(String key) =>
      sources.where((source) => source.key == key).firstOrNull;

  SourceViewModel viewModel(String sourceKey) =>
      SourceViewModel(config: config!, sourceKey: sourceKey);

  Future<ApiConfig?> getConfig({bool useCache = true}) {
    if (config != null) {
      return Future.value(config);
    }
    return _configFuture ??= loadSources(useCache: useCache)
        .then((_) => config)
        .whenComplete(() => _configFuture = null);
  }

  Future<void> resetConfig() async {
    config = null;
    setHomeSource('');
    setHomeRec(homeRecDouban);
    if (Pref.vodDefaultParse.isNotEmpty) {
      Pref.setVodDefaultParse = '';
    }
    await Pref.clearVodEnabledSites();
  }

  Future<void> loadSources({bool useCache = false}) async {
    sourcesState.value = LoadingState.loading();
    final result = await ApiConfig.load(useCache: useCache);
    if (result case Success(:final response)) {
      config = response;
      final supportedSites = response.sourceBeanList.where(
        (site) => site.supported,
      );
      if (!Pref.hasVodEnabledSites) {
        Pref.setVodEnabledSites = supportedSites
            .map((site) => site.key)
            .toList();
      }
      final enabled = Pref.vodEnabledSites.toSet();
      final enabledSites = supportedSites
          .where((site) => enabled.contains(site.key))
          .toList();
      sourcesState.value = Success(enabledSites);
      if (enabledSites.isEmpty) {
        setHomeSource('');
      } else if (!enabledSites.any((site) => site.key == homeSourceKey.value)) {
        setHomeSource(enabledSites.first.key);
      }
    } else {
      config = null;
      if (Pref.vodConfigUrl.isEmpty) {
        await resetConfig();
      }
      sourcesState.value = result as Error;
    }
  }
}
