/// com.github.catvod.crawler.Spider
abstract class Spider {
  /// com.github.catvod.crawler.Spider.homeContent
  Future<String> homeContent(bool filter);

  /// com.github.catvod.crawler.Spider.homeVideoContent
  Future<String> homeVideoContent();

  /// com.github.catvod.crawler.Spider.categoryContent
  Future<String> categoryContent(
    String tid,
    String pg,
    bool filter,
    Map<String, String>? extend,
  );

  /// com.github.catvod.crawler.Spider.detailContent
  Future<String> detailContent(List<String> ids);

  /// com.github.catvod.crawler.Spider.searchContent
  Future<String> searchContent(String key, bool quick, [String? pg]);

  /// com.github.catvod.crawler.Spider.playerContent
  Future<String> playerContent(String flag, String id, List<String> vipFlags);

  /// com.github.catvod.crawler.Spider.isVideoFormat
  Future<bool> isVideoFormat(String url);

  /// com.github.catvod.crawler.Spider.manualVideoCheck
  Future<bool> manualVideoCheck();

  /// com.github.catvod.crawler.Spider.proxyLocal
  Future<Object?> proxyLocal(Map<String, String> params);

  /// com.github.catvod.crawler.Spider.destroy
  Future<void> destroy();
}
