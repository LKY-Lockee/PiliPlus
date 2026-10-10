import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/pages/setting/models/vod_settings.dart';
import 'package:material_ui/material_ui.dart';

class VodSettingsPage extends StatelessWidget {
  const VodSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(title: const Text('点播设置')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: vodSettings.map((e) => e.widget).toList(),
      ),
    );
  }
}
