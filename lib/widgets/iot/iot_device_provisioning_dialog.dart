import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_granith/models/iot_telemetry_models.dart';
import 'package:project_granith/services/iot_device_provisioning_service.dart';
import 'package:project_granith/themes/app_theme.dart';

Future<IoTProvisioningKit?> showIoTDeviceProvisioningDialog(
  BuildContext context,
) {
  return showDialog<IoTProvisioningKit>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _IoTDeviceProvisioningDialog(),
  );
}

class _IoTDeviceProvisioningDialog extends StatefulWidget {
  const _IoTDeviceProvisioningDialog();

  @override
  State<_IoTDeviceProvisioningDialog> createState() =>
      _IoTDeviceProvisioningDialogState();
}

class _IoTDeviceProvisioningDialogState
    extends State<_IoTDeviceProvisioningDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Sensor de obra');
  final _intervalController = TextEditingController(text: '900');
  final _service = IoTDeviceProvisioningService();
  late final Future<List<IoTProjectOption>> _projectsFuture;

  String? _projectId;
  bool _submitting = false;
  String? _error;
  IoTProvisioningKit? _kit;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _service.getAvailableProjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _createKit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final projectId = _projectId;
    if (projectId == null) {
      setState(() => _error = 'Selecione a obra para o sensor.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final kit = await _service.createKit(
        projectId: projectId,
        name: _nameController.text.trim(),
        telemetryIntervalSeconds: int.parse(_intervalController.text.trim()),
      );
      if (!mounted) return;
      setState(() => _kit = kit);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: Container(
          decoration: AppDecorations.dialogSurface(
            glowColor: AppColors.accentBlue,
          ),
          child:
              _kit == null ? _buildForm(wide) : _buildSecretResult(_kit!, wide),
        ),
      ),
    );
  }

  Widget _buildForm(bool wide) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogHeader(
            icon: Icons.add_to_queue_rounded,
            title: 'Cadastrar sensor',
            subtitle: 'Vincule o novo dispositivo à obra.',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<List<IoTProjectOption>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 176,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _projectsLoadFailure();
                }
                final projects = snapshot.data ?? const <IoTProjectOption>[];
                if (projects.isEmpty) {
                  return const _EmptyProjectsNotice();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _projectId,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceElevated,
                      decoration: _inputDecoration(
                        label: 'Obra',
                        icon: Icons.business_rounded,
                      ),
                      hint: const Text('Selecione uma obra'),
                      items: projects
                          .map(
                            (project) => DropdownMenuItem(
                              value: project.id,
                              child: Text(
                                project.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _projectId = value),
                      validator:
                          (value) => value == null ? 'Selecione a obra.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Nome do sensor',
                        icon: Icons.sensors_rounded,
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        if (length < 3 || length > 120) {
                          return 'Informe entre 3 e 120 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: wide ? 260 : double.infinity,
                      child: TextFormField(
                        controller: _intervalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration(
                          label: 'Intervalo em segundos',
                          icon: Icons.timer_outlined,
                        ),
                        validator: (value) {
                          final interval = int.tryParse(value?.trim() ?? '');
                          if (interval == null ||
                              interval < 60 ||
                              interval > 86400) {
                            return 'Use de 60 a 86400 segundos.';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _ErrorMessage(message: _error!),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _createKit,
                          icon:
                              _submitting
                                  ? const SizedBox(
                                    height: 17,
                                    width: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.key_rounded),
                          label: const Text('Gerar segredo'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretResult(IoTProvisioningKit kit, bool wide) {
    final expires = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(kit.expiresAt));
    final date =
        '${kit.expiresAt.day.toString().padLeft(2, '0')}/'
        '${kit.expiresAt.month.toString().padLeft(2, '0')}';
    final setupFile =
        '#pragma once\n\n'
        '#define GRANITH_IOT_PROVISIONING_SECRET "${kit.secret}"';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dialogHeader(
          icon: Icons.verified_user_rounded,
          title: 'Segredo gerado',
          subtitle: '${kit.deviceName} | expira em $date às $expires',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardInnerSurface(
                  accent: AppColors.accentGold,
                  radius: 12,
                ),
                child: SelectableText(
                  kit.secret,
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppDecorations.cardInnerSurface(
                  accent: AppColors.accentBlue,
                  radius: 12,
                ),
                child: SelectableText(
                  setupFile,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: wide ? WrapAlignment.end : WrapAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: kit.secret));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Segredo copiado.')),
                      );
                    },
                    icon: const Icon(Icons.key_rounded),
                    label: const Text('Copiar segredo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: setupFile));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bloco de configuração copiado.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_rounded),
                    label: const Text('Copiar arquivo'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(kit),
                    child: const Text('Concluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dialogHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.dialogHeader(accent: AppColors.accentBlue),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecorations.iconTile(AppColors.accentBlue),
            child: Icon(icon, color: AppColors.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectsLoadFailure() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: _ErrorMessage(message: 'Não foi possível carregar as obras.'),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.accentBlue),
      filled: true,
      fillColor: AppColors.surfaceDark.withValues(alpha: 0.82),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentRed,
        radius: 12,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.accentRed),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
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

class _EmptyProjectsNotice extends StatelessWidget {
  const _EmptyProjectsNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Cadastre uma obra antes de provisionar sensores.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
