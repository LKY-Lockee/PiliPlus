import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_ugreen/data.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenFavHttp {
  static Future<LoadingState<FavUgreenData>> favoriteVideos(
    UgreenSession session, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.collectGet,
      query: {
        'page': page,
        'page_size': pageSize,
        'language': UgreenHttpString.language,
        'create_time_order': false,
        'video_type': 0,
        'sort_type': 0,
        'order_type': 2,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(
        FavUgreenData.fromJson((res.response['data'] as Map).cast()),
      );
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<void>> addFavorite(
    UgreenSession session, {
    required String categoryId,
    required int ugVideoInfoId,
    required int type,
    int? mediaLibSetId,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.collectCreate,
      method: 'POST',
      data: {
        'ids': [
          {
            'category_id': categoryId,
            'ug_video_info_id': ugVideoInfoId,
            'type': type,
          },
        ],
        if (mediaLibSetId != null && mediaLibSetId > 0)
          'media_lib_set_id': mediaLibSetId,
      },
    );
    if (res is Error) {
      return res;
    }
    return const Success(null);
  }

  static Future<LoadingState<void>> deleteFavorite(
    UgreenSession session, {
    required String categoryId,
    required int mediaLibSetId,
    required int type,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.collectDelete,
      method: 'POST',
      data: {
        'ids': [categoryId],
        'media_lib_set_id': mediaLibSetId,
        'type': type,
      },
    );
    if (res is Error) {
      return res;
    }
    return const Success(null);
  }
}
