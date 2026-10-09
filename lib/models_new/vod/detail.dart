import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';

/// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo.InfoBean
class VodEpisode {
  /// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo.InfoBean.name
  final String name;

  /// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo.InfoBean.url
  final String url;

  const VodEpisode({required this.name, required this.url});
}

/// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo
class VodPlayGroup {
  /// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo.flag
  final String flag;

  /// com.github.tvbox.osc.bean.Movie.Video.UrlBean.UrlInfo.beanList
  final List<VodEpisode> episodes;

  const VodPlayGroup({required this.flag, required this.episodes});
}

/// com.github.tvbox.osc.bean.VodInfo
class VodInfoModel {
  // .. com.github.tvbox.osc.bean.Movie.Video
  final VodVideo video;

  /// com.github.tvbox.osc.bean.Movie.Video.UrlBean.infoList
  final List<VodPlayGroup> playFlags;

  const VodInfoModel({required this.video, required this.playFlags});

  /// com.github.tvbox.osc.bean.VodInfo.setVideo
  static VodInfoModel? fromJson(Map<String, dynamic> vod) {
    final video = VodVideo.fromJson(vod);
    if (video == null) {
      return null;
    }
    return VodInfoModel(
      video: video,
      playFlags: SourceViewModel.parsePlayUrls(
        vod['vod_play_from']?.toString(),
        vod['vod_play_url']?.toString(),
      ),
    );
  }
}
