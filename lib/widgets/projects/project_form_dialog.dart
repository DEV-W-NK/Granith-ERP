import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_granith/Services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../../models/project_model.dart';
import 'package:project_granith/widgets/projects/keep_alive.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project;
  final Function(Project) onSave;

  const ProjectFormDialog({super.key, this.project, required this.onSave});

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
  late TextEditingController _budgetController;
  late TextEditingController _currentCostController;
  late TextEditingController _teamSizeController;

  File? _selectedFile;
  Uint8List? _selectedImageWeb;
  Uint8List? _webImage;

  final ServiceProjetos _service = ServiceProjetos();

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _tags = [];

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
    _initializeControllers();
    _initializeProjectData();
    _initializeAnimations();
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
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _slideController.dispose();
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _currentCostController.dispose();
    _teamSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.3),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isDesktop ? 40 : 16),
        child: Container(
          width: isDesktop ? 800 : double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: 600,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceDark,
                AppColors.surfaceDark.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEnhancedHeader(),
              _buildProgressIndicator(),
              Expanded(child: _buildPageView()),
              _buildEnhancedActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryDark.withBlue(20)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
              size: 24,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.project != null
                      ? 'Modifique as informações do projeto'
                      : 'Preencha os dados para criar um novo projeto',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Básico', Icons.info_outline),
          _buildProgressConnector(0),
          _buildProgressStep(1, 'Detalhes', Icons.settings_outlined),
          _buildProgressConnector(1),
          _buildProgressStep(2, 'Finalizar', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentPage >= step;
    final isCurrent = _currentPage == step;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? AppColors.accentGold
                        : AppColors.textMuted.withOpacity(0.2),
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
                  : AppColors.textMuted.withOpacity(0.2),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      children: [
        PageKeepAlive(child: _buildBasicInfoPage()),
        PageKeepAlive(child: _buildDetailsPage()),
        PageKeepAlive(child: _buildFinalizePage()),
      ],
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informações Básicas', Icons.business_outlined),
            const SizedBox(height: 24),
            _buildEnhancedTextField(
              controller: _nameController,
              label: 'Nome do Projeto',
              hint: 'Digite o nome do projeto',
              icon: Icons.work_outline,
              required: true,
            ),
            const SizedBox(height: 20),
            _buildEnhancedTextField(
              controller: _clientController,
              label: 'Cliente',
              hint: 'Nome do cliente',
              icon: Icons.person_outline,
              required: true,
            ),
            const SizedBox(height: 20),
            _buildEnhancedImagePicker(),
            const SizedBox(height: 20),
            _buildEnhancedTextField(
              controller: _descriptionController,
              label: 'Descrição',
              hint: 'Descrição detalhada do projeto',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Detalhes do Projeto', Icons.settings_outlined),
          const SizedBox(height: 24),
          _buildEnhancedStatusDropdown(),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: _locationController,
            label: 'Localização',
            hint: 'Endereço da obra',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),
          _buildEnhancedDateFields(),
          const SizedBox(height: 20),
          _buildEnhancedFinancialFields(),
          const SizedBox(height: 20),
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

  Widget _buildFinalizePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Finalização', Icons.check_circle_outline),
          const SizedBox(height: 24),
          _buildEnhancedTagsSection(),
          const SizedBox(height: 32),
          _buildProjectSummary(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accentGold, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
              fontSize: 14,
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
        const SizedBox(height: 10),
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textMuted.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: AppColors.accentGold.withOpacity(0.7),
                  size: 20,
                ),
              ),
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
              contentPadding: const EdgeInsets.all(20),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accentGold.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canInteract() ? _pickImage : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.accentGold.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selecionar Imagem',
                      style: TextStyle(
                        color: AppColors.accentGold.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
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
    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedFile != null) {
      return Image.file(
        _selectedFile!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (widget.project?.imageUrl != null) {
      return Image.network(
        widget.project!.imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryDark.withOpacity(0.5),
                  AppColors.primaryDark.withOpacity(0.3),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondaryDark.withOpacity(0.5),
              AppColors.primaryDark.withOpacity(0.3),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              SizedBox(height: 8),
              Text(
                'Adicionar imagem',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEnhancedStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
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
            value: _selectedStatus,
            style: const TextStyle(color: AppColors.textPrimary),
            dropdownColor: AppColors.secondaryDark,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.flag_outlined,
                  color: AppColors.accentGold.withOpacity(0.7),
                  size: 20,
                ),
              ),
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
                vertical: 20,
                horizontal: 20,
              ),
            ),
            items:
                ProjectStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
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
                        const SizedBox(width: 12),
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

  Widget _buildEnhancedDateFields() {
    return Row(
      children: [
        Expanded(
          child: _buildEnhancedDateField(
            'Data de Início',
            _startDate,
            true,
            Icons.play_arrow_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEnhancedDateField(
            'Data Prevista',
            _endDate,
            false,
            Icons.flag_outlined,
          ),
        ),
      ],
    );
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
              fontSize: 14,
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
        const SizedBox(height: 10),
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: AppColors.accentGold.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      date != null
                          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                          : 'Selecionar data',
                      style: TextStyle(
                        color:
                            date != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
    return Row(
      children: [
        Expanded(
          child: _buildEnhancedTextField(
            controller: _budgetController,
            label: 'Orçamento',
            hint: 'R\$ 0,00',
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEnhancedTextField(
            controller: _currentCostController,
            label: 'Custo Atual',
            hint: 'R\$ 0,00',
            icon: Icons.monetization_on_outlined,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
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
                          horizontal: 12,
                          vertical: 6,
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
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
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
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accentGold.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _canInteract() ? _showAddTagDialog : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: AppColors.accentGold.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Adicionar Tag',
                      style: TextStyle(
                        color: AppColors.accentGold.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.3),
            AppColors.accentGold.withOpacity(0.1),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Resumo do Projeto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          if (_budgetController.text.isNotEmpty)
            _buildSummaryItem('Orçamento', 'R\$ ${_budgetController.text}'),
          if (_tags.isNotEmpty) _buildSummaryItem('Tags', _tags.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActions() {
    return Container(
      padding: const EdgeInsets.all(28),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
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
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Próximo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Anterior'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                Row(
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
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
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
                          horizontal: 24,
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
        width: 16,
        height: 16,
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

  Future<void> _saveProject() async {
    if (_isSaving || _operationCompleted) return;

    // Add null check for form state
    if (_formKey.currentState?.validate() == false) return;

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
      tags: List.from(_tags),
      teamSize: _parseInt(_teamSizeController.text),
      imageUrl: imageUrl,
    );
  }

  Future<void> _createNewProject(Project project) async {
    await _service.addProject(project);
  }

  Future<void> _updateExistingProject(Project project) async {
    await _service.updateProject(project);
  }

  String _generateProjectId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
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
