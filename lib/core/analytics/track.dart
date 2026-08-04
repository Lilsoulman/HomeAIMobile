import 'package:flutter/foundation.dart';

/// M0.5 埋点占位：M5 事件服务可用后替换为远程上报。
void track(String event, [Map<String, Object?> properties = const {}]) {
  if (kDebugMode) debugPrint('track $event $properties');
}
