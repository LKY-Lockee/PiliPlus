import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/detail.dart';
import 'package:PiliPlus/models_new/ugreen/related.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/models_new/ugreen/transcode.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';

abstract final class UgreenVideoHttp {
  static Future<LoadingState<UgreenMovieDetail>> movieDetail(
    UgreenSession session, {
    required int id,
    required int mediaLibSetId,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoMovieDetail,
      query: {
        'id': id,
        'media_lib_set_id': mediaLibSetId,
        'fileVersion': true,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenMovieDetail.fromJson(_data(res.response)));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<UgreenTvDetail>> tvDetail(
    UgreenSession session, {
    required int ugVideoInfoId,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoTvDetail,
      query: {'ug_video_info_id': ugVideoInfoId},
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenTvDetail.fromJson(_data(res.response)));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<List<UgreenRelatedVideo>>> relatedRecommendation(
    UgreenSession session, {
    required int ugVideoInfoId,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.videoRelatedRecommendation,
      query: {'ug_video_info_id': ugVideoInfoId},
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    final data = res.response['data'];
    if (data is! Map) {
      return const Error('加载失败');
    }
    try {
      final items = data['related_recommendation_arr'];
      if (items is! List) {
        return const Success([]);
      }
      return Success(
        items
            .whereType<Map>()
            .map(
              (e) => UgreenRelatedVideo.fromJson(e.cast<String, dynamic>()),
            )
            .toList(),
      );
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<UgreenTranscodeInfo>> transcodeInfo(
    UgreenSession session, {
    required String videoPath,
    required String taskId,
    required String timestamp,
    int srcType = 2,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.transcodeInfo,
      method: 'POST',
      data: {
        'video_path': videoPath,
        'is_net_disk_direct': true,
        'task_id': taskId,
        'timestamp': timestamp,
        'src_type': srcType,
      },
    );
    if (res is Error) {
      return res;
    }
    if (res is! Success<Map<String, dynamic>>) {
      return const Error('加载失败');
    }
    try {
      return Success(UgreenTranscodeInfo.fromJson(_data(res.response)));
    } catch (e) {
      return Error('解析失败: $e');
    }
  }

  static Future<LoadingState<void>> play(
    UgreenSession session, {
    required String m3u8File,
    required String taskId,
    required String timestamp,
    required int srcType,
    int subtitleIndex = -1,
    int? audioIndex,
    bool preferH265 = false,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.transcodePlay,
      query: {
        'm3u8_file': m3u8File,
        'regen': 1,
        'subtitle_index': subtitleIndex,
        'audio_index': ?audioIndex,
        'prefer_h265': preferH265,
        'task_id': taskId,
        'timestamp': timestamp,
        'src_type': srcType,
      },
    );
    if (res is Error) {
      return res;
    }
    return const Success(null);
  }

  static String m3u8Url(
    String baseUrl, {
    required String m3u8File,
    required String taskId,
    required String timestamp,
    required int srcType,
    required String token,
  }) {
    final uri = Uri.parse('$baseUrl/ugreen/${UgreenApi.transcodeM3u8}');
    return uri
        .replace(
          queryParameters: {
            'm3u8_file': m3u8File,
            'task_id': taskId,
            'timestamp': timestamp,
            'src_type': '$srcType',
            'token': token,
          },
        )
        .toString();
  }

  static Future<LoadingState<void>> reportProgress(
    UgreenSession session, {
    required Map<String, dynamic> recentlyPlayed,
  }) async {
    final res = await UgreenEndpoint.request(
      session,
      UgreenApi.recentlyPlayedCreate,
      method: 'POST',
      query: {'app_name': 'web'},
      data: {'recently_played': recentlyPlayed},
    );
    if (res is Error) {
      return res;
    }
    return const Success(null);
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    return response['data'];
  }
}
