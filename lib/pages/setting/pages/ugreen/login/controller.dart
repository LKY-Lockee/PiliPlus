import 'dart:async';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/qr.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/pages/setting/pages/ugreen/login/widgets/otp_dialog.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_login_flow.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenLoginPageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final service = UgreenService.to;
  late final _flow = UgreenLoginFlow(service);

  late final addressTextController = TextEditingController(
    text: Pref.ugreenAddress,
  );
  final TextEditingController usernameTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final TextEditingController otpTextController = TextEditingController();

  late final codeInfo =
      LoadingState<({String qrCode, String url})>.loading().obs;
  late final TabController tabController;
  late final RxInt qrCodeLeftTime = 300.obs;
  late final RxString statusQRCode = ''.obs;

  late final RxBool loading = false.obs;
  late final RxBool needOtp = false.obs;
  late final RxBool isExceed = false.obs;
  late final RxBool trust = false.obs;
  late final RxBool emailMode = false.obs;
  late final RxBool sendingEmail = false.obs;
  late final RxInt emailSendCooldown = 0.obs;
  late final RxString email = ''.obs;

  String? _tokenId;
  Timer? qrCodeTimer;
  Timer? emailSendCooldownTimer;

  bool _isReq = false;
  bool _isQrReq = false;

  int get otpType => emailMode.value ? 2 : 1;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
  }

  @override
  void onClose() {
    tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    qrCodeTimer?.cancel();
    emailSendCooldownTimer?.cancel();
    _flow.dispose();
    addressTextController.dispose();
    usernameTextController.dispose();
    passwordTextController.dispose();
    otpTextController.dispose();
    super.onClose();
  }

  Future<void> refreshQRCode() async {
    if (_isQrReq) return;
    _isQrReq = true;
    qrCodeTimer?.cancel();
    qrCodeTimer = null;
    codeInfo.value = LoadingState.loading();
    statusQRCode.value = '正在生成二维码...';
    try {
      final res = await _flow.beginQrLogin();
      if (res case Success(:final response)) {
        codeInfo.value = Success((qrCode: response.qrCode, url: response.url));
        qrCodeLeftTime.value = 300;
        statusQRCode.value = '请使用绿联 App 扫码登录';
        _startQrTimer();
      } else {
        final message = res is Error ? (res.errMsg ?? '生成二维码失败') : '生成二维码失败';
        codeInfo.value = Error(message);
        qrCodeLeftTime.value = 0;
        statusQRCode.value = message;
      }
    } catch (e) {
      codeInfo.value = Error('生成二维码失败: $e');
      qrCodeLeftTime.value = 0;
      statusQRCode.value = '生成二维码失败: $e';
    } finally {
      _isQrReq = false;
    }
  }

  void _handleTabChange() {
    if (tabController.index == 1) {
      if (qrCodeTimer == null || !qrCodeTimer!.isActive) {
        refreshQRCode();
      }
    }
  }

  void _startQrTimer() {
    qrCodeTimer?.cancel();
    qrCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = 300 - timer.tick;
      if (left <= 0) {
        timer.cancel();
        qrCodeTimer = null;
        qrCodeLeftTime.value = 0;
        statusQRCode.value = '二维码已过期，请刷新';
        return;
      }
      qrCodeLeftTime.value = left;
      if (_isReq || tabController.index != 1) return;
      if (timer.tick % 3 != 0) return;
      _isReq = true;
      _pollQRCode(timer);
    });
  }

  Future<void> _pollQRCode(Timer timer) async {
    try {
      final res = await _flow.pollQrLogin();
      if (res is Error) {
        if (qrCodeLeftTime.value > 0) {
          statusQRCode.value = res.errMsg ?? '网络异常，正在重试...';
        }
        return;
      }
      if (res is! Success<UgreenQrPollResult>) {
        return;
      }
      final result = res.response;
      switch (result.status) {
        case UgreenQrStatus.waiting:
          if (qrCodeLeftTime.value > 0) {
            statusQRCode.value = '等待扫码...';
          }
          break;
        case UgreenQrStatus.scanned:
          statusQRCode.value = '已扫码，请在手机上确认';
          break;
        case UgreenQrStatus.expired:
          timer.cancel();
          qrCodeTimer = null;
          qrCodeLeftTime.value = 0;
          statusQRCode.value = '二维码已过期，请刷新';
          break;
        case UgreenQrStatus.rejected:
          timer.cancel();
          qrCodeTimer = null;
          statusQRCode.value = result.message ?? '环境异常，请刷新重试';
          break;
        case UgreenQrStatus.failed:
          statusQRCode.value = result.message ?? '扫码登录失败，正在重试...';
          break;
        case UgreenQrStatus.success:
          timer.cancel();
          qrCodeTimer = null;
          qrCodeLeftTime.value = 0;
          statusQRCode.value = '扫码成功';
          SmartDialog.showToast('登录成功');
          Get.back(result: true);
          break;
      }
    } catch (_) {
      if (qrCodeLeftTime.value > 0) {
        statusQRCode.value = '网络异常，正在重试...';
      }
    } finally {
      _isReq = false;
    }
  }

  Future<void> loginByPassword() async {
    if (loading.value) return;
    final address = addressTextController.text.trim();
    final username = usernameTextController.text.trim();
    final password = passwordTextController.text;
    if (address.isEmpty) {
      SmartDialog.showToast('请输入设备地址或 UGLink ID');
      return;
    }
    if (username.isEmpty) {
      SmartDialog.showToast('请输入用户名');
      return;
    }
    if (password.isEmpty) {
      SmartDialog.showToast('请输入密码');
      return;
    }
    loading.value = true;
    needOtp.value = false;
    emailMode.value = false;
    trust.value = false;
    isExceed.value = false;
    _stopEmailCooldown();
    try {
      final res = await _flow.signIn(
        address: address,
        username: username,
        password: password,
      );
      if (res is Error) {
        SmartDialog.showToast(res.errMsg ?? '登录失败');
        return;
      }
      if (res is! Success<UgreenLoginResult>) {
        return;
      }
      final result = res.response;
      if (result.needOtp) {
        _tokenId = result.tokenId;
        email.value = result.email ?? '';
        isExceed.value = result.isExceed;
        needOtp.value = true;
        otpTextController.clear();
        showUgreenOtpDialog(this);
        return;
      }
      _onSuccess();
    } catch (e) {
      SmartDialog.showToast('登录失败: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> loginByOtp() async {
    if (loading.value) return;
    final tokenId = _tokenId;
    if (tokenId == null || tokenId.isEmpty) {
      SmartDialog.showToast('登录状态已失效，请重新登录');
      return;
    }
    final code = otpTextController.text.trim();
    if (code.isEmpty) {
      SmartDialog.showToast(emailMode.value ? '请输入邮箱验证码' : '请输入验证码');
      return;
    }
    loading.value = true;
    try {
      final res = await _flow.submitOtp(
        tokenId: tokenId,
        code: code,
        type: otpType,
        trust: trust.value,
      );
      if (res is Error) {
        SmartDialog.showToast(res.errMsg ?? '验证失败');
        return;
      }
      if (res is! Success<UgreenLoginResult>) {
        return;
      }
      if (res.response.session == null) {
        SmartDialog.showToast('验证码错误或已失效，请重试');
        return;
      }
      _onSuccess(closeDialog: true);
    } catch (e) {
      SmartDialog.showToast('验证失败: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> sendEmailCode() async {
    if (sendingEmail.value || emailSendCooldown.value > 0) return;
    if (email.value.isEmpty) {
      SmartDialog.showToast('该账号未绑定备用邮箱');
      return;
    }
    sendingEmail.value = true;
    try {
      final res = await _flow.sendOtpEmailCode();
      if (res is Error) {
        if (res.code == 1121) {
          _startEmailCooldown();
          SmartDialog.showToast('验证码发送过于频繁，请 60 秒后重试');
        } else {
          SmartDialog.showToast(res.errMsg ?? '发送验证码失败');
        }
        return;
      }
      emailMode.value = true;
      otpTextController.clear();
      _startEmailCooldown();
      SmartDialog.showToast('验证码已发送至 ${email.value}');
    } catch (e) {
      SmartDialog.showToast('发送验证码失败: $e');
    } finally {
      sendingEmail.value = false;
    }
  }

  void backToOtp() {
    emailMode.value = false;
    otpTextController.clear();
  }

  void backToPassword() {
    needOtp.value = false;
    emailMode.value = false;
    otpTextController.clear();
    _stopEmailCooldown();
  }

  void _onSuccess({bool closeDialog = false}) {
    SmartDialog.showToast('登录成功');
    if (closeDialog) {
      Get.back();
    }
    Get.back(result: true);
  }

  void _startEmailCooldown() {
    emailSendCooldownTimer?.cancel();
    emailSendCooldown.value = 60;
    emailSendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      emailSendCooldown.value = 60 - timer.tick;
      if (emailSendCooldown.value <= 0) {
        emailSendCooldown.value = 0;
        timer.cancel();
        emailSendCooldownTimer = null;
      }
    });
  }

  void _stopEmailCooldown() {
    emailSendCooldownTimer?.cancel();
    emailSendCooldownTimer = null;
    emailSendCooldown.value = 0;
  }
}
