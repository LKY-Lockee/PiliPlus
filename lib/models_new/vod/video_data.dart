import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

/// com.github.tvbox.osc.bean.Movie.Video
class VodVideo {
  /// com.github.tvbox.osc.bean.Movie.Video.sourceKey
  String sourceKey = '';

  /// com.github.tvbox.osc.bean.Movie.Video.id
  final String id;

  /// com.github.tvbox.osc.bean.Movie.Video.name
  final String title;

  /// com.github.tvbox.osc.bean.Movie.Video.pic
  final String? cover;

  /// com.github.tvbox.osc.bean.Movie.Video.note
  final String? remarks;

  /// com.github.tvbox.osc.bean.Movie.Video.type
  final String? type;

  /// com.github.tvbox.osc.bean.Movie.Video.year
  final String? year;

  /// com.github.tvbox.osc.bean.Movie.Video.area
  final String? area;

  /// com.github.tvbox.osc.bean.Movie.Video.lang
  final String? lang;

  /// com.github.tvbox.osc.bean.Movie.Video.actor
  final String? actor;

  /// com.github.tvbox.osc.bean.Movie.Video.director
  final String? director;

  /// com.github.tvbox.osc.bean.Movie.Video.des
  final String? description;

  /// com.github.tvbox.osc.bean.AbsJson.AbsJsonVod.vod_score
  /// com.github.tvbox.osc.bean.AbsJson.AbsJsonVod.vod_douban_score
  final String? score;

  VodVideo({
    required this.id,
    required this.title,
    this.cover,
    this.remarks,
    this.type,
    this.year,
    this.area,
    this.lang,
    this.actor,
    this.director,
    this.description,
    this.score,
  });

  /// com.github.tvbox.osc.bean.AbsJson.AbsJsonVod.toXmlVideo
  static VodVideo? fromJson(Map<String, dynamic> vod) {
    final id = vod['vod_id'];
    final name = vod['vod_name'];
    if (id == null || name == null) {
      return null;
    }
    return VodVideo(
      id: id.toString(),
      title: name.toString(),
      cover: _fixCover(vod['vod_pic'] as String?),
      remarks: vod['vod_remarks']?.toString(),
      type: vod['type_name']?.toString(),
      year: vod['vod_year']?.toString(),
      area: vod['vod_area']?.toString(),
      lang: vod['vod_lang']?.toString(),
      actor: vod['vod_actor']?.toString(),
      director: vod['vod_director']?.toString(),
      description: _stripHtml(vod['vod_content'] as String?),
      score: _fixScore(vod['vod_score'] ?? vod['vod_douban_score']),
    );
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.xml
  static VodVideo? fromXml(XmlElement video) {
    String? tag(String name) =>
        video.findElements(name).firstOrNull?.innerText.trim();
    final id = tag('id');
    final name = tag('name');
    if (id == null || id.isEmpty || name == null) {
      return null;
    }
    return VodVideo(
      id: id,
      title: name,
      cover: _fixCover(tag('pic')),
      remarks: tag('note'),
      type: tag('type'),
      year: tag('year'),
      area: tag('area'),
      lang: tag('lang'),
      actor: tag('actor'),
      director: tag('director'),
      description: _stripHtml(tag('des')),
    );
  }

  static String _fixCover(String? pic) {
    if (pic == null || pic.isEmpty) {
      return '';
    }
    if (pic.startsWith('//')) {
      return 'https:$pic';
    }
    return pic;
  }

  static String _stripHtml(String? text) {
    if (text == null || text.isEmpty) {
      return '';
    }
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  static String? _fixScore(dynamic score) {
    final s = score?.toString();
    if (s == null || s.isEmpty || s == '0' || s == '0.0') {
      return null;
    }
    return s;
  }
}

/// com.github.tvbox.osc.bean.AbsSortXml
class VodHomeData {
  /// com.github.tvbox.osc.bean.AbsSortXml.classes
  final List<VodCategory> categories;

  /// com.github.tvbox.osc.bean.MovieSort.SortData.filters
  final Map<String, List<VodFilter>> filters;

  /// com.github.tvbox.osc.bean.AbsSortXml.videoList
  final List<VodVideo> videoList;

  const VodHomeData({
    this.categories = const [],
    this.filters = const {},
    this.videoList = const [],
  });
}

/// com.github.tvbox.osc.bean.AbsXml
class VodListData {
  /// com.github.tvbox.osc.bean.AbsXml.movie.videoList
  final List<VodVideo> videoList;

  /// com.github.tvbox.osc.bean.AbsXml.movie.page
  final int page;

  /// com.github.tvbox.osc.bean.AbsXml.movie.pagecount
  final int pageCount;

  bool get hasMore => page < pageCount;

  const VodListData({
    this.videoList = const [],
    this.page = 1,
    this.pageCount = 1,
  });
}
