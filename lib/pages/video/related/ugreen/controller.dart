import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/related.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_video.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:get/get.dart';

class RelatedUgreenController
    extends CommonListController<List<UgreenRelatedVideo>, UgreenRelatedVideo> {
  final service = UgreenService.to;
  int ugVideoInfoId = Get.arguments['ugVideoInfoId'] as int;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<UgreenRelatedVideo>>> customGetData() async {
    final current = service.session.value;
    final id = ugVideoInfoId;
    if (current == null || id <= 0) {
      return const Error('无法加载相关推荐');
    }
    final result = await UgreenVideoHttp.relatedRecommendation(
      current,
      ugVideoInfoId: id,
    );
    return result;
  }
}
