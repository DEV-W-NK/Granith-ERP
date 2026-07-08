import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/models/diario_obra_model.dart'; // Ajuste o import conforme necessário
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

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

class _FormInfoPill extends StatelessWidget {
  const _FormInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentGold, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherSelector extends StatelessWidget {
  const _WeatherSelector({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final WeatherCondition selected;
  final ValueChanged<WeatherCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accentGold, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  WeatherCondition.values
                      .map(
                        (condition) => SizedBox(
                          width:
                              compact
                                  ? (constraints.maxWidth - 8) / 2
                                  : (constraints.maxWidth - 24) / 4,
                          child: _WeatherOptionButton(
                            condition: condition,
                            selected: selected == condition,
                            onTap: () => onChanged(condition),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _WeatherOptionButton extends StatelessWidget {
  const _WeatherOptionButton({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final WeatherCondition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _weatherLabel(condition),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? AppColors.accentGold.withValues(alpha: 0.16)
                      : AppColors.surfaceDark.withValues(alpha: 0.44),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected
                        ? AppColors.accentGold.withValues(alpha: 0.44)
                        : AppColors.borderColor.withValues(alpha: 0.42),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _weatherIcon(condition),
                  color: selected ? AppColors.accentGold : AppColors.textMuted,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _weatherLabel(condition),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected
                              ? AppColors.accentGold
                              : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _weatherLabel(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sol:
        return 'Sol';
      case WeatherCondition.nublado:
        return 'Nublado';
      case WeatherCondition.chuvoso:
        return 'Chuva';
      case WeatherCondition.tempestade:
        return 'Tempestade';
    }
  }

  static IconData _weatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sol:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.nublado:
        return Icons.cloud_rounded;
      case WeatherCondition.chuvoso:
        return Icons.water_drop_rounded;
      case WeatherCondition.tempestade:
        return Icons.thunderstorm_rounded;
    }
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
  String? _selectedProjectCoordinatorId;
  String? _selectedProjectCoordinatorName;
  WeatherCondition _weatherMorning = WeatherCondition.sol;
  WeatherCondition _weatherAfternoon = WeatherCondition.sol;

  // Fotos
  List<String> _existingPhotoUrls = [];
  final List<XFile> _newPhotos = [];

  // Controle de Interface
  int _currentPage = 0;
  bool _isSaving =
      false; // Controle local de loading para evitar conflito com provider

  // Animação de Entrada
  bool get _isSignedLog => widget.log?.isSigned ?? false;

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
      _selectedProjectCoordinatorId = widget.log!.coordinatorId;
      _selectedProjectCoordinatorName = widget.log!.coordinatorName;
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
    if (_isSignedLog) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diario assinado nao pode ser editado.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

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
      final hasCoordinator =
          _selectedProjectCoordinatorId != null &&
          _selectedProjectCoordinatorId!.trim().isNotEmpty;
      final isAlreadySigned = widget.log?.isSigned ?? false;
      final logStatus =
          isAlreadySigned
              ? LogStatus.signed
              : hasCoordinator
              ? LogStatus.pendingSignature
              : LogStatus.finalized;

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
        status: logStatus,
        coordinatorId: _selectedProjectCoordinatorId,
        coordinatorName: _selectedProjectCoordinatorName,
        signatureRequestedAt:
            widget.log?.signatureRequestedAt ??
            (hasCoordinator ? DateTime.now().toUtc() : null),
        signedAt: widget.log?.signedAt,
        signedByCoordinatorId: widget.log?.signedByCoordinatorId,
        signedByCoordinatorName: widget.log?.signedByCoordinatorName,
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
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;
    final inset = size.width < 420 ? 8.0 : (isDesktop ? 40.0 : 16.0);
    final dialogWidth = (size.width - inset * 2).clamp(300.0, 800.0);

    if (_isSignedLog) {
      return _buildSignedLogLockedDialog(
        inset: inset,
        dialogWidth: dialogWidth.toDouble(),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(inset),
        child: Container(
          width: dialogWidth.toDouble(),
          constraints: BoxConstraints(
            maxHeight: size.height * (size.width < 420 ? 0.94 : 0.9),
            minHeight: size.height < 720 ? 0 : 520,
          ),
          decoration: AppDecorations.dialogSurface(
            glowColor: AppColors.accentGold,
          ),
          clipBehavior: Clip.antiAlias,
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

  Widget _buildSignedLogLockedDialog({
    required double inset,
    required double dialogWidth,
  }) {
    final signedAt = widget.log?.signedAt;
    final signedAtLabel =
        signedAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(signedAt)
            : 'assinatura registrada';
    final signer =
        widget.log?.signedByCoordinatorName ??
        widget.log?.coordinatorName ??
        'coordenador da obra';

    return SlideTransition(
      position: _slideAnimation,
      child: Dialog(
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(inset),
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.dialogSurface(
            glowColor: AppColors.accentGreen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Diario assinado',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Este relatorio foi assinado por $signer em $signedAtLabel e nao pode mais ser editado.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Entendi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isCompactDialog =>
      MediaQuery.sizeOf(context).width < ResponsiveLayout.compact;

  EdgeInsets get _dialogPadding {
    return ResponsiveLayout.pagePadding(MediaQuery.sizeOf(context).width);
  }

  Widget _buildEnhancedHeader() {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Container(
      padding: _dialogPadding,
      decoration: BoxDecoration(
        color: AppColors.backgroundMid.withValues(alpha: 0.78),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.46),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: _isCompactDialog ? 42 : 48,
            height: _isCompactDialog ? 42 : 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(
              widget.log != null ? Icons.edit_note : Icons.post_add,
              color: AppColors.accentGold,
              size: _isCompactDialog ? 22 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.log != null ? 'Editar Diário' : 'Novo Diário de Obra',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: _isCompactDialog ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _FormInfoPill(
                      icon: Icons.calendar_today_rounded,
                      label: dateLabel,
                    ),
                    if (_selectedProjectName.trim().isNotEmpty)
                      _FormInfoPill(
                        icon: Icons.business_rounded,
                        label: _selectedProjectName,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Fechar',
            child: IconButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.58),
                foregroundColor: AppColors.textSecondary,
                disabledForegroundColor: AppColors.textMuted,
                side: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _dialogPadding.left,
        vertical: _isCompactDialog ? 10 : 12,
      ),
      child: Row(
        children: [
          _buildProgressStep(0, 'Geral', Icons.info_outline),
          const SizedBox(width: 8),
          _buildProgressStep(1, 'Detalhes', Icons.list_alt),
          const SizedBox(width: 8),
          _buildProgressStep(2, 'Fotos', Icons.camera_alt_outlined),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentPage >= step;
    final isCurrent = _currentPage == step;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: _isCompactDialog ? 50 : 56,
        padding: EdgeInsets.symmetric(
          horizontal: _isCompactDialog ? 8 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              isCurrent
                  ? AppColors.accentGold.withValues(alpha: 0.16)
                  : isActive
                  ? AppColors.accentBlue.withValues(alpha: 0.10)
                  : AppColors.surfaceDark.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isCurrent
                    ? AppColors.accentGold.withValues(alpha: 0.44)
                    : AppColors.borderColor.withValues(alpha: 0.42),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isCurrent
                        ? AppColors.accentGold
                        : AppColors.surfaceElevated.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    isCurrent ? AppColors.primaryDark : AppColors.textSecondary,
                size: 16,
              ),
            ),
            if (!_isCompactDialog) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isActive ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepSummary() {
    final labels = ['Geral', 'Detalhes', 'Fotos'];
    return Text(
      'Etapa ${_currentPage + 1} de 3 - ${labels[_currentPage]}',
      style: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.95),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.22),
        disabledForegroundColor: AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        disabledForegroundColor: AppColors.textMuted,
        side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.64)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _fillOnCompact(Widget child) {
    if (!_isCompactDialog) return child;
    return SizedBox(width: double.infinity, child: child);
  }

  Widget _buildFieldShell({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
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
      padding: _dialogPadding,
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
                          ),
                        )
                        .toList(),
                onChanged:
                    widget.log == null
                        ? (val) {
                          final selectedProject = controller.projects
                              .cast<dynamic>()
                              .firstWhere(
                                (project) => project?.id == val,
                                orElse: () => null,
                              );
                          setState(() {
                            _selectedProjectId = val;
                            _selectedProjectName =
                                selectedProject?.name?.toString() ?? '';
                            _selectedProjectCoordinatorId =
                                selectedProject?.coordinatorId?.toString();
                            _selectedProjectCoordinatorName =
                                selectedProject?.coordinatorName?.toString();
                          });
                        }
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
          _responsivePair(
            _WeatherSelector(
              label: 'Manhã',
              icon: Icons.wb_twilight_rounded,
              selected: _weatherMorning,
              onChanged: (value) => setState(() => _weatherMorning = value),
            ),
            _WeatherSelector(
              label: 'Tarde',
              icon: Icons.wb_sunny_rounded,
              selected: _weatherAfternoon,
              onChanged: (value) => setState(() => _weatherAfternoon = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return SingleChildScrollView(
      padding: _dialogPadding,
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

          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: _isCompactDialog ? double.infinity : 240,
              child: _buildEnhancedTextField(
                controller: _manpowerController,
                label: 'Efetivo (Qtd.)',
                hint: '0',
                icon: Icons.groups,
                keyboardType: TextInputType.number,
              ),
            ),
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

  Widget _responsivePair(Widget first, Widget second, {int firstFlex = 1}) {
    if (_isCompactDialog) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }

    return Row(
      children: [
        Expanded(flex: firstFlex, child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildPhotosPage() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            _dialogPadding.left,
            _dialogPadding.top,
            _dialogPadding.right,
            10,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSectionTitle(
                'Galeria de Fotos',
                Icons.photo_library_outlined,
              ),
              FilledButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Adicionar fotos'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              (_existingPhotoUrls.isEmpty && _newPhotos.isEmpty)
                  ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      _dialogPadding.left,
                      18,
                      _dialogPadding.right,
                      _dialogPadding.bottom,
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.borderColor.withValues(
                              alpha: 0.46,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accentGold.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_camera_back_rounded,
                                color: AppColors.accentGold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Nenhuma foto adicionada',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inclua registros visuais da obra quando necessario.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.92,
                                ),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildPrimaryActionButton(
                              icon: const Icon(Icons.add_a_photo_rounded),
                              label: 'Adicionar fotos',
                              onPressed: _pickImages,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth < 360
                              ? 2
                              : constraints.maxWidth < ResponsiveLayout.compact
                              ? 3
                              : 4;

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: _dialogPadding.left,
                          vertical: 10,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount:
                            _existingPhotoUrls.length + _newPhotos.length,
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
                                      : FileImage(File(file.path))
                                          as ImageProvider,
                              onDelete: () => _removeNewPhoto(newIndex),
                              isNetwork: false,
                            );
                          }
                        },
                      );
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accentGold, size: fontSize + 2),
        const SizedBox(width: 12),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
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
    return _buildFieldShell(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization:
            maxLines > 1
                ? TextCapitalization.sentences
                : TextCapitalization.none,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        validator:
            required
                ? (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obrigatório' : null
                : null,
        decoration: granithInputDecoration(
          hint: hint,
          icon: icon,
          accentColor: AppColors.accentGold,
        ),
      ),
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
    return _buildFieldShell(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        menuMaxHeight: 360,
        dropdownColor: AppColors.secondaryDark,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.74),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.accentGold.withValues(alpha: 0.78),
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.surfaceDark.withValues(alpha: 0.50),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.42),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.42),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.accentGold,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDateField({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildFieldShell(
      label: label,
      child: Material(
        color: AppColors.surfaceDark.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.42),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.accentGold.withValues(alpha: 0.78),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile({
    required ImageProvider imageProvider,
    required VoidCallback onDelete,
    required bool isNetwork,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: imageProvider, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.58),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: AppColors.primaryDark.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white, size: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActions() {
    final secondary =
        _currentPage > 0
            ? _buildSecondaryActionButton(
              icon: const Icon(Icons.arrow_back_rounded),
              label: 'Anterior',
              onPressed:
                  () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
            )
            : _buildSecondaryActionButton(
              icon: const Icon(Icons.close_rounded),
              label: 'Cancelar',
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            );

    final primary =
        _currentPage < 2
            ? _buildPrimaryActionButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: 'Próximo',
              onPressed: _goToNextPage,
            )
            : _buildPrimaryActionButton(
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
              label: _isSaving ? 'Salvando...' : 'Finalizar Diário',
            );

    return Container(
      padding: _dialogPadding,
      decoration: BoxDecoration(
        color: AppColors.backgroundMid.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.42)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_isCompactDialog || constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepSummary(),
                const SizedBox(height: 12),
                _fillOnCompact(primary),
                const SizedBox(height: 10),
                _fillOnCompact(secondary),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildStepSummary()),
              const SizedBox(width: 16),
              secondary,
              const SizedBox(width: 10),
              primary,
            ],
          );
        },
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage == 0 && _selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um projeto'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
