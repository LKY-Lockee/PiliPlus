import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider.dart';

/// com.github.catvod.crawler.SpiderNull
class SpiderNull implements Spider {
  @override
  Future<String> homeContent(bool filter) async => '';

  @override
  Future<String> homeVideoContent() async => '';

  @override
  Future<String> categoryContent(
    String tid,
    String pg,
    bool filter,
    Map<String, String>? extend,
  ) async => '';

  @override
  Future<String> detailContent(List<String> ids) async => '';

  @override
  Future<String> searchContent(String key, bool quick, [String? pg]) async =>
      '';

  @override
  Future<String> playerContent(
    String flag,
    String id,
    List<String> vipFlags,
  ) async => '';

  @override
  Future<bool> isVideoFormat(String url) async => false;

  @override
  Future<bool> manualVideoCheck() async => false;

  @override
  Future<Object?> proxyLocal(Map<String, String> params) async => null;

  @override
  Future<void> destroy() async {}
}
