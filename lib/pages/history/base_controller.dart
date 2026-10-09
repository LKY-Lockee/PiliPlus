import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryBaseController extends GetxController {
  RxBool pauseStatus = Pref.historyPause.obs;

  RxBool enableMultiSelect = false.obs;
  RxInt checkedCount = 0.obs;

  final account = Accounts.history;

  Future<void> historyStatus() async {
    final res = await UserHttp.historyStatus(account: account);
    if (res case Success(:final response)) {
      pauseStatus.value = response;
      GStorage.localCache.put(LocalCacheKey.historyPause, response);
    } else {
      res.toast();
    }
  }

  // 清空观看历史
  void onClearHistory(
    BuildContext context,
    Future<LoadingState<void>> Function(Account account) onClear,
    VoidCallback onSuccess,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('啊叻？你要清空历史记录功能吗？'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              SmartDialog.showLoading(msg: '请求中');
              final res = await onClear(account);
              SmartDialog.dismiss();
              if (res.isSuccess) {
                SmartDialog.showToast('清空观看历史');
                onSuccess();
              } else {
                res.toast();
              }
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  // 暂停观看历史
  void onPauseHistory(BuildContext context) {
    final pauseStatus = !this.pauseStatus.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(pauseStatus ? '啊叻？你要暂停历史记录功能吗？' : '啊叻？要恢复历史记录功能吗？'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              SmartDialog.showLoading(msg: '请求中');
              final res = account.isLogin
                  ? await UserHttp.pauseHistory(
                      pauseStatus,
                      account: account,
                    )
                  : const Success<void>(null);
              SmartDialog.dismiss();
              if (res.isSuccess) {
                SmartDialog.showToast(pauseStatus ? '暂停观看历史' : '恢复观看历史');
                this.pauseStatus.value = pauseStatus;
                GStorage.localCache.put(
                  LocalCacheKey.historyPause,
                  pauseStatus,
                );
              } else {
                res.toast();
              }
              Get.back();
            },
            child: Text(pauseStatus ? '确认暂停' : '确认恢复'),
          ),
        ],
      ),
    );
  }
}
