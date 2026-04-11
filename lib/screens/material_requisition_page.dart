import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/material_requisition_controller.dart';
import 'package:project_granith/viewmodels/materialrequisitionviewmodel.dart';
import 'package:project_granith/widgets/materialrequisition/material_requisition_page_page_widgets.dart';

class MaterialRequisitionPage extends StatelessWidget {
  const MaterialRequisitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MaterialRequisitionViewModel(
        MaterialRequisitionController(),
      ),
      child: const MaterialRequisitionPageView(),
    );
  }
}
