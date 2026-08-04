// 执行模式 14：Todo 仓储接口。

import 'dto.dart';

abstract class TodoRepository {
  Future<List<TodoDto>> list({String? status, DateTime? from, DateTime? to});
  Future<TodoDto> create({
    required String title,
    String? description,
    String? type,
    String? priority,
    String? color,
    String? status,
    DateTime? dueAt,
    DateTime? remindAt,
    bool? pinned,
    int? sortOrder,
    String? repeatRule,
    int? parentId,
  });
  Future<TodoDto> update(int id, Map<String, dynamic> patch);
  Future<void> delete(int id);
  Future<List<SubtaskDto>> listSubtasks(int todoId);
  Future<SubtaskDto> addSubtask(int todoId, {required String text, int? seq});
  Future<SubtaskDto> updateSubtask(
    int todoId,
    int subId,
    Map<String, dynamic> patch,
  );
  Future<void> deleteSubtask(int todoId, int subId);
}
