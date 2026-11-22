import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';

abstract final class UgreenApi {
  // 设备相对路径（拼接为 $baseUrl/ugreen/$path）
  static const String verifyRunning = 'v1/verify/is_running';
  static const String verifyCheck = 'v1/verify/check';
  static const String verifyLogin = 'v1/verify/login';
  static const String verifyCodeLogin = 'v1/verify/code/login';
  static const String verifyIsLogin = 'v1/verify/is_login';
  static const String otpMailSendCode = 'v1/otp/mail/send/code';
  static const String userPriorityLink = 'v1/user/priority_link';

  static const String videoHomepage = 'v2/video/homepage';
  static const String folderList = 'v1/video/poster_wall/media_lib/get_folder';
  static const String mediaList = 'v1/video/homepage/media_list';
  static const String videoAll = 'v1/video/all';
  static const String videoSearch = 'v2/video/search';
  static const String videoMovieDetail = 'v1/video/details/getMovie';
  static const String videoTvDetail = 'v2/video/details/getTV';
  static const String recentlyPlayedGet = 'v1/video/recently_played/get';
  static const String recentlyPlayedCreate = 'v1/video/recently_played/create';
  static const String recentlyPlayedDelete = 'v1/video/recently_played/delete';
  static const String collectGet = 'v1/video/collect/get';
  static const String collectCreate = 'v1/video/collect/create';
  static const String collectDelete = 'v1/video/collect/delete';
  static const String imageStream = 'v2/video/getImaStream';
  static const String transcodeInfo = 'v2/stream/transcode/web/info';
  static const String transcodePlay = 'v2/stream/transcode/web/play';
  static const String transcodeM3u8 = 'v2/stream/transcode/web/m3u8';

  // 云端接口
  static const String nodeInfoByAlias =
      '${UgreenHttpString.cloudBaseUrl}/p2p/v2/ta/nodeInfo/byAlias';
  static const String createQrCode =
      '${UgreenHttpString.cloudBaseUrl}/user/v3/sa/create/qrCode';
  static const String oauthToken =
      '${UgreenHttpString.cloudBaseUrl}/oauth/token';
}
