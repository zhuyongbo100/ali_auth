import 'dart:async';

import 'package:flutter/services.dart';

class AliAuthPlugin {
  static const MethodChannel _channel = const MethodChannel('ali_auth');

  // 初始化SDK
  static Future<dynamic> initSdk(String sk) async {
    print("SDK sk=$sk");
    Map<String, String> params = {'sk': sk};
    return await _channel.invokeMethod("init", params);
  }

  /// SDK判断网络环境是否支持
  static Future<bool> get checkVerifyEnable async {
    return await _channel.invokeMethod("checkVerifyEnable");
  }
  
  // 一键登录
  static Future<dynamic> get login async {
    return await _channel.invokeMethod('login');
  }
  
  // 预取号
  static Future<dynamic> get preLogin async {
    return await _channel.invokeMethod('preLogin');
  }

}
