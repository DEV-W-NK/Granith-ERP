import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/services/client_account_service.dart';
import 'package:project_granith/services/maps_geocoding_service.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/services/team_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../../models/project_model.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';
import 'package:project_granith/widgets/projects/keep_alive.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project;
  final Function(Project) onSave;
  final ServiceProjetos? projectService;
  final ClientAccountService? clientAccountService;
  final TeamService? teamService;
  final MapsGeocodingService? geocodingService;

  const ProjectFormDialog({
    super.key,
    this.project,
    required this.onSave,
    this.projectService,
    this.clientAccountService,
    this.teamService,
    this.geocodingService,
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  late TextEditingController _nameController;
  late TextEditingController _clientController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _geofenceSideController;
  late TextEditingController _budgetController;
  late TextEditingController _currentCostController;
  late TextEditingController _teamSizeController;

  File? _selectedFile;
  Uint8List? _selectedImageWeb;
  Uint8List? _webImage;

  late final ServiceProjetos _service;
  late final ClientAccountService _clientAccountService;
  late final TeamService _teamService;
  late final MapsGeocodingService _geocodingService;
  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _tags = [];
  List<ClientAccount> _clientAccounts = [];
  List<EmployeeModel> _coordinators = [];
  String? _selectedClientAccountId;
  String? _selectedCoordinatorId;
  bool _isLoadingCoordinators = true;
  bool _isGeocoding = false;
  String? _geocodedAddress;

  // Estados de controle melhorados
  bool _isSaving = false;
  bool _operationCompleted = false;
  DateTime? _lastSaveAttempt;
  Timer? _debounceTimer;
  int _currentPage = 0;

  // Animação
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Constantes para controle de timing
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _minimumTimeBetweenSaves = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _service = widget.projectService ?? ServiceProjetos();
    _clientAccountService =
        widget.clientAccountService ?? ClientAccountService();
    _teamService = widget.teamService ?? TeamService();
    _geocodingService = widget.geocodingService ?? MapsGeocodingService();
    _initializeControllers();
    _initializeProjectData();
    _initializeAnimations();
    _loadClientAccounts();
    _listenCoordinators();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _clientController = TextEditingController(
      text: widget.project?.client ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.project?.location ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.project?.latitude?.toStringAsFixed(6) ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.project?.longitude?.toStringAsFixed(6) ?? '',
    );
    _geofenceSideController = TextEditingController(
      text: (widget.project?.geofenceSideMeters ?? 120).toStringAsFixed(0),
    );
    _budgetController = TextEditingController(
      text: widget.project?.budget.toString() ?? '',
    );
    _currentCostController = TextEditingController(
      text: widget.project?.currentCost.toString() ?? '',
    );
    _teamSizeController = TextEditingController(
      text: widget.project?.teamSize.toString() ?? '',
    );
  }

  void _initializeProjectData() {
    if (widget.project != null) {
      _selectedStatus = widget.project!.status;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _tags = List.from(widget.project!.tags);
      _selectedClientAccountId = widget.project!.clientAccountId;
      _selectedCoordinatorId = widget.project!.coordinatorId;
    }
  }

  Future<void> _loadClientAccounts() async {
    try {
      final accounts = await _clientAccountService.getClientAccounts();
      if (!mounted) return;
      setState(() {
        _clientAccounts = accounts;
        if (_selectedClientAccountId == null &&
            widget.project == null &&
            accounts.length == 1) {
          _selectedClientAccountId = accounts.first.id;
          _clientController.text = accounts.first.name;
        }
      });
    } catch (_) {
      // Mantem o formulario operando mesmo sem a lista.
    }
  }

  void _listenCoordinators() {
    _employeesSubscription = _teamService.getEmployees().listen(
      (employees) {
        final coordinators =
            employees
                .where(
                  (employee) =>
                      employee.isActive &&
                      employee.role == EmployeeRole.coordenador,
                )
                .toList()
              ..sort(
                (left, right) =>
                    left.name.toLowerCase().compareTo(right.name.toLowerCase()),
              );

        if (!mounted) return;
        setState(() {
          _coordinators = coordinators;
          _isLoadingCoordinators = false;
          if (_selectedCoordinatorId == null &&
              widget.project == null &&
              coordinators.length == 1) {
            _selectedCoordinatorId = coordinators.first.id;
          }
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isLoadingCoordinators = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _employeesSubscription?.cancel();
    _slideController.dispose();
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _geofenceSideController.dispose();
    _budgetController.dispose();
    _currentCostController.dispose();
    _teamSizeController.dispose();
    if (widget.geocodingService == null) {
      _geocodingService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;
    final inset = size.width < 420 ? 8.0 : (isDesktop ? 40.0 : 16.0);
    final padding =
        size.width < 380
            ? 12.0
            : isDesktop
            ? 24.0
            : 16.0;
    final dialogWidth = (size.width - inset * 2).clamp(320.0, 820.0);
    final dialogHeight = size.height * (size.width < 420 ? 0.94 : 0.88);

    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.3),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(inset),
        child: Container(
          width: dialogWidth.toDouble(),
          height: dialogHeight,
          decoration: AppDecorations.dialogSurface(
            glowColor: AppColors.accentGold,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ocupa apenas o necessário
            children: [
              _buildEnhancedHeader(padding),
              _buildProgressIndicator(padding),
              Expanded(child: _buildPageView(padding)),
              _buildEnhancedActions(padding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: AppDecorations.dialogHeader(accent: AppColors.accentGold),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              widget.project != null
                  ? Icons.edit_outlined
                  : Icons.add_business_outlined,
              color: AppColors.accentGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project != null ? 'Editar Projeto' : 'Novo Projeto',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.project != null
                      ? 'Ajuste dados, coordenador e parametros da obra'
                      : 'Cadastre a obra com responsavel definido',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _canClose() ? () => Navigator.pop(context) : null,
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              tooltip: _isSaving ? 'Aguarde a conclusão' : 'Fechar',
              splashRadius: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      child: Row(
        children: [
          _buildProgressStep(0, 'Base', Icons.assignment_ind_outlined),
          _buildProgressConnector(0),
          _buildProgressStep(1, 'Operacao', Icons.tune_rounded),
          _buildProgressConnector(1),
          _buildProgressStep(2, 'Revisao', Icons.fact_check_outlined),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentPage >= step;
    final isCurrent = _currentPage == step;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? AppColors.accentGold
                        : AppColors.textMuted.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    isCurrent
                        ? [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primaryDark : AppColors.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressConnector(int step) {
    final isActive = _currentPage > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color:
              isActive
                  ? AppColors.accentGold
                  : AppColors.textMuted.withOpacity(0.15),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildPageView(double padding) {
    return PageView(
      controller: _pageController,
      physics:
          const NeverScrollableScrollPhysics(), // Evita swipe indesejado se tiver forms longos
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      children: [
        PageKeepAlive(child: _buildBasicInfoPage(padding)),
        PageKeepAlive(child: _buildDetailsPage(padding)),
        PageKeepAlive(child: _buildFinalizePage(padding)),
      ],
    );
  }

  Widget _buildBasicInfoPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Form(
        key: _formKey,
        child: _buildFormSection(
          title: 'Base do projeto',
          icon: Icons.assignment_ind_outlined,
          accent: AppColors.accentGold,
          children: [
            _buildResponsiveFieldRow([
              _buildEnhancedTextField(
                controller: _nameController,
                label: 'Nome do Projeto',
                hint: 'Digite o nome do projeto',
                icon: Icons.work_outline,
                required: true,
              ),
              _buildEnhancedTextField(
                controller: _clientController,
                label: 'Cliente',
                hint: 'Nome do cliente',
                icon: Icons.person_outline,
                required: true,
              ),
            ]),
            if (_clientAccounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildClientAccountDropdown(),
            ],
            const SizedBox(height: 16),
            _buildCoordinatorDropdown(),
            const SizedBox(height: 16),
            _buildEnhancedStatusDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: _buildFormSection(
        title: 'Operacao da obra',
        icon: Icons.tune_rounded,
        accent: AppColors.accentBlue,
        children: [
          _buildLocationGeofenceSection(),
          const SizedBox(height: 16),
          _buildEnhancedDateFields(),
          const SizedBox(height: 16),
          _buildEnhancedFinancialFields(),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _teamSizeController,
            label: 'Tamanho da Equipe',
            hint: 'Número de pessoas',
            icon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizePage(double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: _buildFormSection(
        title: 'Apresentacao e revisao',
        icon: Icons.fact_check_outlined,
        accent: AppColors.accentGreen,
        children: [
          _buildEnhancedImagePicker(),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _descriptionController,
            label: 'Descricao',
            hint: 'Descricao detalhada do projeto',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTagsSection(),
          const SizedBox(height: 24),
          _buildProjectSummary(),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color accent = AppColors.accentGold,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.formPanel(borderColor: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title, icon, accent: accent),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsiveFieldRow(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        if (compact || fields.length == 1) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                fields[i],
                if (i < fields.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              Expanded(child: fields[i]),
              if (i < fields.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _buildClientAccountDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedClientAccountId ?? '',
      dropdownColor: AppColors.secondaryDark,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: granithInputDecoration(
        hint: 'Sem vinculo de portal',
        icon: Icons.account_circle_outlined,
        accentColor: AppColors.accentGold,
      ).copyWith(labelText: 'Conta do cliente no portal'),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Sem vinculo de portal'),
        ),
        ..._clientAccounts.map(
          (account) => DropdownMenuItem<String>(
            value: account.id,
            child: Text(account.name),
          ),
        ),
      ],
      onChanged:
          _canInteract()
              ? (value) {
                setState(() {
                  _selectedClientAccountId =
                      value == null || value.isEmpty ? null : value;
                  final selectedAccount = _clientAccounts
                      .cast<ClientAccount?>()
                      .firstWhere(
                        (account) => account?.id == _selectedClientAccountId,
                        orElse: () => null,
                      );
                  if (selectedAccount != null) {
                    _clientController.text = selectedAccount.name;
                  }
                });
              }
              : null,
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    Color accent = AppColors.accentGold,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: AppDecorations.iconTile(accent),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationGeofenceSection() {
    final hasPoint =
        _latitudeController.text.trim().isNotEmpty &&
        _longitudeController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.accentGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Localizacao da obra',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasPoint)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.28),
                    ),
                  ),
                  child: const Text(
                    'Ponto gerado',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEnhancedTextField(
            controller: _locationController,
            label: 'Endereco da obra',
            hint: 'Rua, numero, bairro, cidade',
            icon: Icons.home_work_outlined,
            required: true,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _canInteract() && !_isGeocoding ? _geocodeLocation : null,
              icon:
                  _isGeocoding
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.manage_search_rounded, size: 18),
              label: Text(
                _isGeocoding
                    ? 'Buscando ponto...'
                    : 'Converter endereco em ponto',
              ),
            ),
          ),
          if (_geocodedAddress != null) ...[
            const SizedBox(height: 8),
            Text(
              _geocodedAddress!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              final fields = [
                _buildEnhancedTextField(
                  controller: _latitudeController,
                  label: 'Latitude',
                  hint: '-23.550520',
                  icon: Icons.south_america_rounded,
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                _buildEnhancedTextField(
                  controller: _longitudeController,
                  label: 'Longitude',
                  hint: '-46.633308',
                  icon: Icons.explore_outlined,
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                _buildEnhancedTextField(
                  controller: _geofenceSideController,
                  label: 'Lado da cerca (m)',
                  hint: '120',
                  icon: Icons.straighten_rounded,
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      if (i < fields.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    Expanded(child: fields[i]),
                    if (i < fields.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children:
                required
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.accentRed),
                      ),
                    ]
                    : null,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: _canInteract(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: granithInputDecoration(
              hint: hint,
              icon: icon,
              accentColor: AppColors.accentGold,
            ),
            validator:
                required
                    ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Este campo é obrigatório';
                      }
                      return null;
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedImagePicker() {
    Widget imageWidget = _buildImageWidget();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagem do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canInteract() ? _pickImage : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.accentGold.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selecionar Imagem',
                      style: TextStyle(
                        color: AppColors.accentGold.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    const double imageHeight = 130.0; // Altura otimizada para o card

    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedFile != null) {
      return Image.file(
        _selectedFile!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.project?.imageUrl != null) {
      return Image.network(
        widget.project!.imageUrl!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(imageHeight, isError: true);
        },
      );
    } else {
      return _buildPlaceholderImage(imageHeight);
    }
  }

  Widget _buildPlaceholderImage(double height, {bool isError = false}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryDark.withOpacity(0.5),
            AppColors.primaryDark.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError
                  ? Icons.broken_image_outlined
                  : Icons.add_photo_alternate_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              isError ? 'Erro ao carregar' : 'Adicionar imagem',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<ProjectStatus>(
            initialValue: _selectedStatus,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            dropdownColor: AppColors.secondaryDark,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.flag_outlined,
                  color: AppColors.accentGold.withOpacity(0.7),
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              filled: true,
              fillColor: AppColors.secondaryDark.withOpacity(0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentGold,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
            items:
                ProjectStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: status.color.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(status.displayName),
                      ],
                    ),
                  );
                }).toList(),
            onChanged:
                _canInteract()
                    ? (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    }
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatorDropdown() {
    final selectedId = _selectedCoordinatorId?.trim();
    final currentCoordinatorLoaded = _coordinators.any(
      (employee) => employee.id == selectedId,
    );
    final hasMissingCurrent =
        selectedId != null &&
        selectedId.isNotEmpty &&
        !currentCoordinatorLoaded;
    final selectedValue =
        selectedId != null && selectedId.isNotEmpty ? selectedId : null;
    final selectedCoordinator = _selectedCoordinator;
    final dropdownItems = <DropdownMenuItem<String>>[
      if (hasMissingCurrent)
        DropdownMenuItem<String>(
          value: selectedId,
          child: Text(
            widget.project?.coordinatorName?.trim().isNotEmpty == true
                ? '${widget.project!.coordinatorName} (atual)'
                : 'Coordenador atual',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ..._coordinators.map(
        (employee) => DropdownMenuItem<String>(
          value: employee.id,
          child: Text(
            employee.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Coordenador Responsavel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.accentRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const ValueKey('project-coordinator-dropdown'),
          initialValue: selectedValue,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          dropdownColor: AppColors.secondaryDark,
          menuMaxHeight: 340,
          decoration: InputDecoration(
            hintText:
                _isLoadingCoordinators
                    ? 'Carregando coordenadores...'
                    : dropdownItems.isEmpty
                    ? 'Nenhum coordenador ativo cadastrado'
                    : 'Selecione o coordenador da obra',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Icons.verified_user_outlined,
                color: AppColors.accentGold.withOpacity(0.7),
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            filled: true,
            fillColor: AppColors.secondaryDark.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
          items: dropdownItems,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              if (_coordinators.isEmpty && !hasMissingCurrent) {
                return 'Cadastre um coordenador ativo antes de criar a obra';
              }
              return 'Selecione o coordenador responsavel';
            }
            return null;
          },
          onChanged:
              _canInteract() && dropdownItems.isNotEmpty
                  ? (value) => setState(() => _selectedCoordinatorId = value)
                  : null,
        ),
        const SizedBox(height: 10),
        _buildCoordinatorHint(selectedCoordinator, hasMissingCurrent),
      ],
    );
  }

  Widget _buildCoordinatorHint(
    EmployeeModel? selectedCoordinator,
    bool hasMissingCurrent,
  ) {
    if (_isLoadingCoordinators) {
      return _buildInlineNotice(
        icon: Icons.sync_rounded,
        text: 'Carregando colaboradores de coordenacao.',
        color: AppColors.accentBlue,
      );
    }

    if (selectedCoordinator != null) {
      final details = [
        selectedCoordinator.jobTitle,
        selectedCoordinator.sector,
      ].where((item) => item.trim().isNotEmpty).join(' - ');

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.formHintPanel(color: AppColors.accentGold),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCoordinator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (hasMissingCurrent) {
      return _buildInlineNotice(
        icon: Icons.info_outline_rounded,
        text: 'Coordenador atual mantido. Selecione outro ativo para alterar.',
        color: AppColors.accentGold,
      );
    }

    return _buildInlineNotice(
      icon: Icons.priority_high_rounded,
      text:
          _coordinators.isEmpty
              ? 'Sem coordenadores ativos disponiveis para novas obras.'
              : 'Defina o responsavel antes de concluir o cadastro.',
      color: AppColors.accentRed,
    );
  }

  Widget _buildInlineNotice({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.formHintPanel(color: color),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDateFields() {
    return _buildResponsiveFieldRow([
      _buildEnhancedDateField(
        'Data de Inicio',
        _startDate,
        true,
        Icons.play_arrow_outlined,
      ),
      _buildEnhancedDateField(
        'Data Prevista',
        _endDate,
        false,
        Icons.flag_outlined,
      ),
    ]);
  }

  Widget _buildEnhancedDateField(
    String label,
    DateTime? date,
    bool isRequired,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            children:
                isRequired
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.accentRed),
                      ),
                    ]
                    : null,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: AppColors.secondaryDark.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _canInteract() ? () => _selectDate(isRequired) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: AppColors.accentGold.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        date != null
                            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                            : 'Selecionar',
                        style: TextStyle(
                          color:
                              date != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFinancialFields() {
    return _buildResponsiveFieldRow([
      _buildEnhancedTextField(
        controller: _budgetController,
        label: 'Orcamento',
        hint: 'R\$ 0,00',
        icon: Icons.account_balance_wallet_outlined,
        keyboardType: TextInputType.number,
      ),
      _buildEnhancedTextField(
        controller: _currentCostController,
        label: 'Custo Atual',
        hint: 'R\$ 0,00',
        icon: Icons.monetization_on_outlined,
        keyboardType: TextInputType.number,
      ),
    ]);
  }

  Widget _buildEnhancedTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  _tags.map((tag) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentGold.withOpacity(0.2),
                            AppColors.accentGold.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentGold.withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_canInteract()) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.accentGold.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canInteract() ? _showAddTagDialog : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: AppColors.accentGold.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Adicionar Tag',
                      style: TextStyle(
                        color: AppColors.accentGold.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.3),
            AppColors.accentGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_outlined,
                color: AppColors.accentGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Resumo do Projeto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Nome',
            _nameController.text.isNotEmpty
                ? _nameController.text
                : 'Não informado',
          ),
          _buildSummaryItem(
            'Cliente',
            _clientController.text.isNotEmpty
                ? _clientController.text
                : 'Não informado',
          ),
          _buildSummaryItem('Status', _selectedStatus.displayName),
          _buildSummaryItem(
            'Coordenador',
            _selectedCoordinatorName ?? 'Nao informado',
          ),
          _buildSummaryItem(
            'Local',
            _locationController.text.isNotEmpty
                ? _locationController.text
                : 'Nao informado',
          ),
          if (_latitudeController.text.isNotEmpty &&
              _longitudeController.text.isNotEmpty)
            _buildSummaryItem(
              'Cerca',
              '${_latitudeController.text}, ${_longitudeController.text} '
                  '(${_geofenceSideController.text} m)',
            ),
          if (_budgetController.text.isNotEmpty)
            _buildSummaryItem('Orçamento', 'R\$ ${_budgetController.text}'),
          if (_tags.isNotEmpty) _buildSummaryItem('Tags', _tags.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActions(double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.9),
            AppColors.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Navegação entre páginas
          if (_currentPage < 2)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Anterior'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  )
                else
                  const SizedBox(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_currentPage == 0 &&
                        !_formKey.currentState!.validate()) {
                      return;
                    }
                    if (_currentPage == 1 && !_validateProjectLocation()) {
                      return;
                    }
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Próximo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            )
          else
            // Ações finais
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Anterior'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed:
                          _canClose() ? () => Navigator.pop(context) : null,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            _canClose()
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _canSave() ? _handleSaveWithDebounce : null,
                      icon: _buildSaveButtonContent(),
                      label: Text(
                        widget.project != null
                            ? 'Salvar Projeto'
                            : 'Criar Projeto',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.primaryDark,
                        disabledBackgroundColor: AppColors.textMuted
                            .withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: _canSave() ? 3 : 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButtonContent() {
    if (_isSaving) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
        ),
      );
    }
    return Icon(
      widget.project != null
          ? Icons.save_outlined
          : Icons.add_business_outlined,
      size: 18,
    );
  }

  // Métodos auxiliares mantidos do código original
  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _selectedImageWeb = result.files.single.bytes;
            _webImage = result.files.single.bytes;
          });
        }
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          setState(() {
            _selectedFile = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      _showErrorMessage('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    if (!_canInteract()) return;

    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _showAddTagDialog() {
    if (!_canInteract()) return;

    String newTag = '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Adicionar Tag',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nome da tag',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.secondaryDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accentGold),
                ),
              ),
              onChanged: (value) => newTag = value,
              onSubmitted: (_) => _addTag(newTag),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => _addTag(newTag),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: const Text('Adicionar'),
              ),
            ],
          ),
    );
  }

  void _addTag(String newTag) {
    if (newTag.trim().isNotEmpty && !_tags.contains(newTag.trim())) {
      setState(() {
        _tags.add(newTag.trim());
      });
    }
    Navigator.pop(context);
  }

  // Métodos de controle de estado mantidos
  bool _canSave() => !_isSaving && !_operationCompleted;
  bool _canClose() => !_isSaving;
  bool _canInteract() => !_isSaving;

  bool _isTimingValid() {
    if (_lastSaveAttempt == null) return true;
    return DateTime.now().difference(_lastSaveAttempt!) >=
        _minimumTimeBetweenSaves;
  }

  void _handleSaveWithDebounce() {
    if (!_canSave() || !_isTimingValid()) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted && _canSave()) {
        _saveProject();
      }
    });
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _saveProject() async {
    if (_isSaving || _operationCompleted) return;

    final formValid = _formKey.currentState?.validate() ?? true;
    if (!formValid) {
      _goToPage(0);
      return;
    }
    if (!_validateProjectLocation()) return;

    _lastSaveAttempt = DateTime.now();

    setState(() {
      _isSaving = true;
    });

    try {
      final projectData = await _prepareProjectData();

      if (widget.project == null) {
        await _createNewProject(projectData);
      } else {
        await _updateExistingProject(projectData);
      }

      _operationCompleted = true;
      widget.onSave(projectData);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _handleSaveError(e);
    } finally {
      if (mounted && !_operationCompleted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Project> _prepareProjectData() async {
    String? imageUrl;
    String projectId = widget.project?.id ?? _generateProjectId();
    final selectedCoordinator = _selectedCoordinator;
    final coordinatorId = _selectedCoordinatorId?.trim();

    if (coordinatorId == null || coordinatorId.isEmpty) {
      throw StateError('Selecione o coordenador responsavel pela obra.');
    }

    if (_selectedFile != null || _selectedImageWeb != null) {
      try {
        imageUrl = await _service.uploadProjectImage(
          file: _selectedFile,
          webData: _selectedImageWeb,
          projectId: projectId,
          replaceExisting: true,
        );
      } catch (e) {
        print('Aviso: Erro no upload da imagem - $e');
        imageUrl = widget.project?.imageUrl;
      }
    } else {
      imageUrl = widget.project?.imageUrl;
    }

    return Project(
      id: projectId,
      name: _nameController.text.trim(),
      client: _clientController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
      budget: _parseDouble(_budgetController.text),
      currentCost: _parseDouble(_currentCostController.text),
      location: _locationController.text.trim(),
      latitude: _parseNullableDouble(_latitudeController.text),
      longitude: _parseNullableDouble(_longitudeController.text),
      geofenceSideMeters: _parseDouble(_geofenceSideController.text),
      tags: List.from(_tags),
      teamSize: _parseInt(_teamSizeController.text),
      imageUrl: imageUrl,
      clientAccountId: _selectedClientAccountId,
      clientAccountName:
          _clientAccounts
              .cast<ClientAccount?>()
              .firstWhere(
                (account) => account?.id == _selectedClientAccountId,
                orElse: () => null,
              )
              ?.name,
      coordinatorId: coordinatorId,
      coordinatorName:
          selectedCoordinator?.name ??
          (coordinatorId == widget.project?.coordinatorId
              ? widget.project?.coordinatorName
              : null),
      estimatedProgress: widget.project?.estimatedProgress ?? 0,
      measuredAmount: widget.project?.measuredAmount ?? 0,
      measurementCount: widget.project?.measurementCount ?? 0,
      lastMeasurementAt: widget.project?.lastMeasurementAt,
    );
  }

  Future<void> _createNewProject(Project project) async {
    await _service.addProject(project);
  }

  EmployeeModel? get _selectedCoordinator {
    for (final coordinator in _coordinators) {
      if (coordinator.id == _selectedCoordinatorId) return coordinator;
    }
    return null;
  }

  String? get _selectedCoordinatorName {
    final selected = _selectedCoordinator;
    if (selected != null) return selected.name;
    if (_selectedCoordinatorId == widget.project?.coordinatorId) {
      return widget.project?.coordinatorName;
    }
    return null;
  }

  Future<void> _updateExistingProject(Project project) async {
    await _service.updateProject(project);
  }

  String _generateProjectId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  Future<void> _geocodeLocation() async {
    final address = _locationController.text.trim();
    if (address.isEmpty) {
      _showErrorMessage('Informe o endereco da obra antes de buscar o ponto.');
      return;
    }

    setState(() => _isGeocoding = true);
    try {
      final result = await _geocodingService.geocodeAddress(address);
      if (!mounted) return;
      if (result == null) {
        _showErrorMessage('Nenhum ponto encontrado para este endereco.');
        return;
      }

      setState(() {
        _locationController.text =
            result.formattedAddress.isEmpty ? address : result.formattedAddress;
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
        _geocodedAddress = result.formattedAddress;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Erro ao buscar coordenada: $e');
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  bool _validateProjectLocation() {
    final address = _locationController.text.trim();
    final hasLocationInput =
        address.isNotEmpty ||
        _latitudeController.text.trim().isNotEmpty ||
        _longitudeController.text.trim().isNotEmpty;
    final latitude = _parseNullableDouble(_latitudeController.text);
    final longitude = _parseNullableDouble(_longitudeController.text);
    final side = _parseNullableDouble(_geofenceSideController.text);

    if (!hasLocationInput) return true;

    if (address.isEmpty) {
      _showErrorMessage('Informe o endereco da obra.');
      return false;
    }
    if (latitude == null || latitude < -90 || latitude > 90) {
      _showErrorMessage('Informe uma latitude valida para a obra.');
      return false;
    }
    if (longitude == null || longitude < -180 || longitude > 180) {
      _showErrorMessage('Informe uma longitude valida para a obra.');
      return false;
    }
    if (side == null || side <= 0) {
      _showErrorMessage('Informe o tamanho da cerca em metros.');
      return false;
    }
    return true;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  double? _parseNullableDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  void _handleSaveError(dynamic error) {
    print('Erro ao salvar projeto: $error');

    if (mounted) {
      _showErrorMessage('Erro ao salvar projeto: $error');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accentRed,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
