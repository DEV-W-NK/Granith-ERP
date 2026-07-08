import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/vehicle_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/team_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';

class VehiclesPageView extends StatelessWidget {
  final VehicleController? controller;

  const VehiclesPageView({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ChangeNotifierProvider<VehicleController>.value(
        value: controller!,
        child: const _VehiclesContent(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => VehicleController()..init(),
      child: const _VehiclesContent(),
    );
  }
}

class _VehiclesContent extends StatelessWidget {
  const _VehiclesContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VehicleController>();
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);
    final vehicles = controller.filteredVehicles;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FleetHeader(width: width),
              const SizedBox(height: 14),
              _FleetStats(width: width),
              const SizedBox(height: 14),
              _FleetFilters(width: width),
              const SizedBox(height: 14),
              Expanded(
                child:
                    controller.isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                          ),
                        )
                        : vehicles.isEmpty
                        ? _EmptyFleetState(
                          hasFilters: controller.vehicles.isNotEmpty,
                        )
                        : _VehicleGrid(vehicles: vehicles),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetHeader extends StatelessWidget {
  final double width;

  const _FleetHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    final compact = width < 900;
    final controller = context.watch<VehicleController>();
    final titleBlock = Row(
      children: [
        Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.30),
            ),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frota e Veiculos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cadastro, consumo esperado e base para notas de combustivel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

    final addButton = FilledButton.icon(
      onPressed: () => _VehicleFormDialog.show(context),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Novo veiculo'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniFleetBadge(
                icon: Icons.car_rental_rounded,
                label: '${controller.totalVehicles} cadastrados',
              ),
              SizedBox(width: double.infinity, child: addButton),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        _MiniFleetBadge(
          icon: Icons.car_rental_rounded,
          label: '${controller.totalVehicles} cadastrados',
        ),
        const SizedBox(width: 10),
        addButton,
      ],
    );
  }
}

class _FleetStats extends StatelessWidget {
  final double width;

  const _FleetStats({required this.width});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VehicleController>();
    final columns = width < 760 ? 2 : 4;
    final gap = ResponsiveLayout.gap(width);
    final stats = [
      _FleetStatData(
        title: 'Ativos',
        value: controller.activeVehicles.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.greenAccent,
      ),
      _FleetStatData(
        title: 'Manutencao',
        value: controller.maintenanceVehicles.toString(),
        icon: Icons.build_circle_outlined,
        color: Colors.orangeAccent,
      ),
      _FleetStatData(
        title: 'Idade media',
        value: '${controller.averageFleetAge.toStringAsFixed(1)} anos',
        icon: Icons.history_rounded,
        color: AppColors.accentBlue,
      ),
      _FleetStatData(
        title: 'Abaixo do esperado',
        value: controller.vehiclesUnderExpected.toString(),
        icon: Icons.local_gas_station_outlined,
        color: AppColors.accentRed,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              stats
                  .map((stat) => _FleetStatCard(data: stat, width: cardWidth))
                  .toList(),
        );
      },
    );
  }
}

class _FleetFilters extends StatelessWidget {
  final double width;

  const _FleetFilters({required this.width});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VehicleController>();
    final compact = width < ResponsiveLayout.compact;
    final search = TextField(
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        hintText: 'Buscar por placa, modelo ou responsavel',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
      ),
      onChanged: controller.setSearch,
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusFilterChip(label: 'Todos', status: null),
        for (final status in VehicleStatus.values)
          _StatusFilterChip(label: status.label, status: status),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [search, const SizedBox(height: 10), chips],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 14),
        Expanded(flex: 4, child: chips),
      ],
    );
  }
}

class _VehicleGrid extends StatelessWidget {
  final List<Vehicle> vehicles;

