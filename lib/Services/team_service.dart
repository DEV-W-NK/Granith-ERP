import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';

class EmployeeSchemaException implements Exception {
  final String message;

  const EmployeeSchemaException(this.message);

  @override
  String toString() => message;
}

class TeamService {
  static const _employees = 'employees';
  static const _teams = 'teams';

  Stream<List<EmployeeModel>> getEmployees() {
    return AppSupabase.client
        .from(_employees)
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => EmployeeModel.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id'] as String,
                    ),
                  )
                  .toList(),
        );
  }

  Future<String> saveEmployee(EmployeeModel employee) async {
    final data = DbValue.normalizeMap(employee.toMap());
    try {
      if (employee.id.isEmpty) {
        final response =
            await AppSupabase.client
                .from(_employees)
                .insert(data)
                .select('id')
                .single();
        return response['id'] as String;
      } else {
        await AppSupabase.client
            .from(_employees)
            .update(data)
            .eq('id', employee.id);
        return employee.id;
      }
    } catch (error) {
      if (_isEmployeesRoleConstraintError(error)) {
        throw EmployeeSchemaException(
          'O banco Supabase ainda nao aceita o nivel "Gerencia". '
          'Aplique a migration que atualiza employees_role_check ou selecione '
          'Colaborador, Supervisao ou Coordenacao.',
        );
      }
      rethrow;
    }
  }

  bool _isEmployeesRoleConstraintError(Object error) {
    final text = error.toString();
    return text.contains('23514') && text.contains('employees_role_check');
  }

  Future<void> deleteEmployee(String id) async {
    await AppSupabase.client.from(_employees).delete().eq('id', id);

    final teamsWithMember = await AppSupabase.client
        .from(_teams)
        .select()
        .contains('memberIds', [id]);

    for (final row in teamsWithMember as List) {
      final team = Map<String, dynamic>.from(row as Map);
      final members = List<String>.from(team['memberIds'] ?? []);
      members.remove(id);

      await AppSupabase.client
          .from(_teams)
          .update({
            'memberIds': members,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', team['id']);
    }
  }

  Future<void> dismissEmployee(String id) async {
    await AppSupabase.client
        .from(_employees)
        .update({
          'status': 'desligado',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);

    final teamsWithMember = await AppSupabase.client
        .from(_teams)
        .select()
        .contains('memberIds', [id]);

    for (final row in teamsWithMember as List) {
      final team = Map<String, dynamic>.from(row as Map);
      final members = List<String>.from(team['memberIds'] ?? [])..remove(id);

      await AppSupabase.client
          .from(_teams)
          .update({
            'memberIds': members,
            'leaderId': team['leaderId'] == id ? null : team['leaderId'],
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', team['id']);
    }
  }

  Stream<List<TeamModel>> getTeams() {
    return AppSupabase.client
        .from(_teams)
        .stream(primaryKey: ['id'])
        .eq('isActive', true)
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => TeamModel.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id'] as String,
                    ),
                  )
                  .toList(),
        );
  }

  Future<String> createTeam(TeamModel team) async {
    final response =
        await AppSupabase.client
            .from(_teams)
            .insert(DbValue.normalizeMap(team.toMap()))
            .select('id')
            .single();
    return response['id'] as String;
  }

  Future<void> updateTeam(TeamModel team) async {
    await AppSupabase.client
        .from(_teams)
        .update({
          ...DbValue.normalizeMap(team.toMap()),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', team.id);
  }

  Future<void> deleteTeam(String teamId) async {
    await AppSupabase.client
        .from(_teams)
        .update({
          'isActive': false,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', teamId);
  }

  Future<void> addMemberToTeam(String teamId, String employeeId) async {
    final team = await getTeamById(teamId);
    if (team == null) return;
    final members = <String>{...team.memberIds, employeeId}.toList();
    await AppSupabase.client
        .from(_teams)
        .update({
          'memberIds': members,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', teamId);
  }

  Future<void> removeMemberFromTeam(String teamId, String employeeId) async {
    final team = await getTeamById(teamId);
    if (team == null) return;
    final members = <String>[...team.memberIds]..remove(employeeId);
    await AppSupabase.client
        .from(_teams)
        .update({
          'memberIds': members,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', teamId);
  }

  Future<void> setTeamLeader(String teamId, String? employeeId) async {
    await AppSupabase.client
        .from(_teams)
        .update({
          'leaderId': employeeId,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', teamId);
  }

  Future<TeamModel?> getTeamById(String teamId) async {
    final row =
        await AppSupabase.client
            .from(_teams)
            .select()
            .eq('id', teamId)
            .maybeSingle();
    if (row == null) return null;
    return TeamModel.fromMap(Map<String, dynamic>.from(row), teamId);
  }
}
