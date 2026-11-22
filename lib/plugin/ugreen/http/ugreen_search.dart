import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/search.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenSearchHttp {
  static Future<LoadingState<UgreenSearchData>> search(
    UgreenSession session, {
    required String keyword,
    UgreenSearchType type = UgreenSearchType.all,
    int cursor = 0,
    int limit = 100,
  }) async {
    final value = keyword.trim();
    if (value.isEmpty) {
      return Success(UgreenSearchData.empty());
    }
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoSearch,
      query: {
        'keyword': value,
        'search_type': type.value,
        'cursor': cursor,
        'limit': limit,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('搜索失败');
    }
    final data = res.response['data'];
    if (data is! Map) {
      return const Error('搜索失败');
    }
    try {
      return Success(UgreenSearchData.fromJson(data.cast<String, dynamic>()));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }
}
