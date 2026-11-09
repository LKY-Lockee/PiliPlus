import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_ugreen/data.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenHistoryHttp {
  static Future<LoadingState<HistoryUgreenData>> recentlyPlayed(
    UgreenSession session, {
    required int page,
    int pageSize = 50,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.recentlyPlayedGet,
      query: {
        'page': page,
        'page_size': pageSize,
        'language': UgreenHttpString.language,
        'create_time_order': false,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(HistoryUgreenData.fromJson(res.response['data']));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<void>> deleteRecentlyPlayed(
    UgreenSession session, {
    required int delType,
    List<int> ids = const [],
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.recentlyPlayedDelete,
      method: 'POST',
      data: {
        'del_type': delType,
        'recently_played_id_arr': ids,
      },
    );
    if (res is Error) {
      return res;
    }
    return const Success(null);
  }
}
