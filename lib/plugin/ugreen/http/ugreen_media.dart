import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/all.dart';
import 'package:PiliPlus/models_new/ugreen/folder.dart';
import 'package:PiliPlus/models_new/ugreen/media_lib.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenMediaHttp {
  static Future<LoadingState<UgreenFolderData>> folders(
    UgreenSession session, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.folderList,
      query: {
        'page': page,
        'page_size': pageSize,
        'sort_type': 1,
        'order_type': 1,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenFolderData.fromJson(res.response['data']));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<UgreenMediaLibData>> mediaLibraries(
    UgreenSession session,
  ) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.mediaList,
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenMediaLibData.fromJson(res.response['data']));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<UgreenAllData>> allVideos(
    UgreenSession session, {
    required int classification,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoAll,
      query: {
        'language': UgreenHttpString.language,
        'classification': classification,
        'page': page,
        'pageSize': pageSize,
        'sort_type': 2,
        'order_type': 2,
        'clarity': -1,
        'ug_style_id': 0,
        'ug_country_id': 0,
        'release_date_begin': -9999999999,
        'release_date_end': -9999999999,
        'identify_status': 0,
        'watch_status': -1,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenAllData.fromJson(res.response['data']));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static String coverUrl(
    UgreenSession session, {
    String? categoryId,
    String? posterPath,
  }) {
    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }
    final id = categoryId;
    final idQuery = id == null || id.isEmpty
        ? ''
        : '&id=${Uri.encodeComponent(id)}';
    final baseUrl = UgreenEndpoint.displayUrl(session);
    if (baseUrl.isEmpty) {
      return '';
    }
    return '$baseUrl/ugreen/${UgreenApi.imageStream}'
        '?app_name=web&size=1'
        '$idQuery'
        '&ugk=${Uri.encodeComponent(session.staticToken)}'
        '&name=${Uri.encodeComponent(posterPath)}';
  }
}
