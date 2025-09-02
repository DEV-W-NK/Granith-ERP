import 'package:flutter/foundation.dart';
import 'package:project_granith/contants/supplier_constants.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/supplier_service.dart';

class SupplierController extends ChangeNotifier {
  final SupplierService _service;

  SupplierController(this._service);

  // State variables
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isGridView = true;
  String _searchQuery = '';
  String _selectedFilter = SupplierConstants.filterAll;

  // Getters
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isGridView => _isGridView;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  List<Supplier> get filteredSuppliers {
    var filtered = _suppliers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((supplier) {
            return supplier.name.toLowerCase().contains(query) ||
                supplier.cnpj.contains(query) ||
                (supplier.formattedCnpj.contains(query));
          }).toList();
    }

    // Apply status filter
    switch (_selectedFilter) {
      case SupplierConstants.filterActive:
        filtered = filtered.where((supplier) => supplier.isActive).toList();
        break;
      case SupplierConstants.filterInactive:
        filtered = filtered.where((supplier) => !supplier.isActive).toList();
        break;
      case SupplierConstants.filterAll:
      default:
        // No additional filtering needed
        break;
    }

    // Sort by name
    filtered.sort((a, b) => a.name.compareTo(b.name));

    return filtered;
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedFilter != SupplierConstants.filterAll;

  // Load suppliers
  Future<void> loadSuppliers({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(
        SupplierConstants.loadingDelay,
      ); // Simulate network delay
      final suppliers = await _service.getSuppliers();
      _suppliers = suppliers;
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar fornecedores: ${e.toString()}');
    }
  }

  // Create supplier
  Future<void> createSupplier(Supplier supplier) async {
    try {
      _setLoading(true);
      final newSupplier = await _service.createSupplier(supplier);
      _suppliers.add(newSupplier);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao criar fornecedor: ${e.toString()}');
      rethrow;
    }
  }

  // Update supplier
  Future<void> updateSupplier(Supplier supplier) async {
    try {
      _setLoading(true);
      final updatedSupplier = await _service.updateSupplier(supplier);
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao atualizar fornecedor: ${e.toString()}');
      rethrow;
    }
  }

  // Delete supplier
  Future<void> deleteSupplier(String id) async {
    try {
      _setLoading(true);
      await _service.deleteSupplier(id);
      _suppliers.removeWhere((supplier) => supplier.id == id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao excluir fornecedor: ${e.toString()}');
      rethrow;
    }
  }

  // Toggle supplier status
  Future<void> toggleSupplierStatus(String id, bool isActive) async {
    try {
      final updatedSupplier = await _service.toggleSupplierStatus(id, isActive);

      final index = _suppliers.indexWhere((s) => s.id == id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }

      notifyListeners();
    } catch (e) {
      _setError('Erro ao alterar status: ${e.toString()}');
      rethrow;
    }
  }

  // View mode controls
  void setViewMode(bool isGrid) {
    if (_isGridView != isGrid) {
      _isGridView = isGrid;
      notifyListeners();
    }
  }

  // Search controls
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // Filter controls
  void updateFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void clearFilters() {
    bool hasChanges = false;

    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      hasChanges = true;
    }

    if (_selectedFilter != SupplierConstants.filterAll) {
      _selectedFilter = SupplierConstants.filterAll;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Validation methods
  String? validateSupplierName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return SupplierConstants.errorNameRequired;
    }

    if (name.trim().length < SupplierConstants.minNameLength) {
      return 'Nome deve ter pelo menos ${SupplierConstants.minNameLength} caracteres';
    }

    if (name.trim().length > SupplierConstants.maxNameLength) {
      return 'Nome deve ter no máximo ${SupplierConstants.maxNameLength} caracteres';
    }

    return null;
  }

  String? validateSupplierCnpj(String? cnpj, {String? excludeId}) {
    if (cnpj == null || cnpj.trim().isEmpty) {
      return SupplierConstants.errorCnpjRequired;
    }

    // Remove formatting
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanCnpj.length != SupplierConstants.cnpjLength) {
      return 'CNPJ deve ter 14 dígitos';
    }

