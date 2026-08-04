// 执行模式 7：后端统一响应包络 `{Code, Msg, Data}`。
// Code=0 表示成功；非 0 见 docs/frontend-api-integration.md §3。

class ApiEnvelope<T> {
  ApiEnvelope({required this.code, required this.msg, this.data});

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parseData,
  ) {
    return ApiEnvelope<T>(
      code: (json['Code'] as num).toInt(),
      msg: (json['Msg'] ?? '').toString(),
      data: json['Data'] == null ? null : parseData(json['Data']),
    );
  }

  final int code;
  final String msg;
  final T? data;

  bool get isOk => code == 0;
}
