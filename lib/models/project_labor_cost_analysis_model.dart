import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';

class ProjectLaborWorkHourEntry {
  final String id;
  final String projectId;
  final String employeeId;
  final String employeeName;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final String status;
  final String reason;
  final String source;

  const ProjectLaborWorkHourEntry({
    required this.id,
    required this.projectId,
    required this.employeeId,
    required this.employeeName,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.status,
    required this.reason,
    required this.source,
  });

  factory ProjectLaborWorkHourEntry.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final startAt = DbValue.toDateTime(map['startAt']) ?? DateTime.now();
    final endAt =
        DbValue.toDateTime(map['endAt']) ??
        startAt.add(
          Duration(
            minutes: _toInt(map['durationMinutes']).clamp(0, 1440).toInt(),
          ),
        );

    return ProjectLaborWorkHourEntry(
      id: docId,
      projectId: map['projectId']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeName: map['employeeName']?.toString() ?? '',
      startAt: startAt,
      endAt: endAt,
      durationMinutes: _toInt(map['durationMinutes']),
      status: map['status']?.toString() ?? 'pending',
      reason: map['reason']?.toString() ?? '',
      source: map['source']?.toString() ?? 'mobile',
    );
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  double get durationHours => durationMinutes / 60;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProjectLaborTimeClockEvent {
  final String id;
  final String projectId;
  final String employeeId;
  final String employeeName;
  final DateTime eventAt;
  final String eventKind;
  final String punchType;
  final String geofenceStatus;
  final String reason;
  final String receiptCode;

  const ProjectLaborTimeClockEvent({
    required this.id,
    required this.projectId,
    required this.employeeId,
    required this.employeeName,
    required this.eventAt,
    required this.eventKind,
    required this.punchType,
    required this.geofenceStatus,
    required this.reason,
    required this.receiptCode,
  });

  factory ProjectLaborTimeClockEvent.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return ProjectLaborTimeClockEvent(
      id: docId,
      projectId: map['projectId']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeName: map['employeeName']?.toString() ?? '',
      eventAt: DbValue.toDateTime(map['eventAt']) ?? DateTime.now(),
      eventKind: map['eventKind']?.toString() ?? '',
      punchType: map['punchType']?.toString() ?? 'unknown',
      geofenceStatus: map['geofenceStatus']?.toString() ?? 'unknown',
      reason: map['reason']?.toString() ?? '',
      receiptCode: map['receiptCode']?.toString() ?? '',
    );
  }

  bool get isAcceptedPunch => eventKind == 'punch';
  bool get isEntry => punchType == 'entry';
  bool get isExit => punchType == 'exit';
}

class ProjectLaborCostReport {
  final double consolidatedCost;
  final double approvedMobileCost;
  final double pendingMobileCost;
  final double dailyEstimateUsedCost;
  final double dailyEstimateRawCost;
  final int approvedMobileMinutes;
  final int pendingMobileMinutes;
  final int dailyEstimatedPeople;
  final int dailyLogsCount;
  final int mobileEntriesCount;
  final int timeClockEventsCount;
  final int timeClockPairedEntriesCount;
  final int linkedTeamMembersCount;
  final int linkedTeamMembersWithSalaryCount;
  final double averageHourlyRate;
  final List<ProjectLaborEmployeeCost> employeeCosts;
  final List<ProjectLaborRoleCost> roleCosts;
  final List<ProjectLaborDayCost> dayCosts;
  final List<String> missingSalaryNames;

  const ProjectLaborCostReport({
    required this.consolidatedCost,
    required this.approvedMobileCost,
    required this.pendingMobileCost,
    required this.dailyEstimateUsedCost,
    required this.dailyEstimateRawCost,
    required this.approvedMobileMinutes,
    required this.pendingMobileMinutes,
    required this.dailyEstimatedPeople,
    required this.dailyLogsCount,
    required this.mobileEntriesCount,
    required this.timeClockEventsCount,
    required this.timeClockPairedEntriesCount,
    required this.linkedTeamMembersCount,
    required this.linkedTeamMembersWithSalaryCount,
    required this.averageHourlyRate,
    required this.employeeCosts,
    required this.roleCosts,
    required this.dayCosts,
    required this.missingSalaryNames,
  });