  const _VehicleGrid({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth = constraints.maxWidth;
        final columns = ResponsiveLayout.columnsFor(
          actualWidth,
          mediumColumns: 2,
          expandedColumns: 3,
        );
        final gap = ResponsiveLayout.gap(actualWidth);

        if (columns == 1) {
          return ListView.separated(
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => SizedBox(height: gap),
            itemBuilder: (_, index) => _VehicleCard(vehicle: vehicles[index]),
          );
        }

        return GridView.builder(
          itemCount: vehicles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: 320,
          ),
          itemBuilder: (_, index) => _VehicleCard(vehicle: vehicles[index]),
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final expected = vehicle.expectedAverageKmPerLiter;
    final measured = vehicle.lastMeasuredKmPerLiter;
    final delta = vehicle.consumptionDeltaPercent;
    final accent =
        vehicle.isUnderExpectedConsumption
            ? AppColors.accentRed
            : vehicle.status.color;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _VehicleFormDialog.show(context, vehicle: vehicle),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardSurface(accent: accent, radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vehicle.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(status: vehicle.status),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                _InfoPill(icon: Icons.tag_rounded, label: vehicle.plate),
                _InfoPill(
                  icon: Icons.calendar_month_rounded,
                  label: vehicle.yearLabel,
                ),
                _InfoPill(
                  icon: Icons.local_gas_station_rounded,
                  label: vehicle.fuelType.label,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MetricRow(
              label: 'Hodometro',
              value: '${vehicle.odometerKm.toStringAsFixed(0)} km',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Consumo esperado',
              value: expected > 0 ? '${expected.toStringAsFixed(1)} km/l' : '-',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Consumo real',
              value:
                  measured != null
                      ? '${measured.toStringAsFixed(1)} km/l'
                      : 'Sem abastecimentos',
              valueColor:
                  vehicle.isUnderExpectedConsumption
                      ? AppColors.accentRed
                      : AppColors.textPrimary,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    vehicle.assignedEmployeeName.isEmpty
                        ? 'Sem responsavel fixo'
                        : vehicle.assignedEmployeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (delta != null)
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color:
                          delta < -12
                              ? AppColors.accentRed
                              : Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else if (vehicle.fipeValue != null)
                  Text(
                    currency.format(vehicle.fipeValue),
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const _VehicleFormDialog({this.vehicle});

  static Future<void> show(BuildContext context, {Vehicle? vehicle}) {
    final controller = context.read<VehicleController>();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => ChangeNotifierProvider<VehicleController>.value(
            value: controller,
            child: _VehicleFormDialog(vehicle: vehicle),
          ),
    );
  }

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _manufactureYearCtrl = TextEditingController();
  final _modelYearCtrl = TextEditingController();
  final _odometerCtrl = TextEditingController();
  final _cityConsumptionCtrl = TextEditingController();
  final _highwayConsumptionCtrl = TextEditingController();
  final _tankCtrl = TextEditingController();
  final _employeeCtrl = TextEditingController();
  final _employeeFocus = FocusNode();
  final _acquisitionValueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _teamService = TeamService();
  StreamSubscription<List<EmployeeModel>>? _employeesSubscription;
  List<EmployeeModel> _employees = [];
  EmployeeModel? _selectedEmployee;
  bool _isLoadingEmployees = true;
  String? _employeesError;
  VehicleFuelType _fuelType = VehicleFuelType.flex;
  VehicleStatus _status = VehicleStatus.active;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    final currentYear = DateTime.now().year;

    _plateCtrl.text = vehicle?.plate ?? '';
    _brandCtrl.text = vehicle?.brand ?? '';
    _modelCtrl.text = vehicle?.model ?? '';
    _versionCtrl.text = vehicle?.version ?? '';
    _manufactureYearCtrl.text =
        (vehicle?.manufactureYear ?? currentYear).toString();
    _modelYearCtrl.text = (vehicle?.modelYear ?? currentYear).toString();
    _odometerCtrl.text =
        vehicle == null ? '' : vehicle.odometerKm.toStringAsFixed(0);
    _cityConsumptionCtrl.text =
        vehicle == null || vehicle.expectedCityKmPerLiter == 0
            ? ''
            : vehicle.expectedCityKmPerLiter.toStringAsFixed(1);
    _highwayConsumptionCtrl.text =
        vehicle == null || vehicle.expectedHighwayKmPerLiter == 0
            ? ''
            : vehicle.expectedHighwayKmPerLiter.toStringAsFixed(1);
    _tankCtrl.text =
        vehicle == null || vehicle.tankCapacityLiters == 0
            ? ''
            : vehicle.tankCapacityLiters.toStringAsFixed(1);
    _employeeCtrl.text = vehicle?.assignedEmployeeName ?? '';
    _acquisitionValueCtrl.text =
        vehicle == null || vehicle.acquisitionValue == 0
            ? ''
            : vehicle.acquisitionValue.toStringAsFixed(2);
    _notesCtrl.text = vehicle?.notes ?? '';
    _fuelType = vehicle?.fuelType ?? VehicleFuelType.flex;
    _status = vehicle?.status ?? VehicleStatus.active;
    _employeeCtrl.addListener(_handleEmployeeTextChanged);
    _listenEmployees();
  }

  @override
  void dispose() {
    _employeesSubscription?.cancel();
    _employeeCtrl.removeListener(_handleEmployeeTextChanged);
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _versionCtrl.dispose();
    _manufactureYearCtrl.dispose();
    _modelYearCtrl.dispose();
    _odometerCtrl.dispose();
    _cityConsumptionCtrl.dispose();
    _highwayConsumptionCtrl.dispose();
    _tankCtrl.dispose();
    _employeeCtrl.dispose();
    _employeeFocus.dispose();
    _acquisitionValueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _listenEmployees() {
    try {
      _employeesSubscription = _teamService.getEmployees().listen((employees) {
        final activeEmployees =
            employees.where((employee) => employee.isActive).toList()..sort(
              (left, right) =>
                  left.name.toLowerCase().compareTo(right.name.toLowerCase()),
            );

        final currentEmployeeId = widget.vehicle?.assignedEmployeeId?.trim();
        EmployeeModel? selected = _selectedEmployee;
        if (selected == null &&
            currentEmployeeId != null &&
            currentEmployeeId.isNotEmpty) {
          selected = _employeeById(activeEmployees, currentEmployeeId);
        }

        if (!mounted) return;
        setState(() {
          _employees = activeEmployees;
          _selectedEmployee = selected;
          _isLoadingEmployees = false;
          _employeesError = null;
          if (selected != null &&
              _employeeCtrl.text.trim() != selected.name.trim()) {
            _employeeCtrl.text = selected.name;
          }
        });
      }, onError: _handleEmployeesError);
    } catch (error) {
      _handleEmployeesError(error);
    }
  }

  void _handleEmployeesError(Object error) {
    if (!mounted) return;
    setState(() {
      _isLoadingEmployees = false;
      _employeesError = error.toString();
    });
  }

  void _handleEmployeeTextChanged() {
    final selected = _selectedEmployee;
    if (selected == null) return;
    if (_employeeCtrl.text.trim() == selected.name.trim()) return;
    setState(() => _selectedEmployee = null);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 640;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(size.width < 420 ? 10 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.92,
        ),
        child: Container(
          decoration: AppDecorations.dialogSurface(
            glowColor: AppColors.accentBlue,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildDialogHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _formSectionTitle('Identificacao'),
                        _responsiveFields(compact, [
                          _textField(
                            controller: _plateCtrl,
                            label: 'Placa',
                            icon: Icons.tag_rounded,
                            validator: _required,
                          ),
                          _statusDropdown(),
                        ]),
                        const SizedBox(height: 12),
                        _responsiveFields(compact, [
                          _textField(
                            controller: _brandCtrl,
                            label: 'Marca',
                            icon: Icons.factory_rounded,
                            validator: _required,
                          ),
                          _textField(
                            controller: _modelCtrl,
                            label: 'Modelo',
                            icon: Icons.directions_car_rounded,
                            validator: _required,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _responsiveFields(compact, [
                          _textField(
                            controller: _versionCtrl,
                            label: 'Versao',
                            icon: Icons.tune_rounded,
                          ),
                          _numberField(
                            controller: _manufactureYearCtrl,
                            label: 'Ano fabricacao',
                            icon: Icons.calendar_today_rounded,
                            validator: _yearValidator,
                          ),
                          _numberField(
                            controller: _modelYearCtrl,
                            label: 'Ano modelo',
                            icon: Icons.event_available_rounded,
                            validator: _yearValidator,
                          ),
                        ]),
                        const SizedBox(height: 18),
                        _formSectionTitle('Dados atuais'),
                        _responsiveFields(compact, [
                          _fuelDropdown(),
                          _numberField(
                            controller: _odometerCtrl,
                            label: 'Hodometro atual',
                            icon: Icons.speed_rounded,
                          ),
                          _numberField(
                            controller: _tankCtrl,
                            label: 'Tanque (litros)',
                            icon: Icons.local_gas_station_rounded,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _responsiveFields(compact, [
                          _numberField(
                            controller: _cityConsumptionCtrl,
                            label: 'Consumo cidade (km/l)',
                            icon: Icons.location_city_rounded,
                          ),
                          _numberField(
                            controller: _highwayConsumptionCtrl,
                            label: 'Consumo estrada (km/l)',
                            icon: Icons.alt_route_rounded,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _responsiveFields(compact, [
                          _employeeSearchField(),
                          _numberField(
                            controller: _acquisitionValueCtrl,
                            label: 'Valor de aquisicao',
                            icon: Icons.payments_outlined,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _notesCtrl,
                          label: 'Observacoes',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        _dialogActions(compact),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return GranithDialogHeader(
      icon: Icons.directions_car_filled_rounded,
      title: _isEditing ? 'Editar veiculo' : 'Novo veiculo',
      subtitle: 'Identificacao, consumo, responsavel e status da frota',
      accentColor: AppColors.accentBlue,
      onClose: () => Navigator.of(context).pop(),
    );
  }

  Widget _formSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsiveFields(bool compact, List<Widget> fields) {
    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            fields[i],
            if (i < fields.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          Expanded(child: fields[i]),
          if (i < fields.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _dialogActions(bool compact) {
    final isSaving = context.watch<VehicleController>().isSaving;
    final saveLabel = _isEditing ? 'Salvar veiculo' : 'Cadastrar veiculo';
    final cancelButton = OutlinedButton.icon(
      onPressed: isSaving ? null : () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded, size: 18),
      label: const Text('Cancelar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
    );
    final saveButton = FilledButton.icon(
      onPressed: isSaving ? null : _save,
      icon:
          isSaving
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.save_rounded, size: 18),
      label: Text(saveLabel),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [saveButton, const SizedBox(height: 10), cancelButton],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 10,
      children: [cancelButton, saveButton],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(label, icon),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(label, icon),
    );
  }

  Widget _fuelDropdown() {
    return DropdownButtonFormField<VehicleFuelType>(
      initialValue: _fuelType,
      isExpanded: true,
      dropdownColor: AppColors.surfaceElevated,
      decoration: _fieldDecoration(
        'Combustivel',
        Icons.local_gas_station_rounded,
      ),
      items:
          VehicleFuelType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
      onChanged: (value) => setState(() => _fuelType = value ?? _fuelType),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<VehicleStatus>(
      initialValue: _status,
      isExpanded: true,
      dropdownColor: AppColors.surfaceElevated,
      decoration: _fieldDecoration('Status', Icons.flag_rounded),
      items:
          VehicleStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
      onChanged: (value) => setState(() => _status = value ?? _status),
    );
  }

  Widget _employeeSearchField() {
    final suffixIcon =
        _employeeCtrl.text.trim().isEmpty
            ? _isLoadingEmployees
                ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : null
            : IconButton(
              tooltip: 'Limpar responsavel',
              onPressed: () {
                setState(() {
                  _selectedEmployee = null;
                  _employeeCtrl.clear();
                });
              },
              icon: const Icon(Icons.close_rounded),
            );

    return RawAutocomplete<EmployeeModel>(
      textEditingController: _employeeCtrl,
      focusNode: _employeeFocus,
      displayStringForOption: (employee) => employee.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (_employees.isEmpty) return const Iterable<EmployeeModel>.empty();

        final options =
            query.isEmpty
                ? _employees
                : _employees.where(
                  (employee) => _matchesEmployeeSearch(employee, query),
                );

        return options.take(8);
      },
      onSelected: (employee) {
        setState(() {
          _selectedEmployee = employee;
          _employeeCtrl.text = employee.name;
        });
      },
      fieldViewBuilder: (
        context,
        textEditingController,
        focusNode,
        onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          validator: _employeeValidator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _fieldDecoration(
            'Responsavel / motorista',
            Icons.person_search_rounded,
          ).copyWith(
            hintText: 'Busque um funcionario ativo',
            suffixIcon: suffixIcon,
            helperText:
                _employeesError == null
                    ? 'Selecione na lista para vincular ao cadastro do funcionario.'
                    : 'Nao foi possivel carregar funcionarios.',
            helperStyle: TextStyle(
              color:
                  _employeesError == null
                      ? AppColors.textMuted
                      : AppColors.accentRed,
              fontSize: 11,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final items = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 280),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder:
                    (_, __) => Divider(
                      height: 1,
                      color: AppColors.borderColor.withValues(alpha: 0.36),
                    ),
                itemBuilder: (context, index) {
                  final employee = items[index];
                  return InkWell(
                    onTap: () => onSelected(employee),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.accentBlue.withValues(
                              alpha: 0.14,
                            ),
                            child: Text(
                              employee.initials,
                              style: const TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _employeeDetails(employee),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return granithInputDecoration(
      label: label,
      hint: '',
      icon: icon,
      accentColor: AppColors.accentBlue,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatorio';
    return null;
  }

  String? _yearValidator(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    final year = int.tryParse(value!.trim());
    final maxYear = DateTime.now().year + 1;
    if (year == null || year < 1970 || year > maxYear) {
      return 'Ano invalido';
    }
    return null;
  }

  String? _employeeValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    if (_isLoadingEmployees) return 'Aguarde os funcionarios carregarem';
    if (_employeesError != null) {
      return 'Nao foi possivel carregar funcionarios';
    }
    if (_selectedEmployee != null &&
        _selectedEmployee!.name.trim().toLowerCase() == input.toLowerCase()) {
      return null;
    }

    final exactMatch = _employeeByTypedName(input);
    if (exactMatch != null) return null;

    return 'Selecione um funcionario ativo da lista';
  }

  Future<void> _save() async {
    _syncSelectedEmployeeFromText();
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final initial = widget.vehicle;
    final selectedEmployee = _selectedEmployee;
    final vehicle = Vehicle(
      id: initial?.id ?? '',
      plate: _plateCtrl.text,
      brand: _brandCtrl.text,
      model: _modelCtrl.text,
      version: _versionCtrl.text,
      manufactureYear: int.parse(_manufactureYearCtrl.text.trim()),
      modelYear: int.parse(_modelYearCtrl.text.trim()),
      fuelType: _fuelType,
      status: _status,
      odometerKm: _parseDouble(_odometerCtrl.text),
      expectedCityKmPerLiter: _parseDouble(_cityConsumptionCtrl.text),
      expectedHighwayKmPerLiter: _parseDouble(_highwayConsumptionCtrl.text),
      tankCapacityLiters: _parseDouble(_tankCtrl.text),
      assignedEmployeeId: selectedEmployee?.id,
      assignedEmployeeName: selectedEmployee?.name ?? '',
      acquisitionDate: initial?.acquisitionDate,
      acquisitionValue: _parseDouble(_acquisitionValueCtrl.text),
      fipeCode: initial?.fipeCode,
      fipeValue: initial?.fipeValue,
      fipeReferenceMonth: initial?.fipeReferenceMonth,
      lastMeasuredKmPerLiter: initial?.lastMeasuredKmPerLiter,
      lastFuelLogAt: initial?.lastFuelLogAt,
      notes: _notesCtrl.text,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final controller = context.read<VehicleController>();
      if (_isEditing) {
        await controller.updateVehicle(vehicle);
      } else {
        await controller.createVehicle(vehicle);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Veiculo atualizado' : 'Veiculo cadastrado',
            ),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  void _syncSelectedEmployeeFromText() {
    final input = _employeeCtrl.text.trim();
    if (input.isEmpty) {
      _selectedEmployee = null;
      return;
    }

    final selected = _selectedEmployee;
    if (selected != null &&
        selected.name.trim().toLowerCase() == input.toLowerCase()) {
      return;
    }

    _selectedEmployee = _employeeByTypedName(input);
  }

  EmployeeModel? _employeeByTypedName(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final employee in _employees) {
      if (employee.name.trim().toLowerCase() == normalized) {
        return employee;
      }
    }
    return null;
  }
}

class _FleetStatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FleetStatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _FleetStatCard extends StatelessWidget {
  final _FleetStatData data;
  final double width;

  const _FleetStatCard({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(150, 280),
      height: 82,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.statCardSurface(data.color, radius: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: AppDecorations.iconTile(data.color),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final VehicleStatus? status;

  const _StatusFilterChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VehicleController>();
    final selected = controller.statusFilter == status;
    final color = status?.color ?? AppColors.accentGold;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setStatusFilter(status),
      selectedColor: color.withValues(alpha: 0.16),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.40),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.50)
                : AppColors.borderColor.withValues(alpha: 0.52),
      ),
      labelStyle: TextStyle(
        color: selected ? color : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }
}

class _MiniFleetBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniFleetBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accentGold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.28)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFleetState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyFleetState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off_rounded
                : Icons.directions_car_outlined,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.32),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'Nenhum veiculo encontrado'
                : 'Nenhum veiculo cadastrado',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre a frota para acompanhar consumo, custo e uso por colaborador.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

double _parseDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}

EmployeeModel? _employeeById(List<EmployeeModel> employees, String id) {
  for (final employee in employees) {
    if (employee.id == id) return employee;
  }
  return null;
}

String _employeeDetails(EmployeeModel employee) {
  final details = [
    if (employee.jobTitle.trim().isNotEmpty) employee.jobTitle.trim(),
    if (employee.sector.trim().isNotEmpty) employee.sector.trim(),
    if (employee.email.trim().isNotEmpty) employee.email.trim(),
  ];
  return details.isEmpty ? 'Funcionario ativo' : details.join(' - ');
}

bool _matchesEmployeeSearch(EmployeeModel employee, String query) {
  final searchable =
      [
        employee.name,
        employee.jobTitle,
        employee.sector,
        employee.email,
        employee.phone,
      ].join(' ').toLowerCase();
  return searchable.contains(query);
}
