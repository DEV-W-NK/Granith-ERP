import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';

class TeamService {
  final FirebaseFirestore _firestore;

  TeamService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─── Coleções ───────────────────────────────────────────────────────────────
  CollectionReference get _employees => _firestore.collection('employees');
  CollectionReference get _teams => _firestore.collection('teams');

  // ════════════════════════════════════════════════════════════════════════════
  // EMPLOYEES
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream de todos os funcionários, ordenados por nome.
  Stream<List<EmployeeModel>> getEmployees() {
    return _employees.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EmployeeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Salva (cria ou atualiza) um funcionário.
  Future<String> saveEmployee(EmployeeModel employee) async {
    final data = employee.toMap();
    if (employee.id.isEmpty) {
      final ref = await _employees.add(data);
      await ref.update({'id': ref.id});
      return ref.id;
    } else {
      await _employees.doc(employee.id).update(data);
      return employee.id;
    }
  }

  Future<void> deleteEmployee(String id) async {
    await _employees.doc(id).delete();
    // Remove o funcionário de todas as equipes que o contêm
    final teamsWithMember = await _teams
        .where('memberIds', arrayContains: id)
        .get();
    for (final doc in teamsWithMember.docs) {
      final members = List<String>.from(
          (doc.data() as Map<String, dynamic>)['memberIds'] ?? []);
      members.remove(id);
      await doc.reference.update({'memberIds': members, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  /// Soft-dismiss: altera status para 'desligado' e remove de todas as equipes.
  /// O documento do funcionário é preservado no banco.
  Future<void> dismissEmployee(String id) async {
    // Atualiza o status para desligado
    await _employees.doc(id).update({
      'status': 'desligado',
    });
    // Remove de todas as equipes que o contêm
    final teamsWithMember = await _teams
        .where('memberIds', arrayContains: id)
        .get();
    for (final doc in teamsWithMember.docs) {
      await doc.reference.update({
        'memberIds': FieldValue.arrayRemove([id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Se era líder, remove a liderança também
      final data = doc.data() as Map<String, dynamic>;
      if (data['leaderId'] == id) {
        await doc.reference.update({'leaderId': null});
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TEAMS
  // ════════════════════════════════════════════════════════════════════════════

  /// Stream de todas as equipes ativas.
  Stream<List<TeamModel>> getTeams() {
    return _teams
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Cria uma nova equipe e retorna o ID gerado.
  Future<String> createTeam(TeamModel team) async {
    final data = team.toMap();
    final ref = await _teams.add(data);
    await ref.update({'id': ref.id});
    return ref.id;
  }

  /// Atualiza nome, descrição, líder ou vínculo de projeto da equipe.
  Future<void> updateTeam(TeamModel team) async {
    await _teams.doc(team.id).update({
      ...team.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Desativa (soft-delete) uma equipe.
  Future<void> deleteTeam(String teamId) async {
    await _teams.doc(teamId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adiciona um membro à equipe.
  Future<void> addMemberToTeam(String teamId, String employeeId) async {
    await _teams.doc(teamId).update({
      'memberIds': FieldValue.arrayUnion([employeeId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove um membro da equipe.
  Future<void> removeMemberFromTeam(String teamId, String employeeId) async {
    await _teams.doc(teamId).update({
      'memberIds': FieldValue.arrayRemove([employeeId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Define o líder da equipe.
  Future<void> setTeamLeader(String teamId, String? employeeId) async {
    await _teams.doc(teamId).update({
      'leaderId': employeeId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Busca uma equipe pelo ID (one-shot, não stream).
  Future<TeamModel?> getTeamById(String teamId) async {
    final doc = await _teams.doc(teamId).get();
    if (!doc.exists) return null;
    return TeamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}