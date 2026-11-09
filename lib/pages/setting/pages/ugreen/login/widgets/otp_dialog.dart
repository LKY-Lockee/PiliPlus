import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/pages/setting/pages/ugreen/login/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

void showUgreenOtpDialog(UgreenLoginPageController ctr) {
  final context = Get.context;
  if (context == null) return;
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.only(
          left: 16,
          top: 18,
          right: 16,
          bottom: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: const Text(
          '本次登录需要验证',
          textAlign: TextAlign.center,
        ),
        content: Obx(() {
          final isEmailMode = ctr.emailMode.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEmailMode
                    ? '验证码已发送至 ${ctr.email.value}'
                    : '请输入验证器 App 中显示的一次性验证码',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (ctr.isExceed.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '验证码尝试次数过多，请稍后再试',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextField(
                controller: ctr.otpTextController,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => ctr.loginByOtp(),
                decoration: InputDecoration(
                  hintText: isEmailMode ? '请输入邮箱验证码' : '请输入验证码',
                  hintStyle: const TextStyle(fontSize: 15),
                  suffixIcon: iconButton(
                    icon: const Icon(Icons.clear),
                    size: 32,
                    onPressed: ctr.otpTextController.clear,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 32,
                    maxWidth: 32,
                  ),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: ctr.trust.value,
                    onChanged: (value) => ctr.trust.value = value ?? false,
                  ),
                  const Expanded(child: Text('信任此设备')),
                ],
              ),
              if (!isEmailMode)
                TextButton(
                  onPressed:
                      ctr.sendingEmail.value || ctr.emailSendCooldown.value > 0
                      ? null
                      : ctr.sendEmailCode,
                  child: Text(
                    ctr.sendingEmail.value
                        ? '正在发送...'
                        : ctr.emailSendCooldown.value > 0
                        ? '无法通过OTP验证？（${ctr.emailSendCooldown.value}s）'
                        : '无法通过OTP验证？',
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: ctr.emailSendCooldown.value > 0
                          ? null
                          : ctr.sendEmailCode,
                      child: Text(
                        ctr.emailSendCooldown.value > 0
                            ? '重新发送（${ctr.emailSendCooldown.value}s）'
                            : '重新发送',
                      ),
                    ),
                    TextButton(
                      onPressed: ctr.backToOtp,
                      child: const Text('返回验证器验证'),
                    ),
                  ],
                ),
            ],
          );
        }),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              ctr.backToPassword();
              Get.back();
            },
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Obx(
            () => TextButton(
              onPressed: ctr.loading.value ? null : ctr.loginByOtp,
              child: const Text('确认'),
            ),
          ),
        ],
      );
    },
  );
}