  bool get hasAnySource => dailyLogsCount > 0 || mobileEntriesCount > 0;
  double get approvedMobileHours => approvedMobileMinutes / 60;
  double get pendingMobileHours => pendingMobileMinutes / 60;
  double get salaryCoverage {
    if (linkedTeamMembersCount == 0) return 0;
    return linkedTeamMembersWithSalaryCount / linkedTeamMembersCount;
  }
}

class ProjectLaborEmployeeCost {
  final String employeeId;
  final String employeeName;
  final String roleName;
  final double approvedCost;
  final double pendingCost;
  final int approvedMinutes;
  final int pendingMinutes;
  final int entriesCount;
  final int timeClockEntriesCount;
  final int manualEntriesCount;
  final DateTime? firstAt;
  final DateTime? lastAt;

  const ProjectLaborEmployeeCost({
    required this.employeeId,
    required this.employeeName,
    required this.roleName,
    required this.approvedCost,
    required this.pendingCost,
    required this.approvedMinutes,
    required this.pendingMinutes,
    required this.entriesCount,
    required this.timeClockEntriesCount,
    required this.manualEntriesCount,
    required this.firstAt,
    required this.lastAt,
  });

  double get totalCost => approvedCost + pendingCost;
  int get totalMinutes => approvedMinutes + pendingMinutes;
  double get approvedHours => approvedMinutes / 60;
  double get pendingHours => pendingMinutes / 60;
  double get totalHours => totalMinutes / 60;
}

class ProjectLaborRoleCost {
  final String name;
  final double mobileCost;
  final double mobileHours;
  final double estimatedCost;
  final double estimatedHours;
  final int estimatedPeopleDays;

  const ProjectLaborRoleCost({
    required this.name,
    required this.mobileCost,
    required this.mobileHours,
    required this.estimatedCost,
    required this.estimatedHours,
    required this.estimatedPeopleDays,
  });

  double get totalCost => mobileCost + estimatedCost;
  double get totalHours => mobileHours + estimatedHours;
}

class ProjectLaborDayCost {
  final DateTime date;
  final double approvedMobileCost;
  final double pendingMobileCost;
  final double dailyEstimatedCost;
  final int approvedMobileMinutes;
  final int pendingMobileMinutes;
  final int dailyEstimatedPeople;
  final bool usesDailyEstimate;

  const ProjectLaborDayCost({
    required this.date,
    this.approvedMobileCost = 0,
    this.pendingMobileCost = 0,
    this.dailyEstimatedCost = 0,
    this.approvedMobileMinutes = 0,
    this.pendingMobileMinutes = 0,
    this.dailyEstimatedPeople = 0,
    this.usesDailyEstimate = false,
  });

  double get consolidatedCost =>
      approvedMobileCost + (usesDailyEstimate ? dailyEstimatedCost : 0);
  int get trackedMobileMinutes => approvedMobileMinutes + pendingMobileMinutes;
}

class ProjectLaborCostCalculator {
  static const double monthlyHours = 220;
  static const double defaultDailyHours = 8;

  const ProjectLaborCostCalculator();

  ProjectLaborCostReport build({
    required String projectId,
    String? coordinatorId,
    required List<DailyLogModel> dailyLogs,
    required List<ProjectLaborWorkHourEntry> mobileEntries,
    List<ProjectLaborTimeClockEvent> timeClockEvents = const [],
    required List<EmployeeModel> employees,
    required List<TeamModel> teams,
  }) {
    final filteredLogs =
        dailyLogs.where((log) => log.projectId == projectId).toList();
    final timeClockEntries = _buildEntriesFromTimeClockEvents(
      projectId: projectId,
      events: timeClockEvents,
    );
    final filteredEntries =
        [...mobileEntries, ...timeClockEntries]
            .where((entry) => entry.projectId == projectId)
            .where((entry) => entry.durationMinutes > 0)
            .where((entry) => entry.status != 'rejected')
            .where((entry) => entry.status != 'cancelled')
            .toList();

    final employeesById = {
      for (final employee in employees) employee.id: employee,
    };
    final employeesByName = {
      for (final employee in employees) _normalize(employee.name): employee,
    };

    final linkedEmployeeIds = <String>{};
    for (final team in teams) {
      if (team.projectId != projectId || !team.isActive) continue;
      linkedEmployeeIds.addAll(team.memberIds);
      final leaderId = team.leaderId?.trim();
      if (leaderId != null && leaderId.isNotEmpty) {
        linkedEmployeeIds.add(leaderId);
      }
    }
    final normalizedCoordinatorId = coordinatorId?.trim();
    if (normalizedCoordinatorId != null && normalizedCoordinatorId.isNotEmpty) {
      linkedEmployeeIds.add(normalizedCoordinatorId);
    }

    final linkedEmployees =
        linkedEmployeeIds
            .map((id) => employeesById[id])
            .whereType<EmployeeModel>()
            .where((employee) => employee.isActive)
            .toList();
    final allActiveEmployees =
        employees.where((employee) => employee.isActive).toList();
    final salaryBase =
        linkedEmployees.isNotEmpty ? linkedEmployees : allActiveEmployees;
    final averageHourlyRate = _averageHourlyRate(salaryBase);
    final roleRates = _buildRoleRates(salaryBase);
    final roleBuckets = <String, _RoleCostAccumulator>{};
    final employeeBuckets = <String, _EmployeeCostAccumulator>{};
    final dayBuckets = <DateTime, _DayCostAccumulator>{};
    final missingSalaryNames = <String>{};

    double approvedMobileCost = 0;
    double pendingMobileCost = 0;
    int approvedMobileMinutes = 0;
    int pendingMobileMinutes = 0;

    for (final entry in filteredEntries) {
      final employee =
          employeesById[entry.employeeId] ??
          employeesByName[_normalize(entry.employeeName)];
      final hourlyRate = _employeeHourlyRate(employee) ?? averageHourlyRate;
      final cost = hourlyRate * entry.durationHours;
      final roleName = _employeeRoleName(
        employee,
        fallback: entry.employeeName,
      );
      final employeeBucket = employeeBuckets.putIfAbsent(
        _employeeBucketKey(employee, entry),
        () => _EmployeeCostAccumulator(
          employeeId: employee?.id ?? entry.employeeId,
          employeeName: _employeeDisplayName(employee, entry),
          roleName: roleName,
        ),
      );
      employeeBucket.entriesCount += 1;
      if (entry.source == 'time_clock_afd_events') {
        employeeBucket.timeClockEntriesCount += 1;
      } else {
        employeeBucket.manualEntriesCount += 1;
      }
      employeeBucket.registerRange(entry.startAt, entry.endAt);

      final day = _dateOnly(entry.startAt);
      final dayBucket = dayBuckets.putIfAbsent(
        day,
        () => _DayCostAccumulator(day),
      );

      if (entry.isApproved) {
        approvedMobileCost += cost;
        approvedMobileMinutes += entry.durationMinutes;
        dayBucket.approvedMobileCost += cost;
        dayBucket.approvedMobileMinutes += entry.durationMinutes;
        final roleBucket = roleBuckets.putIfAbsent(
          roleName,
          () => _RoleCostAccumulator(roleName),
        );
        roleBucket.mobileCost += cost;
        roleBucket.mobileHours += entry.durationHours;
        employeeBucket.approvedCost += cost;
        employeeBucket.approvedMinutes += entry.durationMinutes;
      } else if (entry.isPending) {
        pendingMobileCost += cost;
        pendingMobileMinutes += entry.durationMinutes;
        dayBucket.pendingMobileCost += cost;
        dayBucket.pendingMobileMinutes += entry.durationMinutes;
        employeeBucket.pendingCost += cost;
        employeeBucket.pendingMinutes += entry.durationMinutes;
      }

      if (employee != null && employee.baseSalary <= 0) {
        missingSalaryNames.add(employee.name);
      }
    }

    double dailyEstimateRawCost = 0;
    int dailyEstimatedPeople = 0;
    final dailyEstimates = <_DailyEstimate>[];
    for (final log in filteredLogs) {
      final day = _dateOnly(log.date);
      final dayBucket = dayBuckets.putIfAbsent(
        day,
        () => _DayCostAccumulator(day),
      );

      log.manpower.forEach((rawRole, amount) {
        final people = amount < 0 ? 0 : amount;
        if (people == 0) return;

        final roleName = _cleanLabel(rawRole, fallback: 'Equipe');
        final hourlyRate = _roleHourlyRate(
          rawRole,
          roleRates,
          averageHourlyRate,
        );
        final hours = people * defaultDailyHours;
        final cost = hours * hourlyRate;

        dailyEstimateRawCost += cost;
        dailyEstimatedPeople += people;
        dayBucket.dailyEstimatedCost += cost;
        dayBucket.dailyEstimatedPeople += people;
        dailyEstimates.add(
          _DailyEstimate(
            day: day,
            roleName: roleName,
            cost: cost,
            hours: hours,
            people: people,
          ),
        );
      });
    }

    double dailyEstimateUsedCost = 0;
    for (final estimate in dailyEstimates) {
      final dayBucket = dayBuckets[estimate.day];
      if (dayBucket == null || dayBucket.hasMobileHours) continue;

      dailyEstimateUsedCost += estimate.cost;
      final roleBucket = roleBuckets.putIfAbsent(
        estimate.roleName,
        () => _RoleCostAccumulator(estimate.roleName),
      );
      roleBucket.estimatedCost += estimate.cost;
      roleBucket.estimatedHours += estimate.hours;
      roleBucket.estimatedPeopleDays += estimate.people;
    }

    final roleCosts =
        roleBuckets.values
            .map((bucket) => bucket.toRoleCost())
            .where((role) => role.totalCost > 0 || role.totalHours > 0)
            .toList()
          ..sort((a, b) => b.totalCost.compareTo(a.totalCost));

    final employeeCosts =
        employeeBuckets.values
            .map((bucket) => bucket.toEmployeeCost())
            .where((employee) => employee.totalMinutes > 0)
            .toList()
          ..sort((a, b) {
            final byMinutes = a.totalMinutes.compareTo(b.totalMinutes);
            if (byMinutes != 0) return byMinutes;
            return a.employeeName.compareTo(b.employeeName);
          });

    final dayCosts =
        dayBuckets.values.map((bucket) => bucket.toDayCost()).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final linkedWithSalary =
        linkedEmployees.where((employee) => employee.baseSalary > 0).length;

    return ProjectLaborCostReport(
      consolidatedCost: approvedMobileCost + dailyEstimateUsedCost,
      approvedMobileCost: approvedMobileCost,
      pendingMobileCost: pendingMobileCost,
      dailyEstimateUsedCost: dailyEstimateUsedCost,
      dailyEstimateRawCost: dailyEstimateRawCost,
      approvedMobileMinutes: approvedMobileMinutes,
      pendingMobileMinutes: pendingMobileMinutes,
      dailyEstimatedPeople: dailyEstimatedPeople,
      dailyLogsCount: filteredLogs.length,
      mobileEntriesCount: filteredEntries.length,
      timeClockEventsCount:
          timeClockEvents
              .where((event) => event.projectId == projectId)
              .where((event) => event.isAcceptedPunch)
              .length,
      timeClockPairedEntriesCount: timeClockEntries.length,
      linkedTeamMembersCount: linkedEmployees.length,
      linkedTeamMembersWithSalaryCount: linkedWithSalary,
      averageHourlyRate: averageHourlyRate,
      employeeCosts: employeeCosts,
      roleCosts: roleCosts,
      dayCosts: dayCosts,
      missingSalaryNames: missingSalaryNames.toList()..sort(),
    );
  }

