import 'dart:isolate';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/node.dart';
import 'package:PiliPlus/models_new/ugreen/qr.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_address.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_login.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_qr.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_rsa.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:pointycastle/export.dart' as pc;

class UgreenLoginFlow {
  UgreenLoginFlow(this._service);

  final UgreenService _service;

  String? _pendingBaseUrl;
  String? _pendingRelayUrl;
  String? _pendingAlias;
  String? _pendingUglinkId;
  String? _pendingUsername;
  List<String> _pendingIpv4 = const [];
  List<String> _pendingIpv6 = const [];
  List<String> _pendingHosts = const [];
  int? _pendingHttpPort;
  int? _pendingHttpsPort;

  pc.RSAPrivateKey? _qrPrivateKey;
  String? _qrCode;

  Future<LoadingState<UgreenLoginResult>> signIn({
    required String address,
    required String username,
    required String password,
  }) async {
    _clearPending();
    final nodeRes = await UgreenAddressHttp.resolveAddress(
      address,
      clientId: _service.clientId,
    );
    if (nodeRes is Error) {
      return Error(nodeRes.errMsg, code: nodeRes.code);
    }
    if (nodeRes is! Success<UgreenResolvedNode>) {
      return const Error('解析设备地址失败');
    }
    final node = nodeRes.response;
    final res = await UgreenLoginHttp.login(
      baseUrl: node.baseUrl,
      username: username,
      password: password,
      clientId: _service.clientId,
      relayUrl: node.relayUrl,
      alias: node.alias,
      uglinkId: node.uglinkId,
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<UgreenLoginResult>) {
      return const Error('登录失败');
    }
    Pref.setUgreenAddress = address.trim();
    final result = res.response;
    if (result.needOtp) {
      _pendingBaseUrl = node.baseUrl;
      _pendingRelayUrl = node.relayUrl;
      _pendingAlias = node.alias;
      _pendingUglinkId = node.uglinkId;
      _pendingUsername = username;
      _pendingIpv4 = node.ipv4;
      _pendingIpv6 = node.ipv6;
      _pendingHosts = node.hosts;
      _pendingHttpPort = node.httpPort;
      _pendingHttpsPort = node.httpsPort;
      return Success(result);
    }
    final session = result.session;
    if (session == null) {
      return const Error('登录失败');
    }
    await _service.saveSession(
      _mergeNodeInfo(
        session,
        ipv4: node.ipv4,
        ipv6: node.ipv6,
        hosts: node.hosts,
        httpPort: node.httpPort,
        httpsPort: node.httpsPort,
      ),
    );
    return Success(result);
  }

  Future<LoadingState<UgreenLoginResult>> submitOtp({
    required String tokenId,
    required String code,
    required int type,
    bool trust = false,
  }) async {
    final baseUrl = _pendingBaseUrl;
    final username = _pendingUsername;
    if (baseUrl == null || username == null) {
      return const Error('登录状态已失效，请重新登录');
    }
    final res = await UgreenLoginHttp.loginByOtp(
      baseUrl: baseUrl,
      tokenId: tokenId,
      code: code,
      type: type,
      clientId: _service.clientId,
      username: username,
      trust: trust,
      relayUrl: _pendingRelayUrl,
      alias: _pendingAlias,
      uglinkId: _pendingUglinkId,
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<UgreenLoginResult>) {
      return const Error('验证失败，请重试');
    }
    final result = res.response;
    final session = result.session;
    if (session == null) {
      if (result.needOtp) {
        return Success(result);
      }
      return const Error('验证失败，请重试');
    }
    await _service.saveSession(
      _mergeNodeInfo(
        session,
        ipv4: _pendingIpv4,
        ipv6: _pendingIpv6,
        hosts: _pendingHosts,
        httpPort: _pendingHttpPort,
        httpsPort: _pendingHttpsPort,
      ),
    );
    return Success(result);
  }

  Future<LoadingState<void>> sendOtpEmailCode() async {
    final baseUrl = _pendingBaseUrl;
    final username = _pendingUsername;
    if (baseUrl == null || username == null) {
      return const Error('登录状态已失效，请重新登录');
    }
    return UgreenLoginHttp.sendOtpEmailCode(
      baseUrl: baseUrl,
      username: username,
      clientId: _service.clientId,
    );
  }

