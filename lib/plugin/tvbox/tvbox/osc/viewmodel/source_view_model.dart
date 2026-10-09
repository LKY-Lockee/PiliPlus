import 'dart:async';
import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/models_new/vod/play.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/abs_json.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/abs_sort_json.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/abs_sort_xml.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/abs_xml.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/video_parse_ruler.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// com.github.tvbox.osc.viewmodel.SourceViewModel
class SourceViewModel {
  final ApiConfig config;

  final String sourceKey;

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.extendCache
  static final _extendCache = <String, String>{};

  SourceBean? get source => config.getSource(sourceKey);

  SourceViewModel({required this.config, required this.sourceKey});

  static Map<String, dynamic>? _asMap(String? body) {
    if (body == null || body.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(body);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.playUrl
  static VodPlayInfo? _normalizePlayResult(
    Map<String, dynamic> json,
    String flag,
  ) {
    var url = json['url']?.toString() ?? '';
    if (url.isEmpty) {
      return null;
    }
    final playUrlPrefix = json['playUrl']?.toString() ?? '';
    var parse = json['parse']?.toString() == '1';
    final jx = json['jx']?.toString() == '1';
    final qualities = <VodQuality>[];

    if (url.startsWith('[') && url.endsWith(']')) {
      try {
        final arr = jsonDecode(url);
        if (arr is List) {
          for (var i = 0; i + 1 < arr.length; i += 2) {
            final name = arr[i]?.toString();
            final link = arr[i + 1]?.toString();
            if (name != null && link != null) {
              if (link.startsWith('video://')) {
                qualities.add(
                  VodQuality(name: name, url: link.substring(8)),
                );
              } else {
                qualities.add(VodQuality(name: name, url: link));
              }
            }
          }
        }
        if (qualities.isNotEmpty) {
          url = qualities.first.url;
          parse = false;
        }
      } catch (_) {}
    } else if (url.startsWith('video://')) {
      url = url.substring(8);
      parse = true;
    } else if (url.startsWith('proxy://')) {
      return null;
    } else if (playUrlPrefix.isEmpty &&
        DefaultConfig.isVideoFormat(url) &&
        !json.containsKey('parse') &&
        !json.containsKey('jx')) {
      parse = false;
    }
    if (url.isEmpty) {
      return null;
    }

    final headers = <String, String>{};
    for (final key in ['header', 'headers']) {
      final header = json[key];
      if (header is Map<String, dynamic>) {
        header.forEach((k, v) {
          if (v != null) {
            headers[k] = v.toString();
          }
        });
      } else if (header is String && header.isNotEmpty) {
        try {
          final parsed = jsonDecode(header);
          if (parsed is Map<String, dynamic>) {
            parsed.forEach((k, v) {
              if (v != null) {
                headers[k] = v.toString();
              }
            });
          }
        } catch (_) {}
      }
    }

    return VodPlayInfo(
      url: url,
      flag: json['flag']?.toString() ?? flag,
      parse: parse || jx,
      jx: jx,
      parsePrefix: playUrlPrefix.isEmpty ? null : playUrlPrefix,
      headers: headers,
      qualities: qualities,
    );
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.absXml
  static List<VodPlayGroup> parsePlayUrls(
    String? playFrom,
    String? playUrl,
  ) {
    if (playFrom == null || playUrl == null || playFrom.isEmpty) {
      return const [];
    }
    final flags = playFrom.split(r'$$$');
    final groups = playUrl.split(r'$$$');
    final result = <VodPlayGroup>[];
    for (var i = 0; i < flags.length && i < groups.length; i++) {
      final flag = flags[i].trim();
      final group = groups[i].trim();
      if (flag.isEmpty || group.isEmpty) {
        continue;
      }
      final episodes = <VodEpisode>[];
      for (final seg in group.split('#')) {
        final segTrim = seg.trim();
        if (segTrim.isEmpty) {
          continue;
        }
        final idx = segTrim.indexOf(r'$');
        if (idx > 0) {
          episodes.add(
            VodEpisode(
              name: segTrim.substring(0, idx),
              url: segTrim.substring(idx + 1),
            ),
          );
        } else {
          episodes.add(
            VodEpisode(
              name: '${episodes.length + 1}',
              url: segTrim,
            ),
          );
        }
      }
      if (episodes.isNotEmpty) {
        result.add(VodPlayGroup(flag: flag, episodes: episodes));
      }
    }
    return result;
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getFixUrl
  Future<String> _getExtend() async {
    final ext = source?.ext ?? '';
    if (!ext.startsWith('http')) {
      return ext;
    }
    final cacheKey = md5.convert(utf8.encode(ext)).toString();
    final cached = _extendCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    String result = ext;
    final data = await Http.string(
      ext,
      options: Options(responseType: ResponseType.plain),
    );
    if (data != null) {
      String minified;
      try {
        minified = jsonEncode(jsonDecode(data));
      } catch (_) {
        minified = data;
      }
      if (minified.length <= 2500) {
        result = minified;
      }
    }
    _extendCache[cacheKey] = result;
    return result;
  }

  Future<Map<String, dynamic>?> _getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    int? timeoutSeconds,
  }) async {
    final data = await Http.string(
      url,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: Duration(
          seconds: timeoutSeconds ?? source?.playTimeoutSeconds ?? 15,
        ),
      ),
    );
    return _asMap(data);
  }

  void _attachSourceKey(Iterable<VodVideo>? cards) {
    if (cards == null) return;
    for (final card in cards) {
      card.sourceKey = sourceKey;
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getSort
  Future<LoadingState<VodHomeData>> getSort({bool filter = true}) async {
    final bean = source;
    if (bean == null) {
      return const Error('未配置点播源');
    }
    switch (bean.type) {
      case 0:
      case 1:
        final res = await Http.get(
          bean.api,
          options: Options(responseType: ResponseType.plain),
        );
        if (res.data == null) {
          return const Error('请求分类失败');
        }
        final state = bean.type == 0
            ? AbsSortXml.parse(res.data!, sourceCategories: bean.categories)
            : AbsSortJson.parse(res.data!, sourceCategories: bean.categories);
        if (state case Success(:final response)) {
          _attachSourceKey(response.videoList);
        }
        return state;
      case 3:
        try {
          final spider = await config.getCSP(bean);
          final json = _asMap(await spider.homeContent(true));
          if (json == null) {
            return const Error('请求分类失败');
          }
          final data = AbsSortJson.toAbsSortXml(
            json,
            sourceCategories: bean.categories,
          );
          if (data.categories.isEmpty) {
            return const Error('源未返回分类');
          }
          _attachSourceKey(data.videoList);
          final vodJson = _asMap(await spider.homeVideoContent());
          if (vodJson == null) {
            return Success(data);
          }
          final cards = AbsJson.toAbsXml(vodJson).videoList;
          _attachSourceKey(cards);
          return Success(
            VodHomeData(
              categories: data.categories,
              filters: data.filters,
              videoList: cards,
            ),
          );
        } on TimeoutException {
          return const Error('请求分类超时');
        } catch (e) {
          return Error('请求分类失败: $e');
        }
      case 4:
        final extend = await _getExtend();
        final json = await _getJson(
          bean.api,
          queryParameters: {
            'filter': 'true',
            if (extend.isNotEmpty) 'extend': extend,
          },
        );
        if (json == null) {
          return const Error('请求分类失败');
        }
        final data = AbsSortJson.toAbsSortXml(
          json,
          sourceCategories: bean.categories,
        );
        _attachSourceKey(data.videoList);
        return Success(data);
      default:
        return const Error('不支持的源类型');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getList
  Future<LoadingState<VodListData>> getList(
    String tid,
    int page, [
    Map<String, String>? filters,
  ]) async {
    final bean = source;
    if (bean == null) {
      return const Error('未配置点播源');
    }
    filters ??= const {};
    switch (bean.type) {
      case 0:
      case 1:
        final params = <String, dynamic>{
          'ac': bean.type == 0 ? 'videolist' : 'detail',
          't': tid,
          'pg': page,
          'f': filters.isEmpty ? '' : jsonEncode(filters),
          ...filters,
        };
        final res = await Http.get(
          bean.api,
          queryParameters: params,
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: Duration(seconds: bean.playTimeoutSeconds),
          ),
        );
        if (res.data == null) {
          return const Error('请求分类失败');
        }
        final state = bean.type == 0
            ? AbsXml.parse(res.data!)
            : AbsJson.parse(res.data!);
        if (state case Success(:final response)) {
          _attachSourceKey(response.videoList);
        }
        return state;
      case 3:
        try {
          final spider = await config.getCSP(bean);
          final json = _asMap(
            await spider.categoryContent(tid, '$page', true, filters),
          );
          if (json == null) {
            return const Error('请求分类失败');
          }
          final data = AbsJson.toAbsXml(json);
          _attachSourceKey(data.videoList);
          return Success(data);
        } on TimeoutException {
          return const Error('请求分类超时');
        } catch (e) {
          return Error('请求分类失败: $e');
        }
      case 4:
        final extend = await _getExtend();
        String ext;
        try {
          ext = base64.encode(utf8.encode(jsonEncode(filters)));
        } catch (_) {
          ext = base64.encode(utf8.encode('{}'));
        }
        final json = await _getJson(
          bean.api,
          queryParameters: {
            'ac': 'detail',
            'filter': 'true',
            't': tid,
            'pg': page,
            'ext': ext,
            if (extend.isNotEmpty) 'extend': extend,
          },
        );
        if (json == null) {
          return const Error('请求分类失败');
        }
        final data = AbsJson.toAbsXml(json);
        _attachSourceKey(data.videoList);
        return Success(data);
      default:
        return const Error('不支持的源类型');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getDetail
  Future<LoadingState<VodInfoModel>> getDetail(String id) async {
    final bean = source;
    if (bean == null) {
      return const Error('未配置点播源');
    }
    switch (bean.type) {
      case 0:
      case 1:
        final res = await Http.get(
          bean.api,
          queryParameters: {
            'ac': bean.type == 0 ? 'videolist' : 'detail',
            'ids': id,
          },
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: Duration(seconds: bean.playTimeoutSeconds),
          ),
        );
        if (res.data == null) {
          return const Error('请求详情失败');
        }
        final state = bean.type == 0
            ? AbsXml.parseDetail(res.data!)
            : AbsJson.parseDetail(res.data!);
        if (state case Success(:final response)) {
          response.video.sourceKey = sourceKey;
        }
        return state;
      case 3:
        try {
          final spider = await config.getCSP(bean);
          final json = _asMap(await spider.detailContent([id]));
          if (json == null) {
            return const Error('请求详情失败');
          }
          final list = json['list'];
          if (list is List && list.isNotEmpty && list.first is Map) {
            final detail = VodInfoModel.fromJson(
              (list.first as Map).cast<String, dynamic>(),
            );
            if (detail != null) {
              detail.video.sourceKey = sourceKey;
              return Success(detail);
            }
          }
          return const Error('未找到相关内容');
        } on TimeoutException {
          return const Error('请求详情超时');
        } catch (e) {
          return Error('请求详情失败: $e');
        }
      case 4:
        final extend = await _getExtend();
        final json = await _getJson(
          bean.api,
          queryParameters: {
            'ac': 'detail',
            'ids': id,
            if (extend.isNotEmpty) 'extend': extend,
          },
        );
        if (json == null) {
          return const Error('请求详情失败');
        }
        final list = json['list'];
        if (list is List && list.isNotEmpty && list.first is Map) {
          final detail = VodInfoModel.fromJson(
            (list.first as Map).cast<String, dynamic>(),
          );
          if (detail != null) {
            detail.video.sourceKey = sourceKey;
            return Success(detail);
          }
        }
        return const Error('未找到相关内容');
      default:
        return const Error('不支持的源类型');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getSearch
  Future<LoadingState<List<VodVideo>>> getSearch(
    String keyword, {
    bool quick = false,
  }) async {
    final bean = source;
    if (bean == null) {
      return const Error('未配置点播源');
    }
    switch (bean.type) {
      case 0:
        final res = await Http.get(
          bean.api,
          queryParameters: {'wd': keyword},
          options: Options(
            responseType: ResponseType.plain,
            receiveTimeout: Duration(seconds: bean.playTimeoutSeconds),
          ),
        );
        if (res.data == null) {
          return const Error('请求搜索失败');
        }
        final state = AbsXml.parse(res.data!);
        if (state case Success(:final response)) {
          _attachSourceKey(response.videoList);
          return Success(response.videoList);
        }
        return state as Error;
      case 1:
        final json = await _getJson(
          bean.api,
          queryParameters: {'wd': keyword, 'ac': 'detail'},
        );
        if (json == null) {
          return const Error('请求搜索失败');
        }
        final cards = AbsJson.toAbsXml(json).videoList;
        _attachSourceKey(cards);
        return Success(cards);
      case 3:
        try {
          final spider = await config.getCSP(bean);
          final json = _asMap(await spider.searchContent(keyword, quick));
          if (json == null) {
            return const Error('请求搜索失败');
          }
          final cards = AbsJson.toAbsXml(json).videoList;
          _attachSourceKey(cards);
          return Success(cards);
        } on TimeoutException {
          return const Error('请求搜索超时');
        } catch (e) {
          return Error('请求搜索失败: $e');
        }
      case 4:
        final extend = await _getExtend();
        final json = await _getJson(
          bean.api,
          queryParameters: {
            'wd': keyword,
            'ac': 'detail',
            'quick': quick ? 'true' : 'false',
            if (extend.isNotEmpty) 'extend': extend,
          },
        );
        if (json == null) {
          return const Error('请求搜索失败');
        }
        final cards = AbsJson.toAbsXml(json).videoList;
        _attachSourceKey(cards);
        return Success(cards);
      default:
        return const Error('不支持的源类型');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.getPlay
  Future<LoadingState<VodPlayInfo>> getPlay(String flag, String url) async {
    final bean = source;
    if (bean == null) {
      return const Error('未配置点播源');
    }
    switch (bean.type) {
      case 0:
      case 1:
        final playUrl = bean.playUrl.trim();
        final direct = DefaultConfig.isVideoFormat(url) && playUrl.isEmpty;
        return Success(
          VodPlayInfo(
            url: url,
            flag: flag,
            parse: !direct,
            parsePrefix: playUrl.isEmpty ? null : playUrl,
          ),
        );
      case 3:
        try {
          final spider = await config.getCSP(bean);
          final json = _asMap(
            await spider.playerContent(flag, url, config.vipParseFlags),
          );
          if (json == null) {
            return const Error('请求播放数据失败');
          }
          final info = _normalizePlayResult(json, flag);
          if (info == null) {
            return const Error('请求播放数据失败');
          }
          return Success(info);
        } on TimeoutException {
          return const Error('请求播放数据超时');
        } catch (e) {
          return Error('请求播放数据失败: $e');
        }
      case 4:
        final extend = await _getExtend();
        final json = await _getJson(
          bean.api,
          queryParameters: {
            'play': url,
            'flag': flag,
            if (extend.isNotEmpty) 'extend': extend,
          },
        );
        if (json == null) {
          return const Error('请求播放数据失败');
        }
        final info = _normalizePlayResult(json, flag);
        if (info == null) {
          return const Error('请求播放数据失败');
        }
        return Success(info);
      default:
        return const Error('不支持的源类型');
    }
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.checkVideoFormat
  Future<bool> checkVideoFormat(String webUrl, String target) async {
    if (target.contains('url=http') || target.contains('.html')) {
      return false;
    }
    final bean = source;
    if (bean != null && bean.type == 3) {
      final spider = await config.getCSP(bean);
      if (await spider.manualVideoCheck()) {
        return spider.isVideoFormat(target);
      }
    }
    return VideoParseRuler.checkIsVideoForParse(webUrl, target);
  }
}
