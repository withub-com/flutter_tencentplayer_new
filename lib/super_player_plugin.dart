import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/view/tencent_player.dart';

class SuperPlayerPlugin{
  MethodChannel _channel = TencentPlayer.channel;

  /// 设置全局license
  Future<void> setGlobalLicense(String licenceUrl, String licenceKey) async {
    return await _channel.invokeMethod("setGlobalLicense", {"licenceUrl": licenceUrl, "licenceKey": licenceKey});
  }
}

