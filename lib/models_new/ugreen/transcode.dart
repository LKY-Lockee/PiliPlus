import 'package:collection/collection.dart';

class UgreenSegmentInfo {
  final int segmentDuration;
  final int totalSegment;

  const UgreenSegmentInfo({
    required this.segmentDuration,
    required this.totalSegment,
  });

  static UgreenSegmentInfo fromJson(Map<String, dynamic> json) {
    return UgreenSegmentInfo(
      segmentDuration: json['segment_duration'] as int,
      totalSegment: json['total_segment'] as int,
    );
  }
}

class UgreenTranscodeInfo {
  final List<UgreenAudioTrack> audios;
  final int duration;
  final num framerate;
  final String hash;
  final bool hdr10;
  final int height;
  final bool isHwAccelSupport;
  final bool isTranscode;
  final bool supportLossless;
  final String redirLink;
  final String codecId;
  final UgreenResolution resolution;
  final String rotation;
  final UgreenSegmentInfo segment;
  final List<UgreenSubtitleTrack> subtitles;
  final List<UgreenTranscodableResolution> transcodeable;
  final int width;
  final bool isCloudPath;

  Duration get durationValue => Duration(milliseconds: duration);

  UgreenAudioTrack? get defaultAudio => audios.firstOrNull;

  UgreenSubtitleTrack? get defaultSubtitle => subtitles.firstOrNull;

  const UgreenTranscodeInfo({
    required this.audios,
    required this.duration,
    required this.framerate,
    required this.hash,
    required this.hdr10,
    required this.height,
    required this.isHwAccelSupport,
    required this.isTranscode,
    required this.supportLossless,
    required this.redirLink,
    required this.codecId,
    required this.resolution,
    required this.rotation,
    required this.segment,
    required this.subtitles,
    required this.transcodeable,
    required this.width,
    required this.isCloudPath,
  });

  static UgreenTranscodeInfo fromJson(Map<String, dynamic> json) {
    return UgreenTranscodeInfo(
      hash: json['hash'] as String,
      redirLink: json['redir_link'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      codecId: json['codec_id'] as String,
      hdr10: json['hdr10'] as bool,
      framerate: json['framerate'] as num,
      duration: json['duration'] as int,
      rotation: json['rotation'] as String,
      resolution: UgreenResolution.fromJson(json['resolution']),
      segment: UgreenSegmentInfo.fromJson(json['segment']),
      audios: (json['audios'] as List)
          .whereType<Map>()
          .map((e) => UgreenAudioTrack.fromJson(e.cast()))
          .whereType<UgreenAudioTrack>()
          .toList(),
      subtitles:
          (json['subtitles'] as List?)
              ?.whereType<Map>()
              .map((e) => UgreenSubtitleTrack.fromJson(e.cast()))
              .whereType<UgreenSubtitleTrack>()
              .toList() ??
          [],
      transcodeable: (json['transcodeable'] as List)
          .whereType<Map>()
          .map((e) => UgreenTranscodableResolution.fromJson(e.cast()))
          .whereType<UgreenTranscodableResolution>()
          .toList(),
      isHwAccelSupport: json['is_hw_accel_support'] as bool,
      supportLossless: json['support_lossless'] as bool,
      isTranscode: json['is_transcode'] as bool,
      isCloudPath: json['is_cloud_path'] as bool,
    );
  }
}

class UgreenResolution {
  final String name;
  final String cname;

  const UgreenResolution({
    required this.name,
    required this.cname,
  });

  static UgreenResolution fromJson(Map<String, dynamic> json) {
    return UgreenResolution(
      name: json['name'] as String,
      cname: json['cname'] as String,
    );
  }
}

class UgreenTranscodableResolution {
  final String name;
  final String cname;
  final String resolution;

  const UgreenTranscodableResolution({
    required this.name,
    required this.cname,
    required this.resolution,
  });

  static UgreenTranscodableResolution fromJson(Map<String, dynamic> json) {
    return UgreenTranscodableResolution(
      name: json['name'] as String,
      cname: json['cname'] as String,
      resolution: json['resolution'] as String,
    );
  }
}

class UgreenAudioTrack {
  final int id;
  final String language;
  final String rawLanguage;
  final String name;
  final String title;
  final bool isDefault;

  const UgreenAudioTrack({
    required this.id,
    required this.language,
    required this.rawLanguage,
    required this.name,
    required this.title,
    required this.isDefault,
  });

  static UgreenAudioTrack fromJson(Map<String, dynamic> json) {
    return UgreenAudioTrack(
      id: json['id'] as int,
      language: json['language'] as String,
      rawLanguage: json['raw_language'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }
}

class UgreenSubtitleTrack {
  final int id;
  final bool isText;
  final String language;
  final String rawLanguage;
  final String name;
  final String title;
  final bool isDefault;

  const UgreenSubtitleTrack({
    required this.id,
    required this.isText,
    required this.language,
    required this.rawLanguage,
    required this.name,
    required this.title,
    required this.isDefault,
  });

  static UgreenSubtitleTrack fromJson(Map<String, dynamic> json) {
    return UgreenSubtitleTrack(
      id: json['id'] as int,
      isText: json['is_text'] as bool,
      language: json['language'] as String,
      rawLanguage: json['raw_language'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }
}
