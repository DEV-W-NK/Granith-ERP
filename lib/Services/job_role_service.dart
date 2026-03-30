import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/job_role_model.dart';

class JobRoleService {
  final FirebaseFirestore _firestore;

  JobRoleService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Coleção no Firestore vinculada ao ERP
  CollectionReference get _collection => _firestore.collection('job_roles');

  // Obter todos os cargos em tempo real
  Stream<List<JobRoleModel>> getJobRoles() {
    return _collection.orderBy('title').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobRoleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> saveJobRole(JobRoleModel role) async {
    if (role.id.isEmpty) {
      await _collection.add(role.toMap());
    } else {
      await _collection.doc(role.id).update(role.toMap());
    }
  }

  Future<void> deleteJobRole(String id) async {
    await _collection.doc(id).delete();
  }
}