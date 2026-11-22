import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_rsa.dart';
import 'package:dio/dio.dart';

abstract final class UgreenLoginHttp {
  static Future<LoadingState<UgreenLoginResult>> login({
    required String baseUrl,
    required String username,
    required String password,
    required String clientId,
    String? relayUrl,
    String? alias,
    String? uglinkId,
  }) async {
    final keyRes = await _fetchRsaKey(baseUrl, username, clientId: clientId);
    if (keyRes is Error) {
      return Error(keyRes.errMsg, code: keyRes.code);
    }
    if (keyRes is! Success<String>) {
      return const Error('获取登录公钥失败');
    }
    final encrypted = UgreenRsa.encryptPassword(password, keyRes.response);
    if (encrypted == null) {
      return const Error('设备公钥格式无效');
    }
    final res = await UgreenClient.request(
      baseUrl,
      UgreenApi.verifyLogin,
      method: 'POST',
      clientId: clientId,
      data: {
        'username': username,
        'password': encrypted,
        'keepalive': true,
        'otp': true,
        'is_simple': false,
      },
    );
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('登录失败');
    }
    return _loginResult(
      res.response,
      relayUrl: relayUrl,
      clientId: clientId,
      username: username,
      publicKey: keyRes.response,
      alias: alias,
      uglinkId: uglinkId,
    );
  }

  static Future<LoadingState<UgreenLoginResult>> loginByOtp({
    required String baseUrl,
    required String tokenId,
    required String code,
    required int type,
    required String clientId,
    required String username,
    bool trust = false,
    String? relayUrl,
    String? alias,
    String? uglinkId,
  }) async {
    final res = await UgreenClient.request(
      baseUrl,
      UgreenApi.verifyCodeLogin,
      method: 'POST',
      clientId: clientId,
      data: {
        'code': code,
        'type': type,
        'token_id': tokenId,
        'trust_info': {
          'client_type': 'pc',
          'system': UgreenClient.systemName,
          'dev_name': UgreenClient.deviceName,
        },
        'trust': trust,
      },
    );
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('验证失败，请重试');
    }
    return _loginResult(
      res.response,
      relayUrl: relayUrl,
      clientId: clientId,
      username: username,
      alias: alias,
      uglinkId: uglinkId,
    );
  }

  static Future<LoadingState<void>> sendOtpEmailCode({
    required String baseUrl,
    required String username,
    required String clientId,
  }) async {
    final res = await UgreenClient.request(
      baseUrl,
      UgreenApi.otpMailSendCode,
      method: 'POST',
      clientId: clientId,
      data: {'username': username},
    );
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    return const Success(null);
  }

  static Future<UgreenSession> refreshSession(UgreenSession session) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.userPriorityLink,
    );
    if (res is! Success<Map<String, dynamic>>) {
      return session;
    }
    final data = res.response['data'];
    if (data is! Map) {
      return session;
    }
    final map = data.cast<String, dynamic>();
    final uglink = map['uglink']?.toString();
    final relayUrl = _relayUrl(uglink) ?? session.relayUrl;
    final ipv4 = UgreenClient.toStringList(map['ipv_4'] ?? map['ipv4']);
    final ipv6 = UgreenClient.toStringList(map['ipv_6'] ?? map['ipv6']);
    return session.copyWith(
      uglink: uglink == null || uglink.isEmpty ? null : uglink,
      uglinkId: map['uglink_id']?.toString(),
      relayUrl: relayUrl,
      ipv4: ipv4.isEmpty ? null : ipv4,
      ipv6: ipv6.isEmpty ? null : ipv6,
      httpPort: UgreenClient.toInt(map['http_port']),
      httpsPort: UgreenClient.toInt(map['https_port']),
    );
  }

  static Future<LoadingState<void>> isLogin(UgreenSession session) async {
    final res = await UgreenEndpoint.request(session, UgreenApi.verifyIsLogin);
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('登录校验失败');
    }
    return const Success(null);
  }

  static Future<LoadingState<String>> _fetchRsaKey(
    String baseUrl,
    String username, {
    required String clientId,
  }) async {
    try {
      final response = await UgreenClient.dio.post<dynamic>(
        '$baseUrl/ugreen/${UgreenApi.verifyCheck}',
        data: {'username': username},
        options: Options(
          headers: UgreenClient.headers(clientId),
          contentType: Headers.jsonContentType,
        ),
      );
      final key = response.headers.value('x-rsa-token');
      if (key != null && key.isNotEmpty) {
        return Success(key);
      }
      final json = UgreenClient.asJson(response.data);
      final code = UgreenClient.toInt(json?['code']);
      if (code != null && code != 200) {
        return Error(
          json?['msg']?.toString() ?? '获取登录公钥失败',
          code: code,
        );
      }
      return const Error('设备未返回登录公钥');
    } on DioException catch (e) {
      return Error(UgreenClient.dioError(e));
    }
  }

  static LoadingState<UgreenLoginResult> _loginResult(
    Map<String, dynamic> json, {
    required String clientId,
    required String username,
    required String? relayUrl,
    required String? alias,
    required String? uglinkId,
    String? publicKey,
  }) {
    final data = json['data'] is Map
        ? (json['data'] as Map).cast<String, dynamic>()
        : json;
    final token =
        data['token']?.toString() ?? data['api_token']?.toString() ?? '';
    final enableOtp = UgreenClient.toBool(data['enable_otp']);
    if (token.isEmpty) {
      if (enableOtp) {
        return Success(
          UgreenLoginResult(
            needOtp: true,
            tokenId: data['token_id']?.toString(),
            email: data['urgent_email']?.toString(),
            isExceed: UgreenClient.toBool(data['is_exceed']),
          ),
        );
      }
      return Error(
        json['msg']?.toString() ?? '登录失败',
        code: UgreenClient.toInt(json['code']),
      );
    }
    final staticToken = data['static_token']?.toString() ?? token;
    final uglink = data['uglink']?.toString() ?? '';
    final resolvedRelay = relayUrl ?? _relayUrl(uglink);
    return Success(
      UgreenLoginResult(
        session: UgreenSession(
          token: token,
          staticToken: staticToken.isEmpty ? token : staticToken,
          relayUrl: resolvedRelay,
          uglink: uglink,
          uglinkId: data['uglink_id']?.toString() ?? uglinkId ?? alias ?? '',
          username: data['username']?.toString() ?? username,
          clientId: clientId,
          nasName: data['nas_name']?.toString(),
          publicKey: data['public_key']?.toString() ?? publicKey,
          ipv4: UgreenClient.toStringList(data['ipv4']),
          ipv6: UgreenClient.toStringList(data['ipv6']),
          httpPort: UgreenClient.toInt(data['http_port']),
          httpsPort: UgreenClient.toInt(data['https_port']),
        ),
      ),
    );
  }

  static String? _relayUrl(String? uglink) {
    if (uglink == null || uglink.isEmpty) {
      return null;
    }
    return uglink.startsWith('http') ? uglink : 'https://$uglink';
  }
}
