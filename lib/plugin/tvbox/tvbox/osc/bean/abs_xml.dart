import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

class AbsXml {
  AbsXml._();

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.xml
  static LoadingState<VodListData> parse(String body) {
    try {
      final doc = XmlDocument.parse(body);
      final listEl = doc.findAllElements('list').firstOrNull;
      if (listEl == null) {
        return const Error('数据解析失败');
      }
      final cards = <VodVideo>[];
      for (final video in listEl.findElements('video')) {
        final card = VodVideo.fromXml(video);
        if (card != null) {
          cards.add(card);
        }
      }
      return Success(
        VodListData(
          videoList: cards,
          page: DefaultConfig.safeJsonInt(listEl.getAttribute('page'), 1),
          pageCount: DefaultConfig.safeJsonInt(
            listEl.getAttribute('pagecount'),
            1,
          ),
        ),
      );
    } catch (_) {
      return const Error('数据解析失败');
    }
  }

  /// com.github.tvbox.osc.viewmodel.SourceViewModel.xml
  static LoadingState<VodInfoModel> parseDetail(String body) {
    try {
      final doc = XmlDocument.parse(body);
      final video = doc.findAllElements('video').firstOrNull;
      if (video == null) {
        return const Error('未找到相关内容');
      }
      final card = VodVideo.fromXml(video);
      if (card == null) {
        return const Error('未找到相关内容');
      }
      final playFlags = <VodPlayGroup>[];
      for (final dd in video.findAllElements('dd')) {
        final flag = dd.getAttribute('flag')?.trim() ?? '';
        final urls = dd.innerText.trim();
        if (flag.isEmpty || urls.isEmpty) {
          continue;
        }
        playFlags.addAll(SourceViewModel.parsePlayUrls(flag, urls));
      }
      return Success(VodInfoModel(video: card, playFlags: playFlags));
    } catch (_) {
      return const Error('数据解析失败');
    }
  }
}
