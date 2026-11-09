import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenSettingsPage extends StatelessWidget {
  const UgreenSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = UgreenService.to;
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return SimpleScaffold(
      appBar: AppBar(title: const Text('绿联云')),
      body: Obx(() {
        final session = service.session.value;
        final isLogin = service.isLogin;
        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            if (session != null && isLogin) ...[
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(session.username, style: titleStyle),
                subtitle: Text(session.nasName ?? '', style: subTitleStyle),
              ),
              const Divider(height: 1),
              if (session.localBaseUrls.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text('本地地址', style: titleStyle),
                  subtitle: Text(
                    session.localBaseUrls.join('\n'),
                    style: subTitleStyle,
                  ),
                ),
              if (!session.relayUrl.isNullOrEmpty)
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: Text('中继地址', style: titleStyle),
                  subtitle: Text(session.relayUrl!, style: subTitleStyle),
                ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text('当前地址', style: titleStyle),
                subtitle: Text(
                  UgreenEndpoint.displayUrl(session),
                  style: subTitleStyle,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text('退出登录', style: titleStyle),
                onTap: () => _confirmLogout(context, service),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text('登录绿联云', style: titleStyle),
                onTap: () => Get.toNamed('/ugreenLogin'),
              ),
            ],
          ],
        );
      }),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    UgreenService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出绿联云账号吗？'),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '取消',
                style: TextStyle(color: ColorScheme.of(context).outline),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await service.logout();
    }
  }
}
