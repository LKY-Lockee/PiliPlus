class UgreenMediaLibData {
  final List<UgreenMediaLibInfo> mediaLibInfoList;

  const UgreenMediaLibData({
    this.mediaLibInfoList = const [],
  });

  static UgreenMediaLibData fromJson(Map<String, dynamic> json) {
    return UgreenMediaLibData(
      mediaLibInfoList:
          (json['media_lib_info_list'] as List?)
              ?.whereType<Map>()
              .map((e) => UgreenMediaLibInfo.fromJson(e.cast()))
              .whereType<UgreenMediaLibInfo>()
              .toList() ??
          const [],
    );
  }
}

class UgreenMediaLibInfo {
  final int mediaLibSetId;
  final String mediaName;
  final List<String> posterPaths;
  final List<String> backdropPaths;
  final int videoCount;
  final int orderSn;
  final String customCover;

  const UgreenMediaLibInfo({
    required this.mediaLibSetId,
    required this.mediaName,
    required this.posterPaths,
    required this.backdropPaths,
    required this.videoCount,
    required this.orderSn,
    required this.customCover,
  });

  static UgreenMediaLibInfo fromJson(Map<String, dynamic> json) {
    return UgreenMediaLibInfo(
      mediaLibSetId: json['media_lib_set_id'] as int,
      mediaName: json['media_name'] as String,
      posterPaths: (json['poster_paths'] as List?)?.cast() ?? const [],
      backdropPaths: (json['backdrop_paths'] as List?)?.cast() ?? const [],
      videoCount: json['video_count'] as int,
      orderSn: json['order_sn'] as int,
      customCover: json['custom_cover'] as String,
    );
  }
}
