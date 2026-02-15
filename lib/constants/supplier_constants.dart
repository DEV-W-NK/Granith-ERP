class SupplierConstants {
  // Responsive breakpoints
  static const double desktopBreakpoint = 1024;
  static const double tabletBreakpoint = 768;
  
  // View modes
  static const String gridView = 'grid';
  static const String listView = 'list';
  
  // Filter types
  static const String filterAll = 'all';
  static const String filterActive = 'active';
  static const String filterInactive = 'inactive';
  
  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int cnpjLength = 14;
  
  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingDelay = Duration(milliseconds: 500);
  
  // Grid settings
  static const double gridSpacing = 16.0;
  static const double listSpacing = 12.0;
  
  // Card dimensions
  static const double cardBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  
  // Export types
  static const String exportCsv = 'CSV';
  static const String exportPdf = 'PDF';
  
  // Error messages
  static const String errorGeneric = 'Erro desconhecido ocorreu';
  static const String errorNetwork = 'Erro de conexão. Verifique sua internet';
  static const String errorNotFound = 'Fornecedor não encontrado';
  static const String errorInvalidCnpj = 'CNPJ inválido';
  static const String errorNameRequired = 'Nome é obrigatório';
  static const String errorCnpjRequired = 'CNPJ é obrigatório';
  static const String errorCnpjAlreadyExists = 'CNPJ já cadastrado';
  
  // Success messages
  static const String successCreate = 'Fornecedor criado com sucesso';
  static const String successUpdate = 'Fornecedor atualizado com sucesso';
  static const String successDelete = 'Fornecedor excluído com sucesso';
  static const String successStatusChange = 'Status alterado com sucesso';
  
  // Placeholders
  static const String hintSearchSuppliers = 'Buscar fornecedores por nome ou CNPJ...';
  static const String hintSupplierName = 'Digite o nome do fornecedor';
  static const String hintSupplierCnpj = 'Digite o CNPJ (apenas números)';
  
  // Labels
  static const String labelSupplierName = 'Nome do Fornecedor';
  static const String labelSupplierCnpj = 'CNPJ';
  static const String labelActive = 'Ativo';
  static const String labelInactive = 'Inativo';
  
  // Button texts
  static const String buttonCreate = 'Criar Fornecedor';
  static const String buttonUpdate = 'Atualizar Fornecedor';
  static const String buttonCancel = 'Cancelar';
  static const String buttonSave = 'Salvar';
  static const String buttonDelete = 'Excluir';
  static const String buttonEdit = 'Editar';
  
  // Tooltips
  static const String tooltipEdit = 'Editar fornecedor';
  static const String tooltipDelete = 'Excluir fornecedor';
  static const String tooltipToggleStatus = 'Alternar status';
  static const String tooltipExport = 'Exportar fornecedores';
  static const String tooltipRefresh = 'Atualizar lista';
  static const String tooltipClearSearch = 'Limpar busca';
  
  // Status badges
  static const String statusActive = 'Ativo';
  static const String statusInactive = 'Inativo';
}