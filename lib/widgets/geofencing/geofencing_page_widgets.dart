import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_granith/controllers/geofence_controller.dart';
import 'package:project_granith/models/geofence_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

typedef GeofenceMapBuilder =
    Widget Function(BuildContext context, GeofenceController controller);

class GeofencingPageView extends StatelessWidget {
  final GeofenceController? controller;
  final GeofenceMapBuilder? mapBuilder;

  const GeofencingPageView({super.key, this.controller, this.mapBuilder});

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ChangeNotifierProvider<GeofenceController>.value(
        value: controller!,
        child: _GeofencingContent(mapBuilder: mapBuilder),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => GeofenceController()..init(),
      child: _GeofencingContent(mapBuilder: mapBuilder),
    );
  }
}

class _GeofencingContent extends StatelessWidget {
  final GeofenceMapBuilder? mapBuilder;

  const _GeofencingContent({this.mapBuilder});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);
    final gap = ResponsiveLayout.gap(width);
    final desktop = width >= 1120;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GeofenceHeader(width: width),
              SizedBox(height: gap),
              Expanded(
                child:
                    desktop
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(
                              width: 420,
                              child: _GeofenceSidePanel(expandedList: true),
                            ),
                            SizedBox(width: gap),
                            Expanded(child: _MapPanel(mapBuilder: mapBuilder)),
                          ],
                        )
                        : ListView(
                          children: [
                            const _GeofenceSidePanel(expandedList: false),
                            SizedBox(height: gap),
                            SizedBox(
                              height: width < 520 ? 360 : 460,
                              child: _MapPanel(mapBuilder: mapBuilder),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeofenceHeader extends StatelessWidget {
  final double width;

  const _GeofenceHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    final compact = width < 760;
    final controller = context.watch<GeofenceController>();
    final selected = controller.selectedGeofence;

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
          child: const Icon(Icons.map_rounded, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Geofencing',
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
                'Cercas quadradas por coordenada central',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _HeaderBadge(
          icon: Icons.crop_square_rounded,
          label: '${controller.totalGeofences} cercas',
          color: AppColors.accentGold,
        ),
        _HeaderBadge(
          icon: Icons.check_circle_outline_rounded,
          label: '${controller.activeGeofences} ativas',
          color: Colors.greenAccent,
        ),
        _HeaderBadge(
          icon: Icons.my_location_rounded,
          label: selected?.centerCoordinate ?? 'Sem coordenada mae',
          color: AppColors.accentBlue,
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 12), badges],
      );
    }

    return Row(
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        Flexible(child: badges),
      ],
    );
  }
}

class _GeofenceSidePanel extends StatelessWidget {
  final bool expandedList;

  const _GeofenceSidePanel({required this.expandedList});

  @override
  Widget build(BuildContext context) {
    final list = _GeofenceList(expanded: expandedList);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GeofenceFormPanel(),
        const SizedBox(height: 14),
        const _GeofenceFilters(),
        const SizedBox(height: 14),
        if (expandedList) Expanded(child: list) else list,
      ],
    );
  }
}

class _GeofenceFormPanel extends StatelessWidget {
  const _GeofenceFormPanel();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    return _ToolSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.account_tree_rounded,
            title: 'Cercas das obras',
            trailing: IconButton(
              tooltip: 'Atualizar',
              onPressed: controller.isLoading ? null : controller.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'As cercas sao geradas no cadastro do projeto a partir do endereco da obra, latitude, longitude e lado em metros.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Ativas',
                  value: controller.activeGeofences.toString(),
                  icon: Icons.verified_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Rascunho',
                  value: controller.draftGeofences.toString(),
                  icon: Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeofenceFilters extends StatelessWidget {
  const _GeofenceFilters();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    return _ToolSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Buscar cerca, codigo ou coordenada',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: controller.setSearch,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusFilterChip(label: 'Todos', status: null),
              for (final status in GeofenceStatus.values)
                _StatusFilterChip(label: status.label, status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final GeofenceStatus? status;

  const _StatusFilterChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    final selected = controller.statusFilter == status;
    final color = status?.color ?? AppColors.accentBlue;

    return FilterChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(
        status == null ? Icons.layers_rounded : Icons.circle,
        size: status == null ? 16 : 10,
        color: selected ? color : AppColors.textMuted,
      ),
      onSelected: (_) => controller.setStatusFilter(status),
      selectedColor: color.withValues(alpha: 0.14),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.42)
                : AppColors.borderColor.withValues(alpha: 0.70),
      ),
    );
  }
}

class _GeofenceList extends StatelessWidget {
  final bool expanded;

