import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/BenefitModel.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';
import 'package:project_granith/models/SalaryHistoryModel.dart';
import 'package:project_granith/models/employee_model.dart';

class HrService {
  final _db = FirebaseFirestore.instance;

  // ── Collections ────────────────────────────────────────────────────────────
  CollectionReference get _employees      => _db.collection('employees');
  CollectionReference get _benefits       => _db.collection('benefits');
  CollectionReference get _salaryHistory  => _db.collection('salary_history');
  CollectionReference get _empBenefits    => _db.collection('employee_benefits');

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIONÁRIOS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<EmployeeModel>> watchEmployees() =>
      _employees.orderBy('name').snapshots().map((snap) => snap.docs
          .map((d) => EmployeeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList());

  Future<EmployeeModel?> getEmployee(String id) async {
    final doc = await _employees.doc(id).get();
    if (!doc.exists) return null;
    return EmployeeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<String> addEmployee(EmployeeModel employee) async {
    final ref = await _employees.add(employee.toMap());
    return ref.id;
  }

  Future<void> updateEmployee(EmployeeModel employee) =>
      _employees.doc(employee.id).update({
        ...employee.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

  /// Registra desligamento: muda status, salva dismissalDate e remove de equipes.
  Future<void> dismissEmployee(String employeeId, {String? updatedBy}) async {
    final batch = _db.batch();

    // Atualiza funcionário
    batch.update(_employees.doc(employeeId), {
      'status':       EmployeeStatus.desligado.name,
      'dismissalDate': Timestamp.fromDate(DateTime.now()),
      'updatedAt':    Timestamp.fromDate(DateTime.now()),
    });

    // Remove de todas as equipes
    final teamsSnap = await _db
        .collection('teams')
        .where('memberIds', arrayContains: employeeId)
        .get();

    for (final team in teamsSnap.docs) {
      final members = List<String>.from(
          (team.data()['memberIds'] as List<dynamic>?) ?? []);
      members.remove(employeeId);

      final update = <String, dynamic>{'memberIds': members};
      // Remove liderança se for o líder
      if (team.data()['leaderId'] == employeeId) update['leaderId'] = null;
      batch.update(team.reference, update);
    }

    // Desativa benefícios ativos
    final benefitsSnap = await _empBenefits
        .where('employeeId', isEqualTo: employeeId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final b in benefitsSnap.docs) {
      batch.update(b.reference, {
        'isActive': false,
        'endDate':  Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HISTÓRICO SALARIAL
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<SalaryHistoryModel>> watchSalaryHistory(String employeeId) =>
      _salaryHistory
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('effectiveDate', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => SalaryHistoryModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList());

  /// Aplica reajuste salarial: grava histórico + atualiza baseSalary do funcionário.
  Future<void> applyRaise({
    required String employeeId,
    required double currentSalary,
    required double newSalary,
    required String reason,
    required String updatedBy,
    DateTime? effectiveDate,
  }) async {
    final batch = _db.batch();
    final now   = DateTime.now();
    final date  = effectiveDate ?? now;

    // Append-only: nunca editar entradas de histórico
    final histRef = _salaryHistory.doc();
    batch.set(histRef, SalaryHistoryModel(
      id:             histRef.id,
      employeeId:     employeeId,
      previousSalary: currentSalary,
      newSalary:      newSalary,
      effectiveDate:  date,
      reason:         reason,
      updatedBy:      updatedBy,
      createdAt:      now,
    ).toMap());

    // Atualiza salário atual no funcionário
    batch.update(_employees.doc(employeeId), {
      'baseSalary': newSalary,
      'updatedAt':  Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BENEFÍCIOS (catálogo)
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<BenefitModel>> watchBenefits({bool onlyActive = false}) {
    Query query = _benefits.orderBy('name');
    if (onlyActive) query = query.where('isActive', isEqualTo: true);
    return query.snapshots().map((snap) => snap.docs
        .map((d) => BenefitModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<String> addBenefit(BenefitModel benefit) async {
    final ref = await _benefits.add(benefit.toMap());
    return ref.id;
  }

  Future<void> updateBenefit(BenefitModel benefit) =>
      _benefits.doc(benefit.id).update(benefit.toMap());

  Future<void> toggleBenefit(String id, bool isActive) =>
      _benefits.doc(id).update({'isActive': isActive});

  // ══════════════════════════════════════════════════════════════════════════
  // BENEFÍCIOS POR FUNCIONÁRIO
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<EmployeeBenefitModel>> watchEmployeeBenefits(String employeeId) =>
      _empBenefits
          .where('employeeId', isEqualTo: employeeId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => EmployeeBenefitModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList());

  Future<String> assignBenefit(EmployeeBenefitModel empBenefit) async {
    final ref = await _empBenefits.add(empBenefit.toMap());
    return ref.id;
  }

  /// Altera valor de um benefício existente e registra no histórico.
  Future<void> updateBenefitValue({
    required String empBenefitId,
    required double currentValue,
    required double newValue,
    required String changedBy,
    String reason = '',
  }) async {
    final entry = BenefitHistoryEntry(
      previousValue: currentValue,
      newValue:      newValue,
      changedAt:     DateTime.now(),
      changedBy:     changedBy,
      reason:        reason,
    );

    await _empBenefits.doc(empBenefitId).update({
      'monthlyValue': newValue,
      'history': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  Future<void> removeBenefitFromEmployee(String empBenefitId) =>
      _empBenefits.doc(empBenefitId).update({
        'isActive': false,
        'endDate':  Timestamp.fromDate(DateTime.now()),
      });

  /// Custo total mensal de benefícios de um funcionário.
  Future<double> getTotalBenefitCost(String employeeId) async {
    final snap = await _empBenefits
        .where('employeeId', isEqualTo: employeeId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.fold<double>(0.0, (sum, d) {
      final data = d.data() as Map<String, dynamic>;
      return sum + ((data['monthlyValue'] ?? 0.0) as num).toDouble();
    });
  }
}