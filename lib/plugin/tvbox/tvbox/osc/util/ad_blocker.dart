/// com.github.tvbox.osc.util.AdBlocker
class AdBlocker {
  AdBlocker._();

  /// com.github.tvbox.osc.util.AdBlocker.AD_HOSTS
  static final List<String> _adHosts = [];

  /// com.github.tvbox.osc.api.ApiConfig.loadDefaultConfig
  static const List<String> defaultAdHosts = [
    'mimg.0c1q0l.cn',
    'www.googletagmanager.com',
    'www.google-analytics.com',
    'mc.usihnbcq.cn',
    'mg.g1mm3d.cn',
    'mscs.svaeuzh.cn',
    'cnzz.hhttm.top',
    'tp.vinuxhome.com',
    'cnzz.mmstat.com',
    'www.baihuillq.com',
    's23.cnzz.com',
    'z3.cnzz.com',
    'c.cnzz.com',
    'stj.v1vo.top',
    'z12.cnzz.com',
    'img.mosflower.cn',
    'tips.gamevvip.com',
    'ehwe.yhdtns.com',
    'xdn.cqqc3.com',
    'www.jixunkyy.cn',
    'sp.chemacid.cn',
    'hm.baidu.com',
    's9.cnzz.com',
    'z6.cnzz.com',
    'um.cavuc.com',
    'mav.mavuz.com',
    'wofwk.aoidf3.com',
    'z5.cnzz.com',
    'xc.hubeijieshikj.cn',
    'tj.tianwenhu.com',
    'xg.gars57.cn',
    'k.jinxiuzhilv.com',
    'cdn.bootcss.com',
    'ppl.xunzhuo123.com',
    'xomk.jiangjunmh.top',
    'img.xunzhuo123.com',
    'z1.cnzz.com',
    's13.cnzz.com',
    'xg.huataisangao.cn',
    'z7.cnzz.com',
    'z2.cnzz.com',
    's96.cnzz.com',
    'q11.cnzz.com',
    'thy.dacedsfa.cn',
    'xg.whsbpw.cn',
    's19.cnzz.com',
    'z8.cnzz.com',
    's4.cnzz.com',
    'f5w.as12df.top',
    'ae01.alicdn.com',
    'www.92424.cn',
    'k.wudejia.com',
    'vivovip.mmszxc.top',
    'qiu.xixiqiu.com',
    'cdnjs.hnfenxun.com',
    'cms.qdwgcht.com',
  ];

  /// com.github.tvbox.osc.util.AdBlocker.clear
  static void clear() => _adHosts.clear();

  static void reset() {
    _adHosts
      ..clear()
      ..addAll(defaultAdHosts);
  }

  /// com.github.tvbox.osc.util.AdBlocker.isEmpty
  static bool isEmpty() => _adHosts.isEmpty;

  /// com.github.tvbox.osc.util.AdBlocker.addAdHost
  static void addAdHost(String host) {
    if (host.isNotEmpty && !_adHosts.contains(host)) {
      _adHosts.add(host);
    }
  }

  /// com.github.tvbox.osc.util.AdBlocker.hasHost
  static bool hasHost(String host) => _adHosts.contains(host);

  /// com.github.tvbox.osc.util.AdBlocker.isAd
  static bool isAd(String url) {
    final lower = url.toLowerCase();
    for (final adHost in _adHosts) {
      if (lower.contains(adHost)) {
        return true;
      }
    }
    return false;
  }
}
