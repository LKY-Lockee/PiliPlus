class UgreenResolvedNode {
  final String baseUrl;
  final String? relayUrl;
  final String alias;
  final String uglinkId;
  final List<String> candidates;
  final List<String> ipv4;
  final List<String> ipv6;
  final List<String> hosts;
  final int? httpPort;
  final int? httpsPort;

  const UgreenResolvedNode({
    required this.baseUrl,
    this.relayUrl,
    this.alias = '',
    this.uglinkId = '',
    this.candidates = const [],
    this.ipv4 = const [],
    this.ipv6 = const [],
    this.hosts = const [],
    this.httpPort,
    this.httpsPort,
  });

  UgreenResolvedNode copyWith({
    String? baseUrl,
    String? relayUrl,
  }) {
    return UgreenResolvedNode(
      baseUrl: baseUrl ?? this.baseUrl,
      relayUrl: relayUrl ?? this.relayUrl,
      alias: alias,
      uglinkId: uglinkId,
      candidates: candidates,
      ipv4: ipv4,
      ipv6: ipv6,
      hosts: hosts,
      httpPort: httpPort,
      httpsPort: httpsPort,
    );
  }
}
