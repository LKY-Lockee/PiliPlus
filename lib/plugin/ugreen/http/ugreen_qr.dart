import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/qr.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:dio/dio.dart';

abstract final class UgreenQrHttp {
  static Future<LoadingState<UgreenQrCode>> createQrCode({
    required String publicKey,
    required String bid,
    required String alias,
    required String osVer,
  }) async {
    try {
      final response = await UgreenClient.dio.post<dynamic>(
        UgreenApi.createQrCode,
        data: {
          'qrType': 'LOCAL_LOGIN',
          'clientType': 'Windows',
          'alias': alias,
          'platform': 'Windows',
          'model': 'Windows',
          'bid': bid,
          'ak': UgreenHttpString.qrAk,
          'public_key': publicKey,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      final json = UgreenClient.asJson(response.data);
      if (json == null) {
        return const Error('扫码服务返回异常');
      }
      final code = UgreenClient.toInt(json['code']);
      if (code != 200) {
        return Error(
          json['msg']?.toString() ?? '创建二维码失败',
          code: code,
        );
      }
      final data = json['data'];
      if (data is! Map) {
        return const Error('创建二维码失败：返回数据异常');
      }
      final map = data.cast<String, dynamic>();
      final qrCode = map['qrCode']?.toString() ?? '';
      final url = map['url']?.toString() ?? '';
      if (qrCode.isEmpty || url.isEmpty) {
        return const Error('创建二维码失败：二维码数据为空');
      }
      return Success(UgreenQrCode(qrCode: qrCode, url: url));
    } on DioException catch (e) {
      return Error(UgreenClient.dioError(e));
    }
  }

  static Future<LoadingState<UgreenQrPollResult>> pollQrCode({
    required String qrCode,
    required String bid,
    required String alias,
    required String osVer,
  }) async {
    try {
      final response = await UgreenClient.dio.post<dynamic>(
        UgreenApi.oauthToken,
        data: FormData.fromMap({
          'qrcode': qrCode,
          'grant_type': 'qrcode',
          'platform': 'Windows',
          'clientType': 'Windows',
          'osVer': osVer,
          'model': 'Windows',
          'bid': bid,
          'alias': alias,
        }),
      );
      final json = UgreenClient.asJson(response.data);
      if (json == null) {
        return const Error('扫码服务返回异常');
      }
      final code = UgreenClient.toInt(json['code']);
      switch (code) {
        case 200:
          final data = json['data'];
          final user = data is Map ? data['user'] : null;
          final raw = user is Map ? user['linkParams'] : null;
          final map = raw is String && raw.isNotEmpty
              ? UgreenClient.asJson(raw)
              : raw is Map
              ? raw.cast<String, dynamic>()
              : null;
          if (map == null) {
            return const Error('扫码结果解析失败');
          }
          return Success(
            UgreenQrPollResult(
              status: UgreenQrStatus.success,
              linkParams: map,
            ),
          );
        case 81520:
          return const Success(
            UgreenQrPollResult(status: UgreenQrStatus.waiting),
          );
        case 81308:
          return const Success(
            UgreenQrPollResult(status: UgreenQrStatus.scanned),
          );
        case 8058:
          return const Success(
            UgreenQrPollResult(status: UgreenQrStatus.expired),
          );
        case 81604:
          return Success(
            UgreenQrPollResult(
              status: UgreenQrStatus.rejected,
              message: json['msg']?.toString(),
              code: code,
            ),
          );
        default:
          return Success(
            UgreenQrPollResult(
              status: UgreenQrStatus.failed,
              message: json['msg']?.toString() ?? '扫码登录失败',
              code: code,
            ),
          );
      }
    } on DioException catch (e) {
      return Error(UgreenClient.dioError(e));
    }
  }
}