  static List<ProjectLaborWorkHourEntry> _buildEntriesFromTimeClockEvents({
    required String projectId,
    required List<ProjectLaborTimeClockEvent> events,
  }) {
    final ordered =
        events
            .where((event) => event.projectId == projectId)
            .where((event) => event.isAcceptedPunch)
            .where((event) => event.isEntry || event.isExit)
            .toList()
          ..sort((a, b) => a.eventAt.compareTo(b.eventAt));

    final openEntries = <String, ProjectLaborTimeClockEvent>{};
    final entries = <ProjectLaborWorkHourEntry>[];

    for (final event in ordered) {
      final key = _timeClockEmployeeKey(event);
      if (key.isEmpty) continue;

      if (event.isEntry) {
        openEntries[key] = event;
        continue;
      }

      final entryEvent = openEntries.remove(key);
      if (entryEvent == null) continue;

      final durationMinutes =
          event.eventAt.difference(entryEvent.eventAt).inMinutes;
      if (durationMinutes <= 0 || durationMinutes > 18 * 60) continue;

      entries.add(
        ProjectLaborWorkHourEntry(
          id: 'time-clock-${entryEvent.id}-${event.id}',
          projectId: projectId,
          employeeId:
              entryEvent.employeeId.isNotEmpty
                  ? entryEvent.employeeId
                  : event.employeeId,
          employeeName:
              entryEvent.employeeName.isNotEmpty
                  ? entryEvent.employeeName
                  : event.employeeName,
          startAt: entryEvent.eventAt,
          endAt: event.eventAt,
          durationMinutes: durationMinutes,
          status: 'approved',
          reason: _timeClockReason(entryEvent, event),
          source: 'time_clock_afd_events',
        ),
      );
    }

    return entries;
  }

