import 'dart:math';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_address.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_login.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:get/get.dart';
import 'package:uuid/v4.dart';

class UgreenService extends GetxService {
  static const _sessionKey = 'session';
  static const _clientIdKey = 'clientId';
  static const _qrBidKey = 'qrBid';

  static UgreenService get to => Get.find();

  final Rx<UgreenSession?> session = Rx<UgreenSession?>(null);

  late String _clientId;
  String? _qrBid;

  String get clientId => _clientId;

  String get qrBid {
    final cached = _qrBid ?? GStorage.ugreen.get(_qrBidKey)?.toString();
    if (cached != null && cached.isNotEmpty) {
      _qrBid = cached;
      return cached;
    }
    final value = const UuidV4().generate();
    GStorage.ugreen.put(_qrBidKey, value);
    _qrBid = value;
    return value;
  }

  bool get isLogin => session.value?.token.isNotEmpty == true;

  @override
  void onInit() {
    super.onInit();
    _clientId = _loadClientId();
    final raw = GStorage.ugreen.get(_sessionKey);
    if (raw is Map) {
      session.value = UgreenSession.fromJson(raw.cast<String, dynamic>());
    }
  }

  String _loadClientId() {
    final cached = GStorage.ugreen.get(_clientIdKey)?.toString();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final random = Random.secure();
    final value = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    GStorage.ugreen.put(_clientIdKey, value);
    return value;
  }

  Future<void> saveSession(UgreenSession value) async {
    var session = value;
    try {
      session = await UgreenLoginHttp.refreshSession(session);
    } catch (_) {}
    UgreenEndpoint.invalidate();
    await UgreenEndpoint.resolve(session);
    await _storeSession(session);
  }

  Future<void> _storeSession(UgreenSession value) async {
    await GStorage.ugreen.put(_sessionKey, value.toMap());
    session.value = value;
  }

  Future<LoadingState<bool>> checkSession() async {
    final old = session.value;
    if (old == null) {
      return const Success(false);
    }
    var current = old;
    try {
      current = await UgreenLoginHttp.refreshSession(current);
    } catch (_) {}
    UgreenEndpoint.invalidate();
    var base = await UgreenEndpoint.resolve(current);
    if (base == null && current.uglinkId.isNotEmpty) {
      final nodeRes = await UgreenAddressHttp.resolveAddress(
        current.uglinkId,
        clientId: _clientId,
      );
      if (nodeRes case Success(:final response)) {
        current = current.copyWith(
          ipv4: current.ipv4.isEmpty && response.ipv4.isNotEmpty
              ? response.ipv4
              : null,
          ipv6: current.ipv6.isEmpty && response.ipv6.isNotEmpty
              ? response.ipv6
              : null,
          hosts: current.hosts.isEmpty && response.hosts.isNotEmpty
              ? response.hosts
              : null,
          relayUrl: response.relayUrl ?? current.relayUrl,
          httpPort: current.httpPort ?? response.httpPort,
          httpsPort: current.httpsPort ?? response.httpsPort,
        );
        UgreenEndpoint.invalidate();
        base = await UgreenEndpoint.resolve(current);
      } else if (nodeRes is Error) {
        return Error(nodeRes.errMsg, code: nodeRes.code);
      }
    }
    if (base == null) {
      return const Error('无法连接设备');
    }
    final loginRes = await UgreenLoginHttp.isLogin(current);
    if (loginRes is Error) {
      if (loginRes.code == 1024) {
        await logout();
        return const Success(false);
      }
      return Error(loginRes.errMsg, code: loginRes.code);
    }
    if (_sessionChanged(old, current)) {
      await _storeSession(current);
    }
    return const Success(true);
  }

  Future<void> logout() async {
    UgreenEndpoint.invalidate();
    await GStorage.ugreen.delete(_sessionKey);
    session.value = null;
  }

  static bool _sessionChanged(UgreenSession a, UgreenSession b) {
    return a.token != b.token ||
        a.staticToken != b.staticToken ||
        a.relayUrl != b.relayUrl ||
        a.uglink != b.uglink ||
        a.uglinkId != b.uglinkId ||
        a.username != b.username ||
        a.clientId != b.clientId ||
        a.nasName != b.nasName ||
        a.publicKey != b.publicKey ||
        !listEquals(a.ipv4, b.ipv4) ||
        !listEquals(a.ipv6, b.ipv6) ||
        !listEquals(a.hosts, b.hosts) ||
        a.httpPort != b.httpPort ||
        a.httpsPort != b.httpsPort;
  }
}
