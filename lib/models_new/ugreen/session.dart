class UgreenSession {
  final String token;
  final String staticToken;
  final String? relayUrl;
  final String uglink;
  final String uglinkId;
  final String username;
  final String clientId;
  final String? nasName;
  final String? publicKey;
  final List<String> ipv4;
  final List<String> ipv6;
  final List<String> hosts;
  final int? httpPort;
  final int? httpsPort;

  const UgreenSession({
    required this.token,
    required this.staticToken,
    required this.username,
    required this.clientId,
    this.relayUrl,
    this.uglink = '',
    this.uglinkId = '',
    this.nasName,
    this.publicKey,
    this.ipv4 = const [],
    this.ipv6 = const [],
    this.hosts = const [],
    this.httpPort,
    this.httpsPort,
  });

  int get port => httpsPort ?? 9443;

  List<String> get localBaseUrls => _unique([
    for (final ip in ipv4) 'https://$ip:$port',
    for (final ip in ipv6) 'https://[$ip]:$port',
    for (final host in hosts) 'https://${_hostForUrl(host)}:$port',
  ]);

  List<String> get endpointCandidates => _unique([
    ...localBaseUrls,
    ?relayBaseUrl,
  ]);

  static String _hostForUrl(String host) {
    return host.contains(':') && !host.startsWith('[') ? '[$host]' : host;
  }

  static List<String> _unique(Iterable<String> values) {
    final result = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }
    return result.toList();
  }

  String? get relayBaseUrl {
    final relay = relayUrl;
    return relay != null && relay.isNotEmpty ? relay : null;
  }

  UgreenSession copyWith({
    String? token,
    String? staticToken,
    String? relayUrl,
    String? uglink,
    String? uglinkId,
    String? username,
    String? clientId,
    String? nasName,
    String? publicKey,
    List<String>? ipv4,
    List<String>? ipv6,
    List<String>? hosts,
    int? httpPort,
    int? httpsPort,
  }) {
    return UgreenSession(
      token: token ?? this.token,
      staticToken: staticToken ?? this.staticToken,
      relayUrl: relayUrl ?? this.relayUrl,
      uglink: uglink ?? this.uglink,
      uglinkId: uglinkId ?? this.uglinkId,
      username: username ?? this.username,
      clientId: clientId ?? this.clientId,
      nasName: nasName ?? this.nasName,
      publicKey: publicKey ?? this.publicKey,
      ipv4: ipv4 ?? this.ipv4,
      ipv6: ipv6 ?? this.ipv6,
      hosts: hosts ?? this.hosts,
      httpPort: httpPort ?? this.httpPort,
      httpsPort: httpsPort ?? this.httpsPort,
    );
  }

  static UgreenSession fromJson(Map<String, dynamic> json) {
    return UgreenSession(
      token: json['token'] as String,
      staticToken: json['staticToken'] as String,
      relayUrl: json['relayUrl'] as String?,
      uglink: json['uglink'] as String,
      uglinkId: json['uglinkId'] as String,
      username: json['username'] as String,
      clientId: json['clientId'] as String,
      nasName: json['nasName'] as String?,
      publicKey: json['publicKey'] as String?,
      ipv4: (json['ipv4'] as List?)?.cast<String>() ?? const [],
      ipv6: (json['ipv6'] as List?)?.cast<String>() ?? const [],
      hosts: (json['hosts'] as List?)?.cast<String>() ?? const [],
      httpPort: json['httpPort'] as int?,
      httpsPort: json['httpsPort'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'token': token,
    'staticToken': staticToken,
    'relayUrl': relayUrl,
    'uglink': uglink,
    'uglinkId': uglinkId,
    'username': username,
    'clientId': clientId,
    'nasName': nasName,
    'publicKey': publicKey,
    'ipv4': ipv4,
    'ipv6': ipv6,
    'hosts': hosts,
    'httpPort': httpPort,
    'httpsPort': httpsPort,
  };
}

class UgreenLoginResult {
  final UgreenSession? session;
  final bool needOtp;
  final String? tokenId;
  final String? email;
  final bool isExceed;

  const UgreenLoginResult({
    this.session,
    this.needOtp = false,
    this.tokenId,
    this.email,
    this.isExceed = false,
  });
}
