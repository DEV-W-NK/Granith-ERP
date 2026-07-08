import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

class ProjectMeasurementFormDialog extends StatefulWidget {
  final List<Project> projects;
  final ProjectMeasurement? measurement;

  const ProjectMeasurementFormDialog({
    super.key,
    required this.projects,
    this.measurement,
  });

  @override
  State<ProjectMeasurementFormDialog> createState() =>
      _ProjectMeasurementFormDialogState();
}

class _ProjectMeasurementFormDialogState
    extends State<ProjectMeasurementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _grossAmountController;
  late final TextEditingController _discountAmountController;
  late final TextEditingController _notesController;

  String? _selectedProjectId;
  ProjectMeasurementStatus _selectedStatus = ProjectMeasurementStatus.pending;
  DateTime _measurementDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final measurement = widget.measurement;
    _titleController = TextEditingController(text: measurement?.title ?? '');
    _grossAmountController = TextEditingController(
      text:
          measurement != null ? measurement.grossAmount.toStringAsFixed(2) : '',
    );
    _discountAmountController = TextEditingController(
      text:
          measurement != null
              ? measurement.discountAmount.toStringAsFixed(2)
              : '',
    );
    _notesController = TextEditingController(text: measurement?.notes ?? '');
    _selectedProjectId =
        measurement?.projectId ??
        (widget.projects.length == 1 ? widget.projects.first.id : null);
    _selectedStatus = measurement?.status ?? ProjectMeasurementStatus.pending;
    _measurementDate = measurement?.measurementDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _grossAmountController.dispose();
    _discountAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.measurement != null;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < ResponsiveLayout.compact;
    final inset = size.width < 420 ? 8.0 : 24.0;
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 560.0);
    final projectItems =
        widget.projects
            .map(
              (project) => DropdownMenuItem<String>(
                value: project.id,
                child: Text('${project.name} • ${project.client}'),
              ),
            )
            .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(inset),
      child: Container(
        width: dialogWidth.toDouble(),
        constraints: BoxConstraints(maxHeight: size.height * 0.92),
        decoration: AppDecorations.dialogSurface(
          glowColor: AppColors.accentBlue,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GranithDialogHeader(
              icon: Icons.fact_check_rounded,
              title: isEditing ? 'Editar medicao' : 'Nova medicao',
              subtitle:
                  'Registre valores medidos e atualize o progresso estimado da obra.',
              accentColor: AppColors.accentBlue,
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: ResponsiveLayout.pagePadding(size.width),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedProjectId,
                        dropdownColor: AppColors.surfaceDark,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Projeto'),
                        items: projectItems,
                        onChanged: (value) {
                          setState(() => _selectedProjectId = value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selecione um projeto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Titulo da medicao',
                          hintText: 'Ex.: 1a medicao, medicao estrutural',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _responsivePair(
                        TextFormField(
                          controller: _grossAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Valor bruto',
                            prefixText: 'R\$ ',
                          ),
                          validator: (value) {
                            final amount = _parseAmount(value);
                            if (amount <= 0) {
                              return 'Informe um valor bruto maior que zero.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _discountAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Descontos',
                            prefixText: 'R\$ ',
                          ),
                          validator: (value) {
                            final discount = _parseAmount(value);
                            final gross = _parseAmount(
                              _grossAmountController.text,
                            );
                            if (discount < 0) {
                              return 'Desconto invalido.';
                            }
                            if (discount > gross) {
                              return 'Desconto maior que o valor bruto.';
                            }
                            return null;
                          },
                        ),
                        compact,
                      ),
                      const SizedBox(height: 16),
                      _responsivePair(
                        DropdownButtonFormField<ProjectMeasurementStatus>(
                          initialValue: _selectedStatus,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items:
                              ProjectMeasurementStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.displayName),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                            }
                          },
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data da medicao',
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_measurementDate),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        compact,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Observacoes',
                          hintText:
                              'Registre escopo medido, etapa executada ou pontos de atencao.',
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : Icons.add_task_rounded,
                            ),
                            label: Text(isEditing ? 'Salvar' : 'Registrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _responsivePair(Widget first, Widget second, bool compact) {
    if (compact) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }

    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _measurementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentBlue,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _measurementDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final selectedProject = widget.projects.firstWhere(
      (project) => project.id == _selectedProjectId,
    );

    Navigator.pop(
      context,
      ProjectMeasurement(
        id: widget.measurement?.id ?? '',
        projectId: selectedProject.id,
        projectName: selectedProject.name,
        projectClient: selectedProject.client,
        title: _titleController.text.trim(),
        sequence: widget.measurement?.sequence ?? 0,
        status: _selectedStatus,
        measurementDate: _measurementDate,
        grossAmount: _parseAmount(_grossAmountController.text),
        discountAmount: _parseAmount(_discountAmountController.text),
        netAmount: widget.measurement?.netAmount ?? 0,
        accumulatedGrossAmount: widget.measurement?.accumulatedGrossAmount ?? 0,
        measurementPercentage: widget.measurement?.measurementPercentage ?? 0,
        accumulatedPercentage: widget.measurement?.accumulatedPercentage ?? 0,
        contractBalance: widget.measurement?.contractBalance ?? 0,
        notes: _notesController.text.trim(),
        createdAt: widget.measurement?.createdAt,
        updatedAt: widget.measurement?.updatedAt,
      ),
    );
  }

  double _parseAmount(String? rawValue) {
    final normalized = (rawValue ?? '').replaceAll('R\$', '').trim();
    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains(',') && normalized.contains('.')) {
      return double.tryParse(
            normalized.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0;
    }

    return double.tryParse(normalized.replaceAll(',', '.')) ?? 0;
  }
}
