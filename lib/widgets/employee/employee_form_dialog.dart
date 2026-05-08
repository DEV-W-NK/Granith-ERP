import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/models/sector_model.dart';
import 'package:project_granith/services/job_role_service.dart';
import 'package:project_granith/services/sector_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class EmployeeFormDialog extends StatefulWidget {
  /// Passar um [employee] existente coloca o dialog em modo de edição.
  final EmployeeModel? employee;
  final bool canViewSalary;
  final JobRoleService jobRoleService;
  final SectorService sectorService;

  EmployeeFormDialog({
    super.key,
    this.employee,
    this.canViewSalary = true,
    JobRoleService? jobRoleService,
    SectorService? sectorService,
  }) : jobRoleService = jobRoleService ?? JobRoleService(),
       sectorService = sectorService ?? SectorService();

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _ctpsCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _coursesCtrl = TextEditingController();

  late final Stream<List<JobRoleModel>> _jobRolesStream;
  late final Stream<List<SectorModel>> _sectorsStream;
  String? _selectedJobRoleId;
  String? _selectedSector;
  EmployeeRole _role = EmployeeRole.funcionario;
  EmployeeStatus _status = EmployeeStatus.ativo;
  DateTime _admissionDate = DateTime.now();

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _jobRolesStream = widget.jobRoleService.getJobRoles();
    _sectorsStream = widget.sectorService.getSectors();
    final e = widget.employee;
    if (e != null) {
      _nameCtrl.text = e.name;
      _emailCtrl.text = e.email;
      _phoneCtrl.text = e.phone;
      _cpfCtrl.text = e.cpf;
      _ctpsCtrl.text = e.ctps;
      _jobTitleCtrl.text = e.jobTitle;
      _selectedJobRoleId = e.jobRoleId;
      _selectedSector = e.sector;
      if (widget.canViewSalary) {
        _salaryCtrl.text = e.baseSalary.toStringAsFixed(2);
      }
      _educationCtrl.text = e.educationLevel;
      _coursesCtrl.text = e.courses;
      _role = e.role;
      _status = e.status;
      _admissionDate = e.admissionDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cpfCtrl.dispose();
    _ctpsCtrl.dispose();
    _jobTitleCtrl.dispose();
    _salaryCtrl.dispose();
    _educationCtrl.dispose();
    _coursesCtrl.dispose();
    super.dispose();
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJobRoleId == null || _jobTitleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione um cargo cadastrado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    if (_selectedSector == null || _selectedSector!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione um setor cadastrado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final now = DateTime.now();
    final baseSalary =
        widget.canViewSalary
            ? double.tryParse(_salaryCtrl.text.replaceAll(',', '.')) ?? 0.0
            : widget.employee?.baseSalary ?? 0.0;
    final existing = widget.employee;
    final employee =
        existing == null
            ? EmployeeModel(
              id: '',
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              cpf: _cpfCtrl.text.trim(),
              ctps: _ctpsCtrl.text.trim(),
              jobTitle: _jobTitleCtrl.text.trim(),
              jobRoleId: _selectedJobRoleId,
              sector: _selectedSector!.trim(),
              baseSalary: baseSalary,
              role: _role,
              admissionDate: _admissionDate,
              status: _status,
              educationLevel: _educationCtrl.text.trim(),
              courses: _coursesCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
            )
            : existing.copyWith(
              name: _nameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              cpf: _cpfCtrl.text.trim(),
              ctps: _ctpsCtrl.text.trim(),
              jobTitle: _jobTitleCtrl.text.trim(),
              jobRoleId: _selectedJobRoleId,
              sector: _selectedSector!.trim(),
              baseSalary: baseSalary,
              role: _role,
              admissionDate: _admissionDate,
              status: _status,
              educationLevel: _educationCtrl.text.trim(),
              courses: _coursesCtrl.text.trim(),
              updatedAt: now,
            );

    try {
      await context.read<TeamController>().saveEmployee(employee);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Funcionário atualizado!' : 'Funcionário cadastrado!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Date Picker ───────────────────────────────────────────────────────────

  Future<void> _pickAdmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder:
          (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accentGold,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _admissionDate = picked);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < ResponsiveLayout.compact;
    final inset = size.width < 420 ? 8.0 : 24.0;
    final padding = ResponsiveLayout.pagePadding(size.width);
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 620.0);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: EdgeInsets.all(inset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth.toDouble(),
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        padding: padding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                    color: AppColors.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Editar Funcionário' : 'Novo Funcionário',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 19 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),

              // Corpo rolável
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Dados Pessoais ──────────────────────────────
                      _SectionLabel(label: 'Dados Pessoais'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _nameCtrl,
                              label: 'Nome Completo',
                              hint: 'Ex: Carlos Silva',
                              validator:
                                  (v) =>
                                      v!.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              controller: _emailCtrl,
                              label: 'E-mail',
                              hint: 'email@empresa.com',
                              keyboardType: TextInputType.emailAddress,
                              validator:
                                  (v) =>
                                      v!.trim().isEmpty
                                          ? 'Informe o e-mail'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _phoneCtrl,
                              label: 'Telefone',
                              hint: '(11) 99999-0000',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Data de admissão
                          Expanded(
                            child: _DatePickerField(
                              label: 'Data de Admissão',
                              date: _admissionDate,
                              onTap: _pickAdmissionDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _cpfCtrl,
                              label: 'CPF',
                              hint: '000.000.000-00',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.-]'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              controller: _ctpsCtrl,
                              label: 'CTPS',
                              hint: 'Carteira de trabalho',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Dados Profissionais ─────────────────────────
                      _SectionLabel(label: 'Dados Profissionais'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildJobRoleField()),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSectorField(
                              hint: 'Ex: Operacional, Técnico',
                              validator:
                                  (v) =>
                                      v!.trim().isEmpty
                                          ? 'Informe o setor'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _salaryCtrl,
                              label: 'Salário (R\$)',
                              hint:
                                  widget.canViewSalary
                                      ? '0.00'
                                      : 'Restrito por permissao',
                              enabled: widget.canViewSalary,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d,.]'),
                                ),
                              ],
                              validator:
                                  widget.canViewSalary
                                      ? (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Informe o salário';
                                        }
                                        if (double.tryParse(
                                              v.replaceAll(',', '.'),
                                            ) ==
                                            null) {
                                          return 'Valor inválido';
                                        }
                                        return null;
                                      }
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown<EmployeeRole>(
                              label: 'Nível Hierárquico',
                              value: _role,
                              items: EmployeeRole.values,
                              itemLabel: (r) => r.label,
                              onChanged: (v) => setState(() => _role = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<EmployeeStatus>(
                        label: 'Status',
                        value: _status,
                        items: EmployeeStatus.values,
                        itemLabel:
                            (s) => switch (s) {
                              EmployeeStatus.ativo => 'Ativo',
                              EmployeeStatus.ferias => 'Em Férias',
                              EmployeeStatus.desligado => 'Desligado',
                              EmployeeStatus.afastado => 'Afastado',
                            },
                        onChanged: (v) => setState(() => _status = v!),
                      ),

                      const SizedBox(height: 24),

                      // ── Qualificação ────────────────────────────────
                      _SectionLabel(label: 'Qualificação'),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _educationCtrl,
                        label: 'Escolaridade',
                        hint: 'Ex: Superior Completo, Técnico, Ensino Médio',
                        validator:
                            (v) =>
                                v!.trim().isEmpty
                                    ? 'Informe a escolaridade'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _coursesCtrl,
                        label: 'Cursos e Certificações (opcional)',
                        hint: 'Ex: NR-18, Gestão de Projetos...',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Ações
              isCompact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSaveAction(),
                      const SizedBox(height: 8),
                      _buildCancelAction(),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        icon:
                            _saving
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                                : Icon(
                                  _isEdit
                                      ? Icons.save_rounded
                                      : Icons.check_rounded,
                                ),
                        label: Text(
                          _isEdit ? 'Salvar alterações' : 'Cadastrar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers de construção ─────────────────────────────────────────────────

  Widget _buildCancelAction() {
    return TextButton(
      onPressed: _saving ? null : () => Navigator.pop(context),
      child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
    );
  }

  Widget _buildSaveAction() {
    return ElevatedButton.icon(
      onPressed: _saving ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      icon:
          _saving
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              )
              : Icon(_isEdit ? Icons.save_rounded : Icons.check_rounded),
      label: Text(
        _isEdit ? 'Salvar alteraÃ§Ãµes' : 'Cadastrar',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentGold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildJobRoleField() {
    return StreamBuilder<List<JobRoleModel>>(
      stream: _jobRolesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildJobRoleMessageField('Erro ao carregar cargos');
        }

        if (!snapshot.hasData) {
          return _buildJobRoleMessageField('Carregando cargos...');
        }

        final roles =
            snapshot.data!.where((role) => role.isActive).toList()..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
        final selectedRole = _resolveSelectedJobRole(roles);
        final selectedId = selectedRole?.id;

        if (selectedRole != null && _selectedJobRoleId != selectedRole.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _applyJobRole(selectedRole));
          });
        }

        return KeyedSubtree(
          key: const ValueKey('employee-job-role-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey(
              'employee-job-role-${roles.map((role) => role.id).join('|')}-$selectedId',
            ),
            initialValue: selectedId,
            isExpanded: true,
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(color: Colors.white),
            decoration: _jobRoleDecoration(),
            items:
                roles
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role.id,
                        child: Text(role.title),
                      ),
                    )
                    .toList(),
            onChanged:
                roles.isEmpty ? null : (value) => _selectJobRole(value, roles),
            validator: (value) {
              if (roles.isEmpty) return 'Cadastre um cargo ativo';
              if (value == null || value.isEmpty) return 'Selecione o cargo';
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _buildSectorField({
    String? hint,
    String? Function(String?)? validator,
  }) {
    return StreamBuilder<List<SectorModel>>(
      stream: _sectorsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildSectorMessageField('Erro ao carregar setores');
        }

        if (!snapshot.hasData) {
          return _buildSectorMessageField('Carregando setores...');
        }

        final sectors =
            snapshot.data!.where((sector) => sector.isActive).toList()..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
        final selectedSector = _resolveSelectedSector(sectors);

        if (selectedSector != null && _selectedSector != selectedSector.name) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedSector = selectedSector.name);
          });
        }

        return KeyedSubtree(
          key: const ValueKey('employee-sector-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey(
              'employee-sector-${sectors.map((sector) => sector.name).join('|')}-$selectedSector',
            ),
            initialValue: selectedSector?.name,
            isExpanded: true,
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(color: Colors.white),
            decoration: _sectorDecoration(hintText: hint),
            items:
                sectors
                    .map(
                      (sector) => DropdownMenuItem<String>(
                        value: sector.name,
                        child: Text(sector.name),
                      ),
                    )
                    .toList(),
            onChanged:
                sectors.isEmpty
                    ? null
                    : (value) => setState(() => _selectedSector = value),
            validator: (value) {
              if (value != null) {
                final customError = validator?.call(value);
                if (customError != null) return customError;
              }
              if (sectors.isEmpty) return 'Cadastre um setor ativo';
              if (value == null || value.isEmpty) return 'Selecione o setor';
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _buildSectorMessageField(String message) {
    return InputDecorator(
      decoration: _sectorDecoration(),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _sectorDecoration({String? hintText}) {
    return InputDecoration(
      labelText: 'Setor',
      hintText: hintText ?? 'Selecione um setor cadastrado',
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accentGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  SectorModel? _resolveSelectedSector(List<SectorModel> sectors) {
    final selected = _selectedSector?.trim().toLowerCase();
    if (selected == null || selected.isEmpty) return null;
    for (final sector in sectors) {
      if (sector.name.trim().toLowerCase() == selected) return sector;
    }
    return null;
  }

  Widget _buildJobRoleMessageField(String message) {
    return InputDecorator(
      decoration: _jobRoleDecoration(),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _jobRoleDecoration() {
    return InputDecoration(
      labelText: 'Cargo',
      hintText: 'Selecione um cargo cadastrado',
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accentGold),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _selectJobRole(String? roleId, List<JobRoleModel> roles) {
    final role = _jobRoleById(roles, roleId);
    if (role == null) return;
    setState(() => _applyJobRole(role));
  }

  void _applyJobRole(JobRoleModel role) {
    _selectedJobRoleId = role.id;
    _jobTitleCtrl.text = role.title;
  }

  JobRoleModel? _resolveSelectedJobRole(List<JobRoleModel> roles) {
    final byId = _jobRoleById(roles, _selectedJobRoleId);
    if (byId != null) return byId;

    final title = _jobTitleCtrl.text.trim().toLowerCase();
    if (title.isEmpty) return null;
    for (final role in roles) {
      if (role.title.trim().toLowerCase() == title) {
        return role;
      }
    }
    return null;
  }

  JobRoleModel? _jobRoleById(List<JobRoleModel> roles, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final role in roles) {
      if (role.id == id) return role;
    }
    return null;
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentGold),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Widget auxiliar: campo de data ───────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.04),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: Colors.white38,
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        child: Text(formatted, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─── Label de seção ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