  const _GeofenceList({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    final items = controller.filteredGeofences;

    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    if (items.isEmpty) {
      return _EmptyGeofenceState(hasFilters: controller.geofences.isNotEmpty);
    }

    if (!expanded) {
      return Column(
        children:
            items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GeofenceCard(geofence: item),
                  ),
                )
                .toList(),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _GeofenceCard(geofence: items[index]),
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final GeofenceArea geofence;

  const _GeofenceCard({required this.geofence});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    final selected = controller.selectedGeofenceId == geofence.id;
    final color = selected ? AppColors.accentGold : geofence.status.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.selectGeofence(geofence.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.crop_square_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      geofence.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusPill(status: geofence.status),
                ],
              ),
              if (geofence.code.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  geofence.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.my_location_rounded,
                label: 'Coordenada mae',
                value: geofence.centerCoordinate,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'Lado',
                      value: geofence.sideLabel,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricBox(
                      label: 'Area',
                      value: _formatArea(geofence.areaSquareMeters),
                      icon: Icons.grid_on_rounded,
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
}

class _MapPanel extends StatelessWidget {
  final GeofenceMapBuilder? mapBuilder;

  const _MapPanel({this.mapBuilder});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GeofenceController>();
    final selected = controller.selectedGeofence;
    final map =
        mapBuilder?.call(context, controller) ??
        _GoogleGeofenceMap(
          geofences: controller.geofences,
          selected: selected,
          onSelect: controller.selectGeofence,
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            left: 14,
            top: 14,
            right: 14,
            child: _MapInfoOverlay(geofence: selected),
          ),
        ],
      ),
    );
  }
}

class _GoogleGeofenceMap extends StatefulWidget {
  final List<GeofenceArea> geofences;
  final GeofenceArea? selected;
  final ValueChanged<String> onSelect;

  const _GoogleGeofenceMap({
    required this.geofences,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_GoogleGeofenceMap> createState() => _GoogleGeofenceMapState();
}

class _GoogleGeofenceMapState extends State<_GoogleGeofenceMap> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant _GoogleGeofenceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected?.id != oldWidget.selected?.id) {
      _focusSelected();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.geofences.isEmpty) {
      return const _MapEmptyState();
    }

    final initial = widget.selected ?? widget.geofences.first;
    final polygons = <Polygon>{};
    final markers = <Marker>{};

    for (final geofence in widget.geofences) {
      final selected = geofence.id == widget.selected?.id;
      final color = selected ? AppColors.accentGold : AppColors.accentBlue;

      polygons.add(
        Polygon(
          polygonId: PolygonId(geofence.id),
          points:
              geofence.squareVertices
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
          strokeColor: color,
          strokeWidth: selected ? 4 : 2,
          fillColor: color.withValues(alpha: selected ? 0.26 : 0.13),
          consumeTapEvents: true,
          onTap: () => widget.onSelect(geofence.id),
        ),
      );

      markers.add(
        Marker(
          markerId: MarkerId('center-${geofence.id}'),
          position: LatLng(geofence.centerLatitude, geofence.centerLongitude),
          infoWindow: InfoWindow(
            title: geofence.name,
            snippet: 'Coordenada mae: ${geofence.centerCoordinate}',
          ),
          onTap: () => widget.onSelect(geofence.id),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(initial.centerLatitude, initial.centerLongitude),
        zoom: _zoomForSide(initial.sideMeters),
      ),
      mapType: MapType.normal,
      polygons: polygons,
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      style: _mapStyle,
      onMapCreated: (controller) {
        _mapController = controller;
        _focusSelected();
      },
    );
  }

  void _focusSelected() {
    final selected = widget.selected;
    final controller = _mapController;
    if (selected == null || controller == null) return;

    unawaited(
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(selected.centerLatitude, selected.centerLongitude),
          _zoomForSide(selected.sideMeters),
        ),
      ),
    );
  }
}

class _MapInfoOverlay extends StatelessWidget {
  final GeofenceArea? geofence;

  const _MapInfoOverlay({required this.geofence});

  @override
  Widget build(BuildContext context) {
    final item = geofence;
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
        child:
            item == null
                ? const Text(
                  'Nenhuma cerca selecionada',
                  style: TextStyle(color: AppColors.textSecondary),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.accentGold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.gps_fixed_rounded,
                      label: 'Coordenada mae',
                      value: item.centerCoordinate,
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.crop_square_rounded,
                      label: 'Quadrado',
                      value: '${item.sideLabel} por lado',
                    ),
                  ],
                ),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: AppColors.textMuted, size: 44),
            SizedBox(height: 10),
            Text(
              'Crie uma cerca para visualizar no mapa',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolSurface extends StatelessWidget {
  final Widget child;

  const _ToolSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _PanelTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final GeofenceStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.30)),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 15),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
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
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGeofenceState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyGeofenceState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return _ToolSurface(
      child: Column(
        children: [
          Icon(
            hasFilters ? Icons.search_off_rounded : Icons.crop_square_rounded,
            color: AppColors.textMuted,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            hasFilters ? 'Nenhuma cerca encontrada' : 'Nenhuma cerca criada',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

double _zoomForSide(double sideMeters) {
  if (sideMeters >= 800) return 14.8;
  if (sideMeters >= 400) return 15.8;
  if (sideMeters >= 180) return 16.7;
  return 17.4;
}

String _formatArea(double squareMeters) {
  if (squareMeters >= 10000) {
    return '${(squareMeters / 10000).toStringAsFixed(2)} ha';
  }
  return '${squareMeters.toStringAsFixed(0)} m2';
}

const _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "all",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1d2c4d"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8ec3b9"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a3646"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#304a7d"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0e1626"}]
  }
]
''';