  Future<LoadingState<UgreenQrCode>> beginQrLogin() async {
    try {
      final pair = await Isolate.run(UgreenRsa.generateKeyPair);
      final res = await UgreenQrHttp.createQrCode(
        publicKey: UgreenRsa.publicKeyPem(pair.publicKey),
        bid: _service.qrBid,
        alias: UgreenClient.deviceAlias,
        osVer: UgreenClient.deviceOsVersion,
      );
      if (res is Error) {
        return Error(res.errMsg, code: res.code);
      }
      if (res is! Success<UgreenQrCode>) {
        return const Error('创建二维码失败');
      }
      _qrPrivateKey = pair.privateKey;
      _qrCode = res.response.qrCode;
      return Success(res.response);
    } catch (e) {
      return Error('生成二维码失败: $e');
    }
  }

  Future<LoadingState<UgreenQrPollResult>> pollQrLogin() async {
    final qrCode = _qrCode;
    final privateKey = _qrPrivateKey;
    if (qrCode == null || privateKey == null) {
      return const Error('二维码已失效，请刷新');
    }
    final res = await UgreenQrHttp.pollQrCode(
      qrCode: qrCode,
      bid: _service.qrBid,
      alias: UgreenClient.deviceAlias,
      osVer: UgreenClient.deviceOsVersion,
    );
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    if (res is! Success<UgreenQrPollResult>) {
      return const Error('扫码登录失败');
    }
    final result = res.response;
    if (result.status != UgreenQrStatus.success) {
      return Success(result);
    }
    final params = result.linkParams!;
    var token = params['token']?.toString() ?? '';
    if (_isTrue(params['token_safe']) && token.isNotEmpty) {
      final decrypted = UgreenRsa.decryptToken(token, privateKey);
      if (decrypted == null) {
        return const Error('扫码登录失败：token 解密失败');
      }
      token = decrypted;
    }
    if (token.isEmpty) {
      return const Error('扫码登录失败：未获取到 token');
    }
    final uglink = params['uglink']?.toString() ?? '';
    final relayUrl = uglink.isEmpty
        ? null
        : uglink.startsWith('http')
        ? uglink
        : 'https://$uglink';
    final ipv4 = _toStringList(params['ipv4']);
    final ipv6 = _toStringList(params['ipv6']);
    final httpPort = int.tryParse(params['http_port']?.toString() ?? '');
    final httpsPort = int.tryParse(params['https_port']?.toString() ?? '');
    if (relayUrl == null && ipv4.isEmpty && ipv6.isEmpty) {
      return const Error('扫码登录失败：未获取到设备地址');
    }
    final session = UgreenSession(
      token: token,
      staticToken: params['static_token']?.toString() ?? token,
      relayUrl: relayUrl,
      uglink: uglink,
      uglinkId: params['uglink_id']?.toString() ?? '',
      username: params['username']?.toString() ?? '',
      clientId: _service.clientId,
      nasName: params['nas_name']?.toString(),
      publicKey: params['public_key']?.toString(),
      ipv4: ipv4,
      ipv6: ipv6,
      httpPort: httpPort,
      httpsPort: httpsPort,
    );
    final loginRes = await UgreenLoginHttp.isLogin(session);
    if (loginRes is Error) {
      return Error(loginRes.errMsg, code: loginRes.code);
    }
    await _service.saveSession(session);
    cancelQrLogin();
    return Success(result);
  }

  void cancelQrLogin() {
    _qrPrivateKey = null;
    _qrCode = null;
  }

  void dispose() {
    cancelQrLogin();
    _clearPending();
  }

  void _clearPending() {
    _pendingBaseUrl = null;
    _pendingRelayUrl = null;
    _pendingAlias = null;
    _pendingUglinkId = null;
    _pendingUsername = null;
    _pendingIpv4 = const [];
    _pendingIpv6 = const [];
    _pendingHosts = const [];
    _pendingHttpPort = null;
    _pendingHttpsPort = null;
  }

  static UgreenSession _mergeNodeInfo(
    UgreenSession session, {
    required List<String> ipv4,
    required List<String> ipv6,
    required List<String> hosts,
    required int? httpPort,
    required int? httpsPort,
  }) {
    return session.copyWith(
      ipv4: session.ipv4.isEmpty && ipv4.isNotEmpty ? ipv4 : null,
      ipv6: session.ipv6.isEmpty && ipv6.isNotEmpty ? ipv6 : null,
      hosts: session.hosts.isEmpty && hosts.isNotEmpty ? hosts : null,
      httpPort: session.httpPort ?? httpPort,
      httpsPort: session.httpsPort ?? httpsPort,
    );
  }

  static bool _isTrue(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true';
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final str = value?.toString();
    return str == null || str.isEmpty ? const [] : [str];
  }
}