    // Check if CNPJ already exists (excluding current supplier if editing)
    final existingSupplier =
        _suppliers
            .where(
              (supplier) =>
                  supplier.cnpj == cleanCnpj && supplier.id != excludeId,
            )
            .firstOrNull;

    if (existingSupplier != null) {
      return SupplierConstants.errorCnpjAlreadyExists;
    }

    // Validate CNPJ algorithm (basic validation)
    if (!_isValidCnpj(cleanCnpj)) {
      return SupplierConstants.errorInvalidCnpj;
    }

    return null;
  }

  // CNPJ validation algorithm
  bool _isValidCnpj(String cnpj) {
    if (cnpj.length != 14) return false;

    // Check for known invalid patterns
    if (RegExp(r'^(\d)\1+$').hasMatch(cnpj)) return false;

    try {
      // Calculate first verification digit
      int sum = 0;
      List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      for (int i = 0; i < 12; i++) {
        sum += int.parse(cnpj[i]) * weights1[i];
      }

      int remainder = sum % 11;
      int digit1 = remainder < 2 ? 0 : 11 - remainder;

      if (digit1 != int.parse(cnpj[12])) return false;

      // Calculate second verification digit
      sum = 0;
      List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

      for (int i = 0; i < 13; i++) {
        sum += int.parse(cnpj[i]) * weights2[i];
      }

      remainder = sum % 11;
      int digit2 = remainder < 2 ? 0 : 11 - remainder;

      return digit2 == int.parse(cnpj[13]);
    } catch (e) {
      return false;
    }
  }

  // Utility methods
  String formatCnpj(String cnpj) {
    final clean = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length != 14) return cnpj;

    return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12, 14)}';
  }

  String cleanCnpj(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (loading) _clearError();
      notifyListeners();
    }
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_hasError) {
      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> exportSuppliers(String format) async {
    try {
      _setLoading(true);

      final suppliers = filteredSuppliers;

      if (suppliers.isEmpty) {
        _setError('Nenhum fornecedor para exportar');
        return;
      }

      switch (format.toLowerCase()) {
        case 'csv':
          await _exportToCSV(suppliers);
          break;
        case 'pdf':
          await _exportToPDF(suppliers);
          break;
        default:
          _setError('Formato de exportação não suportado');
          return;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Erro ao exportar fornecedores: ${e.toString()}');
    }
  }

  Future<void> _exportToCSV(List<Supplier> suppliers) async {
    try {
      final csvData = StringBuffer();

      // Header
      csvData.writeln('Nome,CNPJ,Status,Data de Criação,Última Atualização');

      // Data rows
      for (final supplier in suppliers) {
        final name = supplier.name.replaceAll('"', '""'); // Escape quotes
        final cnpj = formatCnpj(supplier.cnpj);
        final status = supplier.isActive ? 'Ativo' : 'Inativo';
        final createdAt = _formatDate(supplier.createdAt);
        final updatedAt = _formatDate(supplier.updatedAt);

        csvData.writeln('"$name","$cnpj","$status","$createdAt","$updatedAt"');
      }

      // For now, just show success message
      // In a real app, you'd save the file using file_picker or share package
      _showExportSuccessMessage('CSV exportado com sucesso!');
    } catch (e) {
      throw Exception('Erro ao gerar CSV: ${e.toString()}');
    }
  }

  /// Export suppliers to PDF format
  Future<void> _exportToPDF(List<Supplier> suppliers) async {
    try {
      // For now, just show success message
      // In a real app, you'd use pdf package to generate PDF
      _showExportSuccessMessage('PDF exportado com sucesso!');
    } catch (e) {
      throw Exception('Erro ao gerar PDF: ${e.toString()}');
    }
  }

  /// Format date for export
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Show export success message
  void _showExportSuccessMessage(String message) {
    // This would typically be handled by the UI layer
    // For now, we'll just clear the loading state
    _setLoading(false);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
