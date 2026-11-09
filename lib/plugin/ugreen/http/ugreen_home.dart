import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/home.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenHomeHttp {
  static Future<LoadingState<UgreenHomeData>> homepage(
    UgreenSession session,
  ) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoHomepage,
      query: {'language': UgreenHttpString.language},
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(
        UgreenHomeData.fromJson((res.response['data'] as Map).cast()),
      );
    } catch (e) {
      return Error('解析失败: $e');
    }
  }
}
