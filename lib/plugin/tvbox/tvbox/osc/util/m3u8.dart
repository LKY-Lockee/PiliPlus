/// com.github.tvbox.osc.util.M3u8
class M3u8 {
  M3u8._();

  /// com.github.tvbox.osc.util.M3u8.isAd
  static bool isAd(String regex) {
    return regex.contains('#EXT-X-DISCONTINUITY') ||
        regex.contains('#EXTINF') ||
        regex.contains('#EXT-X-ENDLIST') ||
        regex.contains('#EXT-X-KEY') ||
        regex.contains('#EXT-X-CUE-OUT') ||
        regex.contains('#EXT-X-CUE-IN') ||
        regex.contains('#EXT-X-DATERANGE') ||
        isDouble(regex);
  }

  /// com.github.tvbox.osc.util.M3u8.isDouble
  static bool isDouble(String ad) {
    final value = double.tryParse(ad);
    return value != null && value != 0;
  }
}
