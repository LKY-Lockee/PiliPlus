import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/plugin/tvbox/catvod/net/dns.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// com.github.tvbox.osc.util.OkGoHelper
class TVBoxHttpHelper {
  TVBoxHttpHelper._();

  /// com.github.tvbox.osc.util.OkGoHelper.init
  static Future<void> init() async {
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'user-agent': Pref.vodUA},
      responseDecoder: (responseBytes, options, responseBody) => utf8.decode(
        responseBytes,
        allowMalformed: true,
      ),
      persistentConnection: true,
    );

    Http.client = Dio(options)
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => HttpClient()
          ..idleTimeout = const Duration(seconds: 15)
          ..badCertificateCallback = ((cert, host, port) => true)
          ..connectionFactory = Dns.connect,
      )
      ..options.validateStatus = (status) => status != null;
  }

  static void updateUserAgent(String userAgent) {
    Http.client.options.headers['user-agent'] = userAgent;
  }

  /// com.github.tvbox.osc.util.OkGoHelper.setDnsList
  static void setDnsList(Map<String, String> hosts) {
    Dns.addAll(hosts);
  }
}
