import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_granith/Services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../models/project_model.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project;
  final Function(Project) onSave;

  const ProjectFormDialog({super.key, this.project, required this.onSave});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _clientController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _budgetController;
  late TextEditingController _currentCostController;
  late TextEditingController _teamSizeController;

  File? _selectedFile; // Para Mobile
  Uint8List? _selectedImageWeb; // Para Web
  Uint8List? _webImage;

  final ServiceProjetos _service = ServiceProjetos();

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _tags = [];

  // CORREÇÃO 1: Flag para prevenir salvamento duplicado
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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

    if (widget.project != null) {
      _selectedStatus = widget.project!.status;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _tags = List.from(widget.project!.tags);
    }
  }

  @override
  void dispose() {
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

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      child: Container(
        width: isDesktop ? 600 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.project != null ? 'Editar Projeto' : 'Novo Projeto',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do projeto
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nome do Projeto',
                        hint: 'Digite o nome do projeto',
                        required: true,
                      ),

                      const SizedBox(height: 16),
                      // Imagem do projeto
                      _buildImagePicker(),

                      const SizedBox(height: 16),

                      // Cliente
                      _buildTextField(
                        controller: _clientController,
                        label: 'Cliente',
                        hint: 'Nome do cliente',
                        required: true,
                      ),

                      const SizedBox(height: 16),

                      // Descrição
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Descrição',
                        hint: 'Descrição detalhada do projeto',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 16),

                      // Status
                      _buildStatusDropdown(),

                      const SizedBox(height: 16),

                      // Localização
                      _buildTextField(
                        controller: _locationController,
                        label: 'Localização',
                        hint: 'Endereço da obra',
                      ),

                      const SizedBox(height: 16),

                      // Datas
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'Data de Início',
                              _startDate,
                              true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              'Data Prevista',
                              _endDate,
                              false,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Valores financeiros
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _budgetController,
                              label: 'Orçamento (R\$)',
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _currentCostController,
                              label: 'Custo Atual (R\$)',
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tamanho da equipe
                      _buildTextField(
                        controller: _teamSizeController,
                        label: 'Tamanho da Equipe',
                        hint: 'Número de pessoas',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      // Tags
                      _buildTagsSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Ações
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CORREÇÃO 2: Botão de salvar com indicador de loading e prevenção de double-tap
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProject,
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(widget.project != null ? 'Salvar' : 'Criar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageWidget;

    if (kIsWeb && _webImage != null) {
      imageWidget = Image.memory(_webImage!, height: 150, fit: BoxFit.cover);
    } else if (!kIsWeb && _selectedFile != null) {
      imageWidget = Image.file(_selectedFile!, height: 150, fit: BoxFit.cover);
    } else if (widget.project?.imageUrl != null) {
      imageWidget = Image.network(
        widget.project!.imageUrl!,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        height: 150,
        color: AppColors.secondaryDark,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagem do Projeto',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        imageWidget,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.photo),
          label: const Text('Selecionar Imagem'),
          onPressed: _isSaving ? null : _pickImage,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImageWeb = result.files.single.bytes;
          _webImage = result.files.single.bytes; // Corrigir referência
        });
      }
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
              fontWeight: FontWeight.w500,
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
          enabled:
              !_isSaving, // CORREÇÃO: Desabilitar campos durante salvamento
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.secondaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
            contentPadding: const EdgeInsets.all(16),
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
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ProjectStatus>(
          value: _selectedStatus,
          style: const TextStyle(color: AppColors.textPrimary),
          dropdownColor: AppColors.secondaryDark,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.accentGold),
            ),
            contentPadding: const EdgeInsets.all(16),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
          onChanged:
              _isSaving
                  ? null
                  : (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isRequired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : () => _selectDate(isRequired),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color:
                      date != null ? AppColors.accentGold : AppColors.textMuted,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Tags existentes
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: AppColors.accentGold.withOpacity(0.1),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.accentGold,
                    ),
                    onDeleted:
                        _isSaving
                            ? null
                            : () {
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                    side: const BorderSide(color: AppColors.accentGold),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Botão para adicionar tag
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _showAddTagDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Adicionar Tag'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderColor),
          ),
        ),
      ],
    );
  }

  void _selectDate(bool isStartDate) async {
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

    if (date != null) {
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
    String newTag = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Adicionar Tag',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Nome da tag',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.secondaryDark,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => newTag = value,
              onSubmitted: (_) {
                if (newTag.trim().isNotEmpty &&
                    !_tags.contains(newTag.trim())) {
                  setState(() {
                    _tags.add(newTag.trim());
                  });
                }
                Navigator.pop(context);
              },
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
                onPressed: () {
                  if (newTag.trim().isNotEmpty &&
                      !_tags.contains(newTag.trim())) {
                    setState(() {
                      _tags.add(newTag.trim());
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Adicionar'),
              ),
            ],
          ),
    );
  }

  // CORREÇÃO 3: Método _saveProject completamente reescrito com prevenção de duplicação
  Future<void> _saveProject() async {
    // Prevenir múltiplas execuções
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl;
      String projectId = widget.project?.id ?? '';

      // CORREÇÃO 4: Gerar ID único apenas para novos projetos
      if (widget.project == null) {
        // Para novos projetos, usar timestamp + random para garantir unicidade
        final now = DateTime.now();
        projectId = '${now.millisecondsSinceEpoch}_${now.microsecond}';
      }

      // Upload da imagem se houver uma nova selecionada
      if (_selectedFile != null || _selectedImageWeb != null) {
        try {
          print('📤 Iniciando upload de imagem...');
          imageUrl = await _service.uploadProjectImage(
            file: _selectedFile,
            webData: _selectedImageWeb,
            projectId: projectId,
            replaceExisting: true, // Substituir imagem existente
          );
          print('✅ Upload concluído: $imageUrl');
        } catch (e) {
          print('❌ Erro no upload da imagem: $e');
          // Continuar mesmo com erro no upload da imagem
          imageUrl = widget.project?.imageUrl;
        }
      } else {
        // Manter imagem existente se não houver nova imagem
        imageUrl = widget.project?.imageUrl;
      }

      // CORREÇÃO 5: Criar projeto com dados validados
      final project = Project(
        id: projectId,
        name: _nameController.text.trim(),
        client: _clientController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        budget:
            double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0,
        currentCost:
            double.tryParse(_currentCostController.text.replaceAll(',', '.')) ??
            0,
        location: _locationController.text.trim(),
        tags: List.from(_tags), // Criar nova lista para evitar referências
        teamSize: int.tryParse(_teamSizeController.text) ?? 0,
        imageUrl: imageUrl,
      );

      print('💾 Salvando projeto: ${project.name} (ID: ${project.id})');

      // Salvar projeto
      if (widget.project == null) {
        print('➕ Criando novo projeto...');
        await _service.addProject(project);
        print('✅ Projeto criado com sucesso');
      } else {
        print('✏️ Atualizando projeto existente...');
        await _service.updateProject(project);
        print('✅ Projeto atualizado com sucesso');
      }

      // Chamar callback de sucesso
      widget.onSave(project);

      // Fechar dialog apenas se ainda estiver montado
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('💥 Erro ao salvar projeto: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Mostrar erro para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar projeto: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }
}