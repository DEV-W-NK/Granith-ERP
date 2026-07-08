import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project_granith/models/purchase_delivery_route_model.dart';
import 'package:project_granith/services/purchase_delivery_route_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

enum _RouteStatusFilter {
  active,
  planned,
  inProgress,
  completed,
  cancelled,
  all,
}

enum _RouteSortOption { scheduledDesc, activeFirst, driver, distanceDesc }

class PurchaseLogisticsPageView extends StatefulWidget {
  final PurchaseDeliveryRouteService? service;
  final Stream<List<PurchaseDeliveryRoute>>? routesStream;

  const PurchaseLogisticsPageView({super.key, this.service, this.routesStream});

  @override
  State<PurchaseLogisticsPageView> createState() =>
      _PurchaseLogisticsPageViewState();
}

class _PurchaseLogisticsPageViewState extends State<PurchaseLogisticsPageView> {
  static const int _initialVisibleRoutes = 12;
  static const int _visibleRoutesStep = 12;

  late final PurchaseDeliveryRouteService _service;
  late final Stream<List<PurchaseDeliveryRoute>> _routesStream;

  final _routeSearchCtrl = TextEditingController();

  String _routeQuery = '';
  _RouteStatusFilter _routeStatusFilter = _RouteStatusFilter.all;
  _RouteSortOption _routeSort = _RouteSortOption.activeFirst;
  int _visibleRouteCount = _initialVisibleRoutes;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PurchaseDeliveryRouteService();
    _routesStream = widget.routesStream ?? _service.watchRoutes();
  }

  @override
  void dispose() {
    _routeSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: StreamBuilder<List<PurchaseDeliveryRoute>>(
            stream: _routesStream,
            builder: (context, routeSnapshot) {
              final routes =
                  routeSnapshot.data ?? const <PurchaseDeliveryRoute>[];

              return _buildContent(
                routes: routes,
                routesLoading: !routeSnapshot.hasData,
                routesError: routeSnapshot.error,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<PurchaseDeliveryRoute> routes,
    required bool routesLoading,
    required Object? routesError,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = ResponsiveLayout.gap(width);
    final filteredRoutes = _filteredRoutes(routes);
    final visibleRoutes = filteredRoutes.take(_visibleRouteCount).toList();
    final hasMoreRoutes = visibleRoutes.length < filteredRoutes.length;

    final routesPanel = _RoutesPanel(
      searchController: _routeSearchCtrl,
      query: _routeQuery,
      statusFilter: _routeStatusFilter,
      sortOption: _routeSort,
      routes: visibleRoutes,
      totalFilteredCount: filteredRoutes.length,
      totalRouteCount: routes.length,
      hasMore: hasMoreRoutes,
      isLoading: routesLoading,
      error: routesError,
      service: _service,
      onSearchChanged: (value) {
        setState(() {
          _routeQuery = value;
          _visibleRouteCount = _initialVisibleRoutes;
        });
      },
      onClearSearch: () {
        setState(() {
          _routeSearchCtrl.clear();
          _routeQuery = '';
          _visibleRouteCount = _initialVisibleRoutes;
        });
      },
      onStatusChanged: (filter) {
        setState(() {
          _routeStatusFilter = filter;
          _visibleRouteCount = _initialVisibleRoutes;
        });
      },
      onSortChanged: (option) {
        setState(() {
          _routeSort = option;
          _visibleRouteCount = _initialVisibleRoutes;
        });
      },
      onClearFilters: () {
        setState(() {
          _routeSearchCtrl.clear();
          _routeQuery = '';
          _routeStatusFilter = _RouteStatusFilter.all;
          _visibleRouteCount = _initialVisibleRoutes;
        });
      },
      onLoadMore: () {
        setState(() => _visibleRouteCount += _visibleRoutesStep);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LogisticsHeader(routes: routes),
        SizedBox(height: gap),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 12),
            children: [routesPanel],
          ),
        ),
      ],
    );
  }

  List<PurchaseDeliveryRoute> _filteredRoutes(
    List<PurchaseDeliveryRoute> routes,
  ) {
    final query = _routeQuery.trim().toLowerCase();
    final filtered =
        routes.where((route) {
          if (!_matchesRouteStatus(route)) return false;
          if (query.isEmpty) return true;

          final searchable =
              [
                route.name,
                route.driverName,
                route.status.label,
                route.notes,
              ].join(' ').toLowerCase();
          return searchable.contains(query);
        }).toList();

    filtered.sort(_compareRoutes);
    return filtered;
  }

  bool _matchesRouteStatus(PurchaseDeliveryRoute route) {
    switch (_routeStatusFilter) {
      case _RouteStatusFilter.active:
        return route.status == PurchaseRouteStatus.planned ||
            route.status == PurchaseRouteStatus.inProgress;
      case _RouteStatusFilter.planned:
        return route.status == PurchaseRouteStatus.planned;
      case _RouteStatusFilter.inProgress:
        return route.status == PurchaseRouteStatus.inProgress;
      case _RouteStatusFilter.completed:
        return route.status == PurchaseRouteStatus.completed;
      case _RouteStatusFilter.cancelled:
        return route.status == PurchaseRouteStatus.cancelled;
      case _RouteStatusFilter.all:
        return true;
    }
  }

  int _compareRoutes(PurchaseDeliveryRoute left, PurchaseDeliveryRoute right) {
    switch (_routeSort) {
      case _RouteSortOption.scheduledDesc:
        return _compareNullableDateDesc(
          left.scheduledDate,
          right.scheduledDate,
        );
      case _RouteSortOption.activeFirst:
        final statusCompare = _routeStatusRank(
          left.status,
        ).compareTo(_routeStatusRank(right.status));
        if (statusCompare != 0) return statusCompare;
        return _compareNullableDateDesc(
          left.scheduledDate,
          right.scheduledDate,
        );
      case _RouteSortOption.driver:
        return left.driverName.toLowerCase().compareTo(
          right.driverName.toLowerCase(),
        );
      case _RouteSortOption.distanceDesc:
        return right.actualDistanceKm.compareTo(left.actualDistanceKm);
    }
  }
}

class _LogisticsHeader extends StatelessWidget {
  final List<PurchaseDeliveryRoute> routes;

  const _LogisticsHeader({required this.routes});

  @override
  Widget build(BuildContext context) {
    final planned = _countRouteStatus(routes, PurchaseRouteStatus.planned);
    final inProgress = _countRouteStatus(
      routes,
      PurchaseRouteStatus.inProgress,
    );
    final completed = _countRouteStatus(routes, PurchaseRouteStatus.completed);
    final totalActualKm = routes.fold<double>(
      0,
      (total, route) => total + route.actualDistanceKm,
    );
    final totalEstimatedKm = routes.fold<double>(
      0,
      (total, route) => total + route.estimatedDistanceKm,
    );
    final scheduledToday =
        routes.where((route) {
          final date = route.scheduledDate;
          if (date == null) return false;
          return _sameDay(date, DateTime.now());
        }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        elevated: false,
        radius: 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < ResponsiveLayout.compact;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Container(
                  width: 46,
                  height: 46,
                  decoration: AppDecorations.iconTile(AppColors.accentGold),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coletas e Entregas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routes.isEmpty
                          ? 'Acompanhe aqui as rotas executadas no app do motorista'
                          : '${_plural(routes.length, 'rota monitorada', 'rotas monitoradas')} com KM sincronizado do mobile',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _HeaderMetric(
                icon: Icons.alt_route_rounded,
                label: _plural(routes.length, 'rota', 'rotas'),
                color: AppColors.accentBlue,
              ),
              _HeaderMetric(
                icon: Icons.speed_outlined,
                label: '${totalActualKm.toStringAsFixed(1)} km feitos',
                color:
                    totalActualKm > 0
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
              ),
              _HeaderMetric(
                icon: Icons.event_available_outlined,
                label: '$scheduledToday hoje',
                color: AppColors.textSecondary,
              ),
              _HeaderMetric(
                icon: Icons.route_outlined,
                label: '$planned planejadas',
                color: AppColors.accentGold,
              ),
              _HeaderMetric(
                icon: Icons.play_arrow_rounded,
                label: '$inProgress em rota',
                color: AppColors.accentBlue,
              ),
              _HeaderMetric(
                icon: Icons.flag_outlined,
                label: '$completed concluidas',
                color: AppColors.accentGreen,
              ),
              _HeaderMetric(
                icon: Icons.straighten_outlined,
                label: '${totalEstimatedKm.toStringAsFixed(1)} km previstos',
                color:
                    totalEstimatedKm > 0
                        ? AppColors.accentGold
                        : AppColors.textSecondary,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), metrics],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              Flexible(child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _RoutesPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final _RouteStatusFilter statusFilter;
  final _RouteSortOption sortOption;
  final List<PurchaseDeliveryRoute> routes;
  final int totalFilteredCount;
  final int totalRouteCount;
  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final PurchaseDeliveryRouteService service;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_RouteStatusFilter> onStatusChanged;
  final ValueChanged<_RouteSortOption> onSortChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onLoadMore;

  const _RoutesPanel({
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.sortOption,
    required this.routes,
    required this.totalFilteredCount,
    required this.totalRouteCount,
    required this.hasMore,
    required this.isLoading,
    required this.error,
    required this.service,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.alt_route_rounded,
            title: 'Rotas e KM dos motoristas',
            subtitle:
                'Execucao no app mobile; ERP apenas acompanha status e KM',
          ),
          const SizedBox(height: 14),
          _RouteToolbar(
            searchController: searchController,
            query: query,
            statusFilter: statusFilter,
            sortOption: sortOption,
            resultCount: totalFilteredCount,
            totalCount: totalRouteCount,
            onSearchChanged: onSearchChanged,
            onClearSearch: onClearSearch,
            onStatusChanged: onStatusChanged,
            onSortChanged: onSortChanged,
            onClearFilters: onClearFilters,
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const _InlineLoading(message: 'Carregando rotas...')
          else if (error != null)
            _EmptyState(
              icon: Icons.error_outline,
              title: 'Nao foi possivel carregar rotas',
              subtitle: error.toString(),
            )
          else if (routes.isEmpty)
            const _EmptyState(
              icon: Icons.route_outlined,
              title: 'Nenhuma rota encontrada',
              subtitle:
                  'Ajuste busca/status ou aguarde as rotas sincronizadas pelo mobile.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 720),
              child: Scrollbar(
                child: ListView.builder(
                  primary: false,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: routes.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= routes.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: onLoadMore,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(
                              'Mostrar mais (${routes.length} de $totalFilteredCount)',
                            ),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RouteCard(route: routes[index], service: service),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final _RouteStatusFilter statusFilter;
  final _RouteSortOption sortOption;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_RouteStatusFilter> onStatusChanged;
  final ValueChanged<_RouteSortOption> onSortChanged;
  final VoidCallback onClearFilters;

  const _RouteToolbar({
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.sortOption,
    required this.resultCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        query.trim().isNotEmpty || statusFilter != _RouteStatusFilter.active;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentBlue),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final search = TextField(
            controller: searchController,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Buscar rota',
              hintText: 'Nome, motorista ou observacao',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  query.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
            onChanged: onSearchChanged,
          );
          final sort = DropdownButtonFormField<_RouteSortOption>(
            initialValue: sortOption,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Ordenar'),
            items:
                _RouteSortOption.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_routeSortLabel(option)),
                      ),
                    )
                    .toList(),
            onChanged: (option) {
              if (option != null) onSortChanged(option);
            },
          );
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Ativas',
                selected: statusFilter == _RouteStatusFilter.active,
                icon: Icons.bolt_outlined,
                color: AppColors.accentBlue,
                onTap: () => onStatusChanged(_RouteStatusFilter.active),
              ),
              _FilterChip(
                label: 'Planejadas',
                selected: statusFilter == _RouteStatusFilter.planned,
                icon: Icons.route_outlined,
                color: AppColors.accentGold,
                onTap: () => onStatusChanged(_RouteStatusFilter.planned),
              ),
              _FilterChip(
                label: 'Em rota',
                selected: statusFilter == _RouteStatusFilter.inProgress,
                icon: Icons.play_arrow_rounded,
                color: AppColors.accentBlue,
                onTap: () => onStatusChanged(_RouteStatusFilter.inProgress),
              ),
              _FilterChip(
                label: 'Concluidas',
                selected: statusFilter == _RouteStatusFilter.completed,
                icon: Icons.flag_outlined,
                color: AppColors.accentGreen,
                onTap: () => onStatusChanged(_RouteStatusFilter.completed),
              ),
              _FilterChip(
                label: 'Canceladas',
                selected: statusFilter == _RouteStatusFilter.cancelled,
                icon: Icons.cancel_outlined,
                color: AppColors.accentRed,
                onTap: () => onStatusChanged(_RouteStatusFilter.cancelled),
              ),
              _FilterChip(
                label: 'Todas',
                selected: statusFilter == _RouteStatusFilter.all,
                icon: Icons.all_inclusive_rounded,
                onTap: () => onStatusChanged(_RouteStatusFilter.all),
              ),
            ],
          );
          final counter = _Metric(
            icon: Icons.filter_alt_outlined,
            label: '$resultCount de $totalCount',
            color: AppColors.accentBlue,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 10),
                sort,
                const SizedBox(height: 10),
                chips,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    counter,
                    if (hasFilters)
                      TextButton.icon(
                        onPressed: onClearFilters,
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 18,
                        ),
                        label: const Text('Limpar'),
                      ),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: sort),
                  const SizedBox(width: 10),
                  counter,
                  if (hasFilters) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: const Text('Limpar'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              chips,
            ],
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final PurchaseDeliveryRoute route;
  final PurchaseDeliveryRouteService service;

  const _RouteCard({required this.route, required this.service});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusAccent = _routeStatusColor(route.status);
    final kmLabel =
        route.status == PurchaseRouteStatus.inProgress
            ? 'KM parcial'
            : 'KM realizado';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppDecorations.cardSurface(accent: statusAccent, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final title = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppDecorations.iconTile(statusAccent),
                    child: Icon(Icons.alt_route_rounded, color: statusAccent),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.driverName.trim().isEmpty
                              ? 'Motorista nao informado'
                              : route.driverName,
                          maxLines: 1,
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
              );
              final status = _RouteStatusChip(status: route.status);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 10), status],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 10),
                  status,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (route.scheduledDate != null)
                _Metric(
                  icon: Icons.event_outlined,
                  label: dateFormat.format(route.scheduledDate!),
                  color: AppColors.accentGold,
                ),
              if (route.startedAt != null)
                _Metric(
                  icon: Icons.play_arrow_rounded,
                  label: 'Inicio ${dateFormat.format(route.startedAt!)}',
                  color: AppColors.accentBlue,
                ),
              if (route.completedAt != null)
                _Metric(
                  icon: Icons.flag_outlined,
                  label: 'Fim ${dateFormat.format(route.completedAt!)}',
                  color: AppColors.accentGreen,
                ),
              _Metric(
                icon: Icons.speed_outlined,
                label:
                    '$kmLabel: ${route.actualDistanceKm.toStringAsFixed(1)} km',
                color:
                    route.actualDistanceKm > 0
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
              ),
              if (route.estimatedDistanceKm > 0)
                _Metric(
                  icon: Icons.straighten_outlined,
                  label:
                      'Previsto: ${route.estimatedDistanceKm.toStringAsFixed(1)} km',
                  color: AppColors.accentGold,
                ),
            ],
          ),
          if (route.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _NoteBox(text: route.notes.trim()),
          ],
          const SizedBox(height: 12),
          StreamBuilder<List<PurchaseDeliveryRouteStop>>(
            stream: service.watchStops(route.id),
            builder: (context, snapshot) {
              final stops =
                  snapshot.data ?? const <PurchaseDeliveryRouteStop>[];
              if (!snapshot.hasData) {
                return const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.accentGold,
                );
              }
              if (stops.isEmpty) {
                return const Text(
                  'Sem paradas vinculadas.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                );
              }

              final completedStops =
                  stops
                      .where(
                        (stop) =>
                            stop.status == PurchaseRouteStopStatus.completed,
                      )
                      .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteProgress(
                    completedStops: completedStops,
                    totalStops: stops.length,
                  ),
                  const SizedBox(height: 10),
                  for (final stop in stops) _StopLine(stop: stop),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  final PurchaseDeliveryRouteStop stop;

  const _StopLine({required this.stop});

  @override
  Widget build(BuildContext context) {
    final color =
        stop.stopType == PurchaseRouteStopType.pickup
            ? AppColors.accentGold
            : AppColors.accentBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              stop.sequence.toString(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${stop.stopType.label} - ${stop.supplierName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StopStatusChip(status: stop.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  stop.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (stop.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    stop.notes.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
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
}

class _RouteProgress extends StatelessWidget {
  final int completedStops;
  final int totalStops;

  const _RouteProgress({
    required this.completedStops,
    required this.totalStops,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalStops == 0 ? 0.0 : completedStops / totalStops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 15,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              '$completedStops de $totalStops paradas concluidas',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.62),
            color: AppColors.accentGreen,
          ),
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: AppDecorations.iconTile(AppColors.accentGold),
          child: Icon(icon, color: AppColors.accentGold, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Metric({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: 13),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.color = AppColors.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? color : AppColors.textMuted,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.46),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.7)
                : AppColors.borderColor.withValues(alpha: 0.55),
      ),
    );
  }
}

class _RouteStatusChip extends StatelessWidget {
  final PurchaseRouteStatus status;

  const _RouteStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _routeStatusColor(status);
    return _Metric(icon: Icons.circle, label: status.label, color: color);
  }
}

class _StopStatusChip extends StatelessWidget {
  final PurchaseRouteStopStatus status;

  const _StopStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PurchaseRouteStopStatus.pending => AppColors.accentGold,
      PurchaseRouteStopStatus.completed => AppColors.accentGreen,
      PurchaseRouteStopStatus.skipped => AppColors.accentRed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;

  const _NoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.textMuted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sticky_note_2_outlined,
            size: 15,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoading extends StatelessWidget {
  final String message;

  const _InlineLoading({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentGold),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: AppDecorations.cardInnerSurface(),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: AppDecorations.iconTile(AppColors.accentGold),
            child: Icon(icon, color: AppColors.accentGold, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

int _compareNullableDateDesc(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return right.compareTo(left);
}

int _routeStatusRank(PurchaseRouteStatus status) {
  switch (status) {
    case PurchaseRouteStatus.inProgress:
      return 0;
    case PurchaseRouteStatus.planned:
      return 1;
    case PurchaseRouteStatus.completed:
      return 2;
    case PurchaseRouteStatus.cancelled:
      return 3;
  }
}

Color _routeStatusColor(PurchaseRouteStatus status) {
  switch (status) {
    case PurchaseRouteStatus.planned:
      return AppColors.accentGold;
    case PurchaseRouteStatus.inProgress:
      return AppColors.accentBlue;
    case PurchaseRouteStatus.completed:
      return AppColors.accentGreen;
    case PurchaseRouteStatus.cancelled:
      return AppColors.accentRed;
  }
}

int _countRouteStatus(
  List<PurchaseDeliveryRoute> routes,
  PurchaseRouteStatus status,
) {
  return routes.where((route) => route.status == status).length;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _routeSortLabel(_RouteSortOption option) {
  switch (option) {
    case _RouteSortOption.scheduledDesc:
      return 'Data recente';
    case _RouteSortOption.activeFirst:
      return 'Ativas primeiro';
    case _RouteSortOption.driver:
      return 'Motorista';
    case _RouteSortOption.distanceDesc:
      return 'Maior KM';
  }
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
