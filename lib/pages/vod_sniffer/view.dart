import 'dart:async';
import 'dart:io' show Platform;

import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/main.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/video_parse_ruler.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodSnifferPage extends StatefulWidget {
  const VodSnifferPage({super.key});

  @override
  State<VodSnifferPage> createState() => _VodSnifferPageState();
}

class _VodSnifferPageState extends State<VodSnifferPage> {
  late final String url = Get.arguments['url'] ?? '';
  late final Map<String, String> headers = Map.from(
    Get.arguments['headers'] ?? const {},
  );
  late final String sourceKey = Get.arguments['sourceKey'] ?? '';

  SourceBean? get _source =>
      sourceKey.isEmpty ? null : TVBoxService.to.sourceByKey(sourceKey);

  Future<bool> _checkVideoFormat(String target) async {
    if (target.contains('url=http') || target.contains('.html')) {
      return false;
    }
    final source = _source;
    final config = TVBoxService.to.config;
    if (source != null && config != null) {
      return SourceViewModel(
        config: config,
        sourceKey: source.key,
      ).checkVideoFormat(url, target);
    }
    return VideoParseRuler.checkIsVideoForParse(url, target);
  }

  final RxBool isDone = false.obs;
  Timer? _timer;
  late final RxInt _countdown = 20.obs;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown.value--;
      if (_countdown.value <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onFound(String videoUrl) {
    if (isDone.value) {
      return;
    }
    isDone.value = true;
    _timer?.cancel();
    Get.back(result: videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux) {
      return SimpleScaffold(
        appBar: AppBar(title: const Text('嗅探')),
        body: const Center(
          child: Text('当前平台不支持网页嗅探'),
        ),
      );
    }
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('正在嗅探播放地址'),
        actions: [
          Obx(
            () => _countdown.value > 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        '${_countdown.value}s',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: InAppWebView(
        webViewEnvironment: webViewEnvironment,
        initialSettings: InAppWebViewSettings(
          clearCache: true,
          javaScriptEnabled: true,
          forceDark: ForceDark.AUTO,
          useHybridComposition: false,
          algorithmicDarkeningAllowed: true,
          useShouldOverrideUrlLoading: true,
          userAgent: headers['user-agent'] ?? BrowserUa.mob,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        ),
        initialUrlRequest: URLRequest(
          url: WebUri.uri(Uri.tryParse(url) ?? Uri()),
          headers: headers,
        ),

        /// com.github.tvbox.osc.ui.fragment.PlayFragment.shouldInterceptRequest
        shouldInterceptRequest: (controller, request) async {
          final requestUrl = request.url.toString();
          if (VideoParseRuler.isFilter(url, requestUrl)) {
            return null;
          }
          if (await _checkVideoFormat(requestUrl)) {
            _onFound(requestUrl);
          }
          return null;
        },

        /// com.github.tvbox.osc.ui.fragment.PlayFragment.shouldOverrideUrlLoading
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final navUrl = navigationAction.request.url.toString();
          if (VideoParseRuler.isFilter(url, navUrl)) {
            return .ALLOW;
          }
          if (await _checkVideoFormat(navUrl)) {
            _onFound(navUrl);
            return .CANCEL;
          }
          return .ALLOW;
        },
      ),
    );
  }
}
