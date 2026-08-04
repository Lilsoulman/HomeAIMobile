// 执行模式 8：API 异常体系。
//  - NetworkException：网络层失败（超时、断网、DNS）。
//  - UnauthorizedException：401 但仍可尝试 refresh。
//  - SessionExpiredException：refresh 也失败，必须跳登录。
//  - ApiException：业务 code ≠ 0，含原始 msg。

class ApiException implements Exception {
  ApiException(this.code, this.msg);
  final int code;
  final String msg;
  @override
  String toString() => 'ApiException($code): $msg';
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  UnauthorizedException();
}

class SessionExpiredException implements Exception {
  SessionExpiredException();
}
