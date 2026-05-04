import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/models/diario_obra_model.dart'; // Ajuste o import conforme necessário
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';

// Widget utilitário para manter o estado das páginas do PageView
class PageKeepAlive extends StatefulWidget {
  final Widget child;
  const PageKeepAlive({super.key, required this.child});
  @override
  State<PageKeepAlive> createState() => _PageKeepAliveState();
}

class _PageKeepAliveState extends State<PageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class DailyLogFormDialog extends StatefulWidget {
  final DailyLogModel? log;

  const DailyLogFormDialog({super.key, this.log});

  @override
  State<DailyLogFormDialog> createState() => _DailyLogFormDialogState();
}

class _DailyLogFormDialogState extends State<DailyLogFormDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  // Controladores de Texto
  final TextEditingController _activitiesController = TextEditingController();
  final TextEditingController _impedimentsController = TextEditingController();
  final TextEditingController _manpowerController = TextEditingController();

  // Estados dos Campos
  late DateTime _selectedDate;
  String? _selectedProjectId;
  String _selectedProjectName = '';
  WeatherCondition _weatherMorning = WeatherCondition.sol;
  WeatherCondition _weatherAfternoon = WeatherCondition.sol;

  // Fotos
  List<String> _existingPhotoUrls = [];
  List<XFile> _newPhotos = [];

  // Controle de Interface
  int _currentPage = 0;
  bool _isSaving =
      false; // Controle local de loading para evitar conflito com provider

  // Animação de Entrada
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsController>().loadProjects();
    });
  }

  void _initializeData() {
    if (widget.log != null) {
      _selectedDate = widget.log!.date;
      _selectedProjectId = widget.log!.projectId;
      _selectedProjectName = widget.log!.projectName;
      _weatherMorning = widget.log!.weatherMorning;
      _weatherAfternoon = widget.log!.weatherAfternoon;
      _activitiesController.text = widget.log!.activitiesDescription;
      _impedimentsController.text = widget.log!.impediments;
      _manpowerController.text =
          widget.log!.manpower.values
              .fold(0, (sum, val) => sum + val)
              .toString();
      _existingPhotoUrls = List.from(widget.log!.photoUrls);
    } else {
      _selectedDate = DateTime.now();
    }
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

  @override
  void dispose() {
    _slideController.dispose();
    _pageController.dispose();
    _activitiesController.dispose();
    _impedimentsController.dispose();
    _manpowerController.dispose();
    super.dispose();
  }

  // --- Lógica de Negócio ---

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newPhotos.addAll(images);
        });
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagens: $e');
    }
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate() || _selectedProjectId == null) {
      // Se estiver na primeira página e falhar validação, avisa
      if (_currentPage == 0 && _selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione um projeto para continuar.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newLog = DailyLogModel(
        id: widget.log?.id ?? '',
        projectId: _selectedProjectId!,
        projectName: _selectedProjectName,
        date: _selectedDate,
        weatherMorning: _weatherMorning,
        weatherAfternoon: _weatherAfternoon,
        manpower: {'Geral': int.tryParse(_manpowerController.text) ?? 0},
        activitiesDescription: _activitiesController.text,
        impediments: _impedimentsController.text,
        photoUrls:
            _existingPhotoUrls, // Envia as URLs que restaram (caso tenha deletado alguma)
        createdByUserId: '', // Será preenchido pelo controller/backend
        status: LogStatus.finalized,
      );

      final success = await context
          .read<DailyLogController>()
          .saveLogWithPhotos(newLog, _newPhotos);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Diário salvo com sucesso!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Construção da UI ---

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.5),
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
              Expanded(
                child: Form(
                  // Form envolve o PageView para validar tudo
                  key: _formKey,
                  child: _buildPageView(),
                ),
              ),
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
              widget.log != null ? Icons.edit_note : Icons.post_add,
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
                  widget.log != null ? 'Editar Diário' : 'Novo Diário de Obra',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.log != null
                      ? 'Edite as informações do registro diário.'
                      : 'Preencha os dados do dia de trabalho.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            splashRadius: 20,
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
          _buildProgressStep(0, 'Geral', Icons.info_outline),
          _buildProgressConnector(0),
          _buildProgressStep(1, 'Detalhes', Icons.list_alt),
          _buildProgressConnector(1),
          _buildProgressStep(2, 'Fotos', Icons.camera_alt_outlined),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentPage >= step;
    final isCurrent = _currentPage == step;

    return Expanded(
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
      physics:
          const NeverScrollableScrollPhysics(), // Navegação apenas pelos botões
      onPageChanged: (page) => setState(() => _currentPage = page),
      children: [
        PageKeepAlive(child: _buildGeneralPage()),
        PageKeepAlive(child: _buildDetailsPage()),
        PageKeepAlive(child: _buildPhotosPage()),
      ],
    );
  }

  // --- Páginas do Formulário ---

  Widget _buildGeneralPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Informações Principais',
            Icons.dashboard_outlined,
          ),
          const SizedBox(height: 24),

          // Dropdown de Projetos
          Consumer<ProjectsController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                );
              }
              return _buildEnhancedDropdown<String>(
                label: 'Projeto',
                value: _selectedProjectId,
                hint: 'Selecione o projeto',
                icon: Icons.business,
                items:
                    controller.projects
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                            onTap: () => _selectedProjectName = p.name,
                          ),
                        )
                        .toList(),
                onChanged:
                    widget.log == null
                        ? (val) => setState(() => _selectedProjectId = val)
                        : null, // Desabilita edição de projeto se for edição de log
              );
            },
          ),
          const SizedBox(height: 20),

          // Data
          _buildEnhancedDateField(
            label: 'Data do Registro',
            date: _selectedDate,
            icon: Icons.calendar_today,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder:
                    (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.accentGold,
                          surface: AppColors.surfaceDark,
                        ),
                      ),
                      child: child!,
                    ),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 20),

          // Clima
          _buildSectionTitle(
            'Condições Climáticas',
            Icons.wb_sunny_outlined,
            fontSize: 16,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedDropdown<WeatherCondition>(
                  label: 'Manhã',
                  value: _weatherMorning,
                  icon: Icons.wb_twilight,
                  items:
                      WeatherCondition.values
                          .map(
                            (w) => DropdownMenuItem(
                              value: w,
                              child: Text(
                                w.name,
                              ), // Idealmente use um helper para traduzir
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _weatherMorning = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedDropdown<WeatherCondition>(
                  label: 'Tarde',
                  value: _weatherAfternoon,
                  icon: Icons.wb_sunny,
                  items:
                      WeatherCondition.values
                          .map(
                            (w) =>
                                DropdownMenuItem(value: w, child: Text(w.name)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _weatherAfternoon = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Relatório de Campo', Icons.article_outlined),
          const SizedBox(height: 24),

          _buildEnhancedTextField(
            controller: _activitiesController,
            label: 'Atividades Executadas',
            hint: 'Descreva as atividades realizadas hoje...',
            icon: Icons.construction,
            maxLines: 5,
            required: true,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _manpowerController,
                  label: 'Efetivo (Qtd.)',
                  hint: '0',
                  icon: Icons.groups,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: Container()), // Spacer para layout
            ],
          ),
          const SizedBox(height: 20),

          _buildEnhancedTextField(
            controller: _impedimentsController,
            label: 'Impedimentos / Ocorrências',
            hint: 'Houve algum problema que paralisou a obra?',
            icon: Icons.warning_amber_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(
                'Galeria de Fotos',
                Icons.photo_library_outlined,
              ),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Adicionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold.withOpacity(0.1),
                  foregroundColor: AppColors.accentGold,
                  elevation: 0,
                  side: BorderSide(
                    color: AppColors.accentGold.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              (_existingPhotoUrls.isEmpty && _newPhotos.isEmpty)
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma foto adicionada',
                          style: TextStyle(
                            color: AppColors.textMuted.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemCount: _existingPhotoUrls.length + _newPhotos.length,
                    itemBuilder: (context, index) {
                      if (index < _existingPhotoUrls.length) {
                        // Foto Existente
                        return _buildPhotoTile(
                          imageProvider: NetworkImage(
                            _existingPhotoUrls[index],
                          ),
                          onDelete: () => _removeExistingPhoto(index),
                          isNetwork: true,
                        );
                      } else {
                        // Nova Foto
                        final newIndex = index - _existingPhotoUrls.length;
                        final file = _newPhotos[newIndex];
                        return _buildPhotoTile(
                          imageProvider:
                              kIsWeb
                                  ? NetworkImage(
                                    file.path,
                                  ) // Em web XFile path funciona como URL blob
                                  : FileImage(File(file.path)) as ImageProvider,
                          onDelete: () => _removeNewPhoto(newIndex),
                          isNetwork: false,
                        );
                      }
                    },
                  ),
        ),
      ],
    );
  }

  // --- Widgets Auxiliares "Enhanced" ---

  Widget _buildSectionTitle(
    String title,
    IconData icon, {
    double fontSize = 18,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: fontSize + 2),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary),
          validator:
              required
                  ? (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null
                  : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 8,
                bottom: 2,
              ), // Ajuste para alinhar ícone no topo se multiline
              child: Icon(
                icon,
                color: AppColors.accentGold.withOpacity(0.7),
                size: 20,
              ),
            ),
            // Alinhamento do ícone para campos multiline
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: AppColors.secondaryDark.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentRed,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required String label,
    required T? value,
    String? hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.secondaryDark,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.accentGold.withOpacity(0.7),
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.secondaryDark.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.secondaryDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: AppColors.accentGold.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTile({
    required ImageProvider imageProvider,
    required VoidCallback onDelete,
    required bool isNetwork,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedActions() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed:
                  () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Anterior'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            )
          else
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Cancelar'),
            ),

          if (_currentPage < 2)
            ElevatedButton.icon(
              onPressed: () {
                if (_currentPage == 0) {
                  // Validação básica da página 1 antes de avançar
                  if (_selectedProjectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione um projeto'),
                        backgroundColor: AppColors.accentRed,
                      ),
                    );
                    return;
                  }
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
            )
          else
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveLog,
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      )
                      : const Icon(Icons.check_circle_outlined),
              label: Text(_isSaving ? 'Salvando...' : 'Finalizar Diário'),
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
      ),
    );
  }
}