  static double _averageHourlyRate(List<EmployeeModel> employees) {
    final rates =
        employees
            .map(_employeeHourlyRate)
            .whereType<double>()
            .where((rate) => rate > 0)
            .toList();
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  static Map<String, double> _buildRoleRates(List<EmployeeModel> employees) {
    final grouped = <String, List<double>>{};
    for (final employee in employees) {
      final rate = _employeeHourlyRate(employee);
      if (rate == null || rate <= 0) continue;
      for (final key in [
        employee.jobTitle,
        employee.sector,
        employee.role.label,
        employee.name,
      ]) {
        final normalized = _normalize(key);
        if (normalized.isEmpty) continue;
        grouped.putIfAbsent(normalized, () => <double>[]).add(rate);
      }
    }

    return grouped.map((key, rates) {
      return MapEntry(key, rates.reduce((a, b) => a + b) / rates.length);
    });
  }

  static double _roleHourlyRate(
    String role,
    Map<String, double> roleRates,
    double fallback,
  ) {
    final normalized = _normalize(role);
    if (normalized.isEmpty || normalized == 'geral' || normalized == 'equipe') {
      return fallback;
    }
    return roleRates[normalized] ?? fallback;
  }

  static double? _employeeHourlyRate(EmployeeModel? employee) {
    if (employee == null || employee.baseSalary <= 0) return null;
    return employee.baseSalary / monthlyHours;
  }

  static String _employeeBucketKey(
    EmployeeModel? employee,
    ProjectLaborWorkHourEntry entry,
  ) {
    if (employee != null) return 'employee:${employee.id}';
    final id = entry.employeeId.trim();
    if (id.isNotEmpty) return 'entry:$id';
    final name = _normalize(entry.employeeName);
    return name.isEmpty ? 'entry:${entry.id}' : 'name:$name';
  }

  static String _employeeDisplayName(
    EmployeeModel? employee,
    ProjectLaborWorkHourEntry entry,
  ) {
    if (employee != null && employee.name.trim().isNotEmpty) {
      return employee.name.trim();
    }
    final name = entry.employeeName.trim();
    return name.isEmpty ? 'Funcionario sem nome' : name;
  }

  static String _employeeRoleName(EmployeeModel? employee, {String? fallback}) {
    if (employee == null) return _cleanLabel(fallback, fallback: 'Sem vinculo');
    return _cleanLabel(
      employee.jobTitle.isNotEmpty ? employee.jobTitle : employee.sector,
      fallback: employee.role.label,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _cleanLabel(String? value, {required String fallback}) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return fallback;
    return text
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _normalize(String? value) {
    final lower = value?.trim().toLowerCase() ?? '';
    if (lower.isEmpty) return '';
    const replacements = {
      '\u00e1': 'a',
      '\u00e0': 'a',
      '\u00e2': 'a',
      '\u00e3': 'a',
      '\u00e4': 'a',
      '\u00e9': 'e',
      '\u00ea': 'e',
      '\u00ed': 'i',
      '\u00f3': 'o',
      '\u00f4': 'o',
      '\u00f5': 'o',
      '\u00fa': 'u',
      '\u00fc': 'u',
      '\u00e7': 'c',
    };
    return lower
        .split('')
        .map((char) => replacements[char] ?? char)
        .join()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _timeClockEmployeeKey(ProjectLaborTimeClockEvent event) {
    final id = event.employeeId.trim();
    if (id.isNotEmpty) return 'employee:$id';
    final name = _normalize(event.employeeName);
    if (name.isNotEmpty) return 'name:$name';
    return event.id;
  }

  static String _timeClockReason(
    ProjectLaborTimeClockEvent start,
    ProjectLaborTimeClockEvent end,
  ) {
    final receipts = [
      start.receiptCode.trim(),
      end.receiptCode.trim(),
    ].where((receipt) => receipt.isNotEmpty).join(' / ');
    if (receipts.isEmpty) return 'Ponto registrado no app';
    return 'Ponto registrado no app ($receipts)';
  }
}

class _RoleCostAccumulator {
  final String name;
  double mobileCost = 0;
  double mobileHours = 0;
  double estimatedCost = 0;
  double estimatedHours = 0;
  int estimatedPeopleDays = 0;

  _RoleCostAccumulator(this.name);

  ProjectLaborRoleCost toRoleCost() {
    return ProjectLaborRoleCost(
      name: name,
      mobileCost: mobileCost,
      mobileHours: mobileHours,
      estimatedCost: estimatedCost,
      estimatedHours: estimatedHours,
      estimatedPeopleDays: estimatedPeopleDays,
    );
  }
}

class _EmployeeCostAccumulator {
  final String employeeId;
  final String employeeName;
  final String roleName;
  double approvedCost = 0;
  double pendingCost = 0;
  int approvedMinutes = 0;
  int pendingMinutes = 0;
  int entriesCount = 0;
  int timeClockEntriesCount = 0;
  int manualEntriesCount = 0;
  DateTime? firstAt;
  DateTime? lastAt;

  _EmployeeCostAccumulator({
    required this.employeeId,
    required this.employeeName,
    required this.roleName,
  });

  void registerRange(DateTime startAt, DateTime endAt) {
    if (firstAt == null || startAt.isBefore(firstAt!)) {
      firstAt = startAt;
    }
    if (lastAt == null || endAt.isAfter(lastAt!)) {
      lastAt = endAt;
    }
  }

  ProjectLaborEmployeeCost toEmployeeCost() {
    return ProjectLaborEmployeeCost(
      employeeId: employeeId,
      employeeName: employeeName,
      roleName: roleName,
      approvedCost: approvedCost,
      pendingCost: pendingCost,
      approvedMinutes: approvedMinutes,
      pendingMinutes: pendingMinutes,
      entriesCount: entriesCount,
      timeClockEntriesCount: timeClockEntriesCount,
      manualEntriesCount: manualEntriesCount,
      firstAt: firstAt,
      lastAt: lastAt,
    );
  }
}

class _DayCostAccumulator {
  final DateTime date;
  double approvedMobileCost = 0;
  double pendingMobileCost = 0;
  double dailyEstimatedCost = 0;
  int approvedMobileMinutes = 0;
  int pendingMobileMinutes = 0;
  int dailyEstimatedPeople = 0;

  _DayCostAccumulator(this.date);

  bool get hasMobileHours =>
      approvedMobileMinutes > 0 || pendingMobileMinutes > 0;

  ProjectLaborDayCost toDayCost() {
    return ProjectLaborDayCost(
      date: date,
      approvedMobileCost: approvedMobileCost,
      pendingMobileCost: pendingMobileCost,
      dailyEstimatedCost: dailyEstimatedCost,
      approvedMobileMinutes: approvedMobileMinutes,
      pendingMobileMinutes: pendingMobileMinutes,
      dailyEstimatedPeople: dailyEstimatedPeople,
      usesDailyEstimate: !hasMobileHours && dailyEstimatedCost > 0,
    );
  }
}

class _DailyEstimate {
  final DateTime day;
  final String roleName;
  final double cost;
  final double hours;
  final int people;

  const _DailyEstimate({
    required this.day,
    required this.roleName,
    required this.cost,
    required this.hours,
    required this.people,
  });
}
