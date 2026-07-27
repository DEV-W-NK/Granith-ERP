import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/granith_task.dart';
import 'package:project_granith/models/project_model.dart';

class GranithTaskService {
  static const _table = 'granith_tasks';

  Stream<List<GranithTask>> watchTasks() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('updatedAt', ascending: false)
        .map(
          (rows) => rows
              .map((row) => GranithTask.fromMap(Map<String, dynamic>.from(row)))
              .toList(growable: false),
        );
  }

  Future<List<EmployeeModel>> getActiveEmployees() async {
    final rows = await AppSupabase.client
        .from('employees')
        .select()
        .eq('status', 'ativo')
        .order('name');
    return (rows as List)
        .map(
          (row) => EmployeeModel.fromMap(
            Map<String, dynamic>.from(row as Map),
            row['id'].toString(),
          ),
        )
        .toList(growable: false);
  }

  Future<List<Project>> getProjects() async {
    final rows = await AppSupabase.client
        .from('projects')
        .select()
        .order('name');
    return (rows as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return Project.fromMap(data['id'].toString(), data);
        })
        .toList(growable: false);
  }

  Future<List<Budget>> getBudgets() async {
    final rows = await AppSupabase.client
        .from('budgets')
        .select()
        .order('creationDate', ascending: false)
        .limit(250);
    return (rows as List)
        .map((row) => Budget.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<EmployeeModel?> getCurrentEmployee() async {
    final user = AppSupabase.client.auth.currentUser;
    if (user == null) return null;

    String? employeeId;
    try {
      final users = await AppSupabase.client
          .from('users')
          .select('employeeId,employee_id')
          .eq('id', user.id)
          .limit(1);
      final userRows = users as List;
      final userRow =
          userRows.isEmpty
              ? null
              : Map<String, dynamic>.from(userRows.first as Map);
      employeeId =
          userRow?['employeeId']?.toString().trim().isNotEmpty == true
              ? userRow!['employeeId'].toString()
              : userRow?['employee_id']?.toString();
    } catch (_) {
      // Contas antigas podem consultar apenas employees via e-mail.
    }

    dynamic row;
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      row =
          await AppSupabase.client
              .from('employees')
              .select()
              .eq('id', employeeId)
              .maybeSingle();
    } else if ((user.email ?? '').trim().isNotEmpty) {
      row =
          await AppSupabase.client
              .from('employees')
              .select()
              .ilike('email', user.email!.trim())
              .maybeSingle();
    }

    if (row == null) return null;
    final data = Map<String, dynamic>.from(row as Map);
    return EmployeeModel.fromMap(data, data['id'].toString());
  }

  Future<void> saveTask({
    String? id,
    required String title,
    required String description,
    required GranithTaskPriority priority,
    required String supervisorId,
    required String assigneeId,
    required GranithTaskSource source,
    String? projectId,
    String? budgetId,
    DateTime? dueAt,
    required int estimatedMinutes,
  }) async {
    final data = DbValue.normalizeMap({
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority.name,
      'supervisorId': supervisorId,
      'assigneeId': assigneeId,
      'sourceType': source.name,
      'projectId': source == GranithTaskSource.project ? projectId : null,
      'budgetId': source == GranithTaskSource.budget ? budgetId : null,
      'dueAt': dueAt,
      'estimatedMinutes': estimatedMinutes,
    });

    if (id == null || id.isEmpty) {
      await AppSupabase.client.from(_table).insert(data);
    } else {
      await AppSupabase.client.from(_table).update(data).eq('id', id);
    }
    _notifyChanged();
  }

  Future<GranithTask> setTimer(
    String taskId,
    String action, {
    String source = 'web',
    DateTime? occurredAt,
  }) async {
    final response = await AppSupabase.client.rpc(
      'set_granith_task_timer',
      params: {
        'p_task_id': taskId,
        'p_action': action,
        'p_source': source,
        'p_occurred_at': occurredAt?.toUtc().toIso8601String(),
      },
    );
    _notifyChanged();
    final data =
        response is List
            ? Map<String, dynamic>.from(response.first as Map)
            : Map<String, dynamic>.from(response as Map);
    return GranithTask.fromMap(data);
  }

  Future<void> cancelTask(String taskId) async {
    await AppSupabase.client
        .from(_table)
        .update({'status': GranithTaskStatus.cancelled.name})
        .eq('id', taskId);
    _notifyChanged();
  }

  void _notifyChanged() {
    AppDataRefreshBus.instance.notify(
      scopes: const ['granith_tasks'],
      source: 'granith_task_service',
    );
  }
}
