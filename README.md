# ARCHITECTURE.md — Granith ERP
> Documento de contexto do projeto. Cole este arquivo no início de cada sessão para retomar sem reexplicar.
> Última atualização: migração do runtime para Supabase e definição das pendências finais do MVP.

---

## Visão geral

**Granith ERP** é um sistema de gestão voltado para empresas de construção/obras, desenvolvido em **Flutter** com backend **Supabase (Auth + Postgres + Storage)**. Objetivo: multiplataforma (web + mobile). Firebase permanece apenas para Hosting.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter (web + mobile) |
| Backend | Supabase Postgres/PostgREST + Realtime |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| State mgmt | ChangeNotifier + Provider (MVC atual) → MVVM futuro |
| Assinatura | SubscriptionController (multi-plano, guards pendentes) |
| Gráficos | fl_chart ^0.68.0 |
| IA | Google Gemini API (modelo configurável no app: Flash / Pro) |

---

## Pendências para fechar o MVP

Faltam três frentes principais para considerar o Granith ERP fechado como MVP. Ajustes finos e demandas do Granith Mobile ficam em backlog separado.

1. **Integração com IA nos módulos Financeiro, Obras e RH**
   - Financeiro: análise de DRE, alertas de custo, projeções, explicação de variações e apoio a decisões.
   - Obras: leitura de diários de obra, resumo de ocorrências, riscos, pendências e produtividade.
   - RH: apoio em triagem, histórico funcional, benefícios, alertas e leitura de documentos.

2. **Controle de veículos da empresa**
   - Cadastro de veículos, status, documentação, responsável, disponibilidade e vínculo com obras/equipes.
   - Controle de manutenção, custos, abastecimento, histórico de uso e alertas operacionais.

3. **Sincronização com Geofencing/sistema de ponto do Granith Mobile**
   - Receber registros de ponto do mobile com localização e referência da obra.
   - Validar entrada/saída por geofence.
   - Consolidar horas no ERP para RH, obras e custo de mão de obra.

---

## Estrutura de pastas (`lib/`)

```
lib/
├── constants/           # budget_type_constants, projects_constants, supplier_constants
├── controllers/         # 12 controllers (ChangeNotifier)
│   └── (futuro)         # hr_controller.dart, talent_controller.dart, ai_controller.dart
├── helpers/             # projects_helpers.dart
├── models/              # 19 modelos de domínio
│   └── (futuro)         # benefit_model.dart, talent_candidate_model.dart, salary_history_model.dart
├── screens/             # 17 telas
│   └── (futuro)         # hr_page.dart, talent_bank_page.dart, ai_assistant_page.dart
├── services/            # services de acesso ao Supabase
│   └── (futuro)         # benefit_service.dart, talent_service.dart, gemini_service.dart, storage_service.dart
├── themes/              # app_theme.dart
├── utils/               # seeder.dart
├── widgets/
│   ├── financial/
│   ├── hr/              # (futuro) employee_card.dart, benefit_chip.dart, salary_history_tile.dart
│   ├── inventory/
│   ├── navigation/      # sidebar_menu, mobile_drawer
│   ├── projects/
│   └── purchases/
└── main.dart
```

### Pendências de nomenclatura (corrigir na migração MVVM)
- `service_projetos.dart` → renomear para `project_service.dart`
- `service_orcamentos.dart` → renomear para `budget_service.dart`
- `FinancialPage.dart` (em `models/`) → mover para `screens/financial_page.dart`
- `InventoryMovementType.dart` → renomear para `inventory_movement_type.dart` (snake_case)

---

## Módulos e responsabilidades

### Projetos ⭐ (centro gravitacional)
- `project_model.dart`, `projects_controller.dart`, `service_projetos.dart`
- `project_details_page.dart` — tela de detalhes com 4 abas: Resumo, Financeiro, Diário, Equipe
- `project_card.dart` — barra de progresso **reativa** via `ProjectBudgetService` stream
- Badges automáticos: `isOverBudget` (vermelho), `isOverdue` (laranja)
- Status: `planning` → `inProgress` → `completed`

### Orçamentos
- `budget_model.dart`, `budget_type.dart`, `budget_type_controller.dart`
- `service_orcamentos.dart`, `budget_type_service.dart`
- Orçamento aprovado deve disparar criação de projeto (regra pendente)

### Financeiro ⭐ (alicerce — implementado)
- `financial_transaction_model.dart` — modelo completo com:
  - `TransactionType`: `income` | `expense`
  - `TransactionStatus`: `pending` | `paid` | `overdue` | `cancelled`
  - `TransactionOrigin`: `manual` | `purchase` | `laborCost` | `materialUsage` | `budget`
  - `TransactionCategory`: `material` | `labor` | `equipment` | `administrative` | `measurement` | `tax` | `other`
  - Campos: `dueDate`, `paymentDate`, `projectId`, `supplierId`, `referenceId`, `createdBy`
  - `isOverdue` getter computado, `copyWith()`, `markAsPaid()`
- `financial_service.dart` — streams por projeto/período/tipo/status/origem, `addTransactionsBatch()`, `getSumByCategory()`
- `financial_controller.dart` — stream real via Supabase, filtros client-side por projeto e período, `_syncOverdueStatus()`
- `financial_page.dart` — 6 cards de stat, filtros, lista com swipe (marcar pago / cancelar), tap abre edição
- `transaction_form_dialog.dart` — dialog unificado

**Regra crítica:** toda transação tem `projectId` + `origin` + `referenceId` para rastreabilidade bidirecional.

### Supply Chain — Compras ⭐ (ciclo fechado)
- `purchase_model.dart` — campos: `itemId`, `supplierId`, `projectId`, `quantity`, `totalValue`, `requisitionId`, `financialTransactionId`, `receivedBy`
- `purchase_service.dart` — `confirmDelivery()` fecha o ciclo completo:
  1. Compra → `delivered` + transação financeira criada
  2. `InventoryService.processPurchaseDelivery()` → entrada no estoque
  3. `ProjectBudgetService.syncProjectCurrentCost()` → atualiza `currentCost`

> Pendência técnica: esse fluxo já usa Supabase, mas ainda roda como chamadas sequenciais do cliente. Para integridade forte em produção, mover para RPC/Edge Function com transação SQL.
  

### Supply Chain — Estoque (implementado)
- `inventory_model.dart`, `inventory_service.dart`, `inventory_page.dart`
- `InventoryMovementType.dart` — tipos: `inbound`, `outbound`, `transfer`, `adjustment`

### Supply Chain — Requisições
- `requisition_model.dart`, `material_requisition_controller.dart`, `material_requisition_service.dart`
- **Fluxo de aprovação pendente:** nível gerência → CEO
- **TODO:** ao aprovar, verificar estoque — se tem: baixa; se não tem: gera pedido de compra

### Budget vs Realizado (implementado)
- `project_budget_service.dart` — `watchProjectBudget()`, `syncProjectCurrentCost()`, `ProjectBudgetSnapshot`
- `project_budget_summary.dart` — widget compacto e completo

### RH + Equipes ⭐ (expansão planejada)

#### Estado atual
- `employee_model.dart` — campos básicos (nome, cargo, equipe)
- `team_model.dart`, `job_role_model.dart`
- `job_role_model` contém `hourlyRate` para cálculo futuro de custo de M.O.
- **Regra corrigida:** cargos NÃO têm salário fixo — o salário pertence ao funcionário

#### Expansão do `employee_model.dart`
Campos a adicionar:
```dart
// Dados pessoais / contratuais
String cpf
String ctps                  // número da carteira de trabalho
DateTime admissionDate
DateTime? dismissalDate

// Remuneração (salário no funcionário, não no cargo)
double baseSalary
List<SalaryHistory> salaryHistory  // histórico de reajustes

// Benefícios
List<String> benefitIds      // referências para benefit_model
```

#### Novo: `salary_history_model.dart`
```dart
String id
String employeeId
double previousSalary
double newSalary
DateTime effectiveDate
String reason                // "reajuste anual", "promoção", etc.
String updatedBy
```

#### Novo: `benefit_model.dart`
```dart
String id
String name                  // "Vale Transporte", "Vale Refeição", "Plano de Saúde"...
String type                  // 'vt' | 'vr' | 'health' | 'dental' | 'other'
String description
bool isActive
DateTime createdAt
```

#### Novo: `employee_benefit_model.dart`
Associação funcionário ↔ benefício com valor e histórico:
```dart
String id
String employeeId
String benefitId
double monthlyValue
DateTime startDate
DateTime? endDate
List<BenefitHistoryEntry> history   // log de alterações de valor
bool isActive
```

#### Novos services
- `benefit_service.dart` — CRUD de tipos de benefício + associações por funcionário
- `hr_service.dart` — CRUD expandido de funcionários com salário e documentos

#### Novas telas / widgets
- `hr_page.dart` — substitui `employee_registration_page.dart`, com abas:
  - **Funcionários** — lista com card expandido (salário, docs, benefícios)
  - **Benefícios** — cadastro e gestão de tipos de benefício
  - **Cargos** — mantém `job_role_model` com `hourlyRate`, sem salário fixo
- `widgets/hr/employee_card.dart`
- `widgets/hr/benefit_chip.dart`
- `widgets/hr/salary_history_tile.dart`

### Banco de Talentos ⭐ (novo módulo)

#### `talent_candidate_model.dart`
```dart
String id
String name
String email
String phone
String targetRole            // cargo pretendido
String area                  // 'obras' | 'administrativo' | 'ti' | 'financeiro' | 'rh' | 'other'
String status                // 'pending' | 'reviewing' | 'approved' | 'rejected'
String resumeStoragePath     // path no Supabase Storage (ex: 'resumes/{id}.pdf')
String resumeDownloadUrl     // URL pública ou signed URL
String? notes                // anotações manuais do recrutador
DateTime uploadedAt
String uploadedBy
Map<String, dynamic>? aiAnalysis   // resultado da triagem IA (preenchido depois)
```

#### `talent_service.dart`
- `uploadResume(File pdfFile, String candidateId)` → Supabase Storage → retorna `downloadUrl`
- `addCandidate(TalentCandidate candidate)` → Supabase
- `updateStatus(String id, String status)`
- `getCandidatesStream({String? area, String? status})` — filtros combinados
- `deleteCandidate(String id)` → remove registro no Supabase + arquivo no Storage

#### `storage_service.dart`
- Abstração sobre Supabase Storage
- `uploadPdf(String path, Uint8List bytes)` → `String downloadUrl`
- `deleteFile(String path)`
- Configuração: bucket privado ou publico conforme a regra de acesso do modulo

#### `talent_bank_page.dart`
- Filtros por área e status
- Card do candidato com chip de status colorido, botão de download do PDF
- FAB para adicionar novo candidato (abre bottom sheet com upload de PDF)
- Futuramente: botão "Analisar com IA" por candidato

---

### IA — Estratégia Gemini ⭐ (planejado)

#### Visão geral
O Granith ERP usará o **Google Gemini** como motor de IA para assistência em múltiplas áreas. A escolha do Gemini é deliberada: custo menor por token (Flash) e perfil generalista que serve bem como assistente utilitário transversal — diferente de modelos especializados em código.

#### Modelo configurável
- Padrão: `gemini-1.5-flash` (custo/velocidade)
- Opcional: `gemini-1.5-pro` (tarefas complexas)
- Configuração salva no Supabase por empresa (`company_settings/ai_config`)

```dart
// ai_config_model.dart
String defaultModel          // 'gemini-1.5-flash' | 'gemini-1.5-pro'
bool aiEnabled
Map<String, bool> featuresEnabled  // por área: {'hr': true, 'financial': false, ...}
```

#### `gemini_service.dart`
```dart
Future<String> prompt({
  required String userMessage,
  required String systemPrompt,   // prompt de sistema da área
  String? model,                  // override do modelo padrão
  List<String>? context,          // contexto adicional (dados do candidato, etc.)
})
```

#### Engenharia de prompt por área
Cada área tem seu próprio `systemPrompt` especializado, buscando respostas baseadas em fontes oficiais (CLT, NRs, etc.):

| Área | Especialização do prompt |
|------|--------------------------|
| **RH — Triagem** | Analista de RH sênior especializado em construção civil. Avalia currículos contra requisitos da vaga. Referência: CBO, convenções coletivas do setor. |
| **RH — Benefícios** | Consultor de RH. Sugere benefícios competitivos com base no cargo, região e mercado de construção civil. Referência: CAGED, pesquisas salariais do setor. |
| **Obras** | Engenheiro civil / mestre de obras. Suporte técnico a dúvidas de execução, normas e segurança. Referência: ABNT NBR, NR-18. |
| **Financeiro** | Controller financeiro. Auxilia análise de DRE, fluxo de caixa e indicadores. Referência: CPC, legislação tributária vigente. |
| **Administrativo** | Assistente administrativo generalista para o setor de construção. |

#### Casos de uso — fase 1
1. **Triagem automática de currículos** — usuário clica "Analisar com IA" no `TalentBankPage`, o PDF é lido (texto extraído client-side ou via Cloud Function), enviado ao Gemini com prompt de RH, resultado salvo em `candidate.aiAnalysis`
2. **Sugestão de benefícios** — ao cadastrar/editar funcionário, botão "Sugerir benefícios" envia cargo + salário ao Gemini com prompt de benefícios
3. **Assistente por área** — `ai_assistant_page.dart` ou bottom sheet flutuante, com contexto da área ativa

#### Fluxo de triagem de currículo
```
PDF no Storage
      ↓
Extrair texto (flutter_pdfview / cloud function)
      ↓
gemini_service.prompt(
  systemPrompt: hrTriagemPrompt,
  userMessage: "Analise este currículo para a vaga de {cargo}: {texto_curriculo}",
  context: [vagaDescricao]
)
      ↓
Retorno: score, pontos fortes, pontos fracos, recomendação
      ↓
Salvar em candidate.aiAnalysis (Supabase)
```

#### Dependências a adicionar (`pubspec.yaml`)
```yaml
google_generative_ai: ^0.4.0    # SDK oficial Gemini
supabase_flutter: ^2.12.0       # Auth, banco e Storage
file_picker: ^8.0.0             # seleção de PDF no device
```

---

### Diário de Obra
- `diario_obra_model.dart` — campos: `projectId`, `date`, `weatherMorning/Afternoon`, `manpower`, `activitiesDescription`, `impediments`, `photoUrls`
- **Evolução planejada:** horas por funcionário → custo M.O. automático no financeiro

### Relatórios ⭐ (redesenhado)
- `reports_page.dart` — visual dark-premium, classe `ReportsPage`
- 4 gráficos fl_chart: `_BarChartCard`, `_GaugeCard`, `_DonutCard`, `_LineChartCard`
- Responsivo desktop/mobile, `RefreshIndicator`
- Dados mensais ainda mockados — **TODO:** conectar com `financial_service.getSumByCategory()`

---

## Mapa de dependências

```
Orçamento aprovado ──────────────────────▶ Projeto (pendente)
                                               │
                     ┌─────────────────────────┼──────────────────┐
                     ▼                         ▼                   ▼
                Financeiro              Diário de Obra          Estoque
                     ▲                                              ▲
Requisição ──────────┼────────────────▶ Compra ─────────────────────┘
                     │                    │
                     └────────────────────┘
                        despesa automática

Funcionários ◀──── RH (salário, benefícios, docs)
Banco de Talentos ──▶ IA Gemini (triagem, sugestões)
Todos os módulos ────▶ Assistente IA por área
Todos ───────────────▶ Relatórios
```

---

## Regras de negócio

| # | Módulo | Regra | Status |
|---|--------|-------|--------|
| 1 | Financeiro | Toda transação tem `projectId` + `origin` + `referenceId` | ✅ |
| 2 | Financeiro | `dueDate` separado de `paymentDate` | ✅ |
| 3 | Financeiro | `_syncOverdueStatus()` marca vencidos no client | ✅ |
| 4 | Compras | `confirmDelivery` gera despesa no Supabase | ✅ |
| 5 | Compras | `confirmDelivery` dá entrada no estoque com `purchase.quantity` | ✅ |
| 6 | Compras | `cancelPurchase` cancela transação financeira vinculada | ✅ |
| 7 | Compras | Status `delivered`/`cancelled` só por ação dedicada | ✅ |
| 8 | Estoque | Entrada automática ao confirmar entrega | ✅ |
| 9 | Estoque | Validação de saldo antes de saída manual | ✅ |
| 10 | Budget | `ProjectBudgetSnapshot` calcula realizado vs previsto em tempo real | ✅ |
| 11 | Budget | `syncProjectCurrentCost` atualiza `project.currentCost` automaticamente | ✅ |
| 12 | Relatórios | Visual dark-premium com sidebar, stat cards e 4 gráficos fl_chart | ✅ |
| 13 | RH | Salário fixo pertence ao **funcionário**, não ao cargo | ✅ (refatorar) |
| 14 | RH | Cargo contém apenas `hourlyRate` para cálculo de M.O. em obras | ✅ (validar) |
| 15 | RH | Histórico de reajustes salariais imutável (append-only) | ✅ |
| 16 | RH | Benefícios têm histórico de valor por funcionário | ✅ |
| 17 | Talentos | PDF do currículo salvo no Supabase Storage, path referenciado no Postgres | 🔲 |
| 18 | Talentos | Análise IA salva em `candidate.aiAnalysis` (não reprocessa se já existir) | 🔲 |
| 19 | IA | Cada área usa systemPrompt próprio com referências oficiais (CLT, ABNT, etc.) | 🔲 |
| 20 | IA | Modelo Gemini configurável por empresa no Supabase | 🔲 | Será feito Depois
| 21 | Orçamentos | Orçamento aprovado cria projeto automaticamente | ✅ |
| 22 | Requisições | Fluxo de aprovação: gerência → CEO | ✅ |
| 23 | Requisições | Se item em estoque → baixa; se não → gera compra | ✅ |
| 24 | Relatórios | DRE real a partir das transações do Supabase | ✅ |
| 25 | Diário de Obra | Horas × valor/hora = custo M.O. no financeiro | 🔲 futuro |
| 26 | Custos | Calculo de Consumo real integrado com as leituras de Banco + Consumo de API´s. | ✅ |

---

## Providers registrados (`main.dart`)

```dart
MultiProvider(providers: [
  ChangeNotifierProvider(create: (_) => AuthController()),
  ChangeNotifierProvider(create: (_) => LoginController()),
  ChangeNotifierProvider(create: (_) => SubscriptionController()),
  ChangeNotifierProvider(create: (_) => DailyLogController()),
  ChangeNotifierProvider(create: (_) => ProjectsController(ServiceProjetos())),
  ChangeNotifierProvider(create: (_) => HomeController()),
  ChangeNotifierProvider(create: (_) => FinancialController()..init()),
  ChangeNotifierProvider(create: (_) => TeamController()),
  ChangeNotifierProvider(create: (_) => JobRoleController()),
  ChangeNotifierProvider(create: (_) => ReportsController()),
  ChangeNotifierProvider(create: (_) => MaterialRequisitionController()),
  // A adicionar:
  // ChangeNotifierProvider(create: (_) => HrController()),
  // ChangeNotifierProvider(create: (_) => TalentController()),
  // ChangeNotifierProvider(create: (_) => AiController()),
])
```

---

## Índices de navegação (`main_layout.dart`)

| Índice | Tela |
|--------|------|
| 0 | HomePage |
| 1 | ProjectsPage |
| 2 | DailyLogsPage |
| 3 | MaterialRequisitionPage |
| 4 | HrPage (substituirá EmployeeRegistrationPage) |
| 5 | JobRoleRegistrationPage |
| 6 | TeamPage |
| 7 | BudgetsPage |
| 8 | BudgetTypesPage |
| 9 | SuppliersPage |
| 10 | ItemsPage |
| 11 | PurchasesPage |
| 12 | InventoryPage |
| 13 | FinancialPage |
| 14 | ReportsPage (dark-premium + fl_chart) |
| 15 | TalentBankPage (novo) |
| 16 | Configurações (placeholder) |

---

## Dependências (`pubspec.yaml`)

```yaml
dependencies:
  fl_chart: ^0.68.0                # gráficos DRE
  google_generative_ai: ^0.4.0    # SDK Gemini
  supabase_flutter: ^2.12.0       # Auth, banco e Storage
  file_picker: ^8.0.0             # seleção de PDF no device
```

---

## Próximos passos (ordem recomendada)

1. **IA — base comum** criar serviço de IA com modelo configurável, prompts por área, logs de uso e controle de permissões.
2. **IA — Financeiro** conectar análise de DRE, custos, projeções e alertas às transações reais.
3. **IA — Obras** gerar resumos, riscos e pendências a partir de diários, medições, compras, estoque e equipe.
4. **IA — RH** apoiar triagem, histórico funcional, benefícios, alertas e leitura de documentos.
5. **Veículos — módulo operacional** criar cadastro, status, documentação, manutenção, custos e vínculo com obras/equipes.
6. **Granith Mobile — ponto/geofencing** sincronizar batidas, validar geofence por obra e consolidar horas no ERP.
7. **RH — refatorar `employee_model`** adicionar `baseSalary`, `salaryHistory`, `cpf`, `ctps`, `admissionDate`.
8. **RH — `benefit_model` + `benefit_service`** CRUD de tipos e associações por funcionário.
9. **Talentos — `talent_candidate_model` + `storage_service`** upload de PDF + Supabase.
10. **Migração MVVM** separar ViewModels, preparar para web + mobile.

---

## Migração MVC → MVVM + Clean Architecture (prioridade)

Objetivo: manter o código funcionando enquanto gradualmente refatora em camadas, com baixo risco, sem grandes rewrites de uma vez.

Passo 1 - Camadas e responsabilidades
- `presentation`: telas (`screens/`), widgets (`widgets/`), view models (`viewmodels/` ou `controllers/` evoluído).
- `domain`: entidades de negócio (`models/`), casos de uso (`usecases/`), interfaces de repositórios.
- `data`: implementações de repositório (`services/`), fontes de dados Supabase, Local, API.

Passo 2 - Regras de conversão de componentes
- Transformar os `Controller` atuais em `ViewModel` que expõem `ValueNotifier`, `ChangeNotifier` ou `Stream`.
- Não fazer acesso direto a backend no `screens`: mover para `services` + `usecases`.
- Cada página deve ter um único ponto de entrada MVVM (por exemplo `HomeViewModel`).

Passo 3 - Estrutura de arquivos proposta
```
lib/
 ├── data/
 │   ├── datasources/
 │   │   ├── local/
 │   │   └── remote/
 │   ├── repositories/
 │   └── models/   (DTOs de Supabase)
 ├── domain/
 │   ├── entities/
 │   ├── repositories/
 │   └── usecases/
 ├── presentation/
 │   ├── pages/
 │   ├── widgets/
 │   ├── viewmodels/
 │   └── routes.dart
 ├── services/     (injeções, supabase_service.dart, auth_service.dart)
 ├── themes/
 ├── utils/
 └── main.dart
```

Passo 4 - Páginas a quebrar primeiro (monolito → componentes)
- `home_page.dart`: separar `HomeHeader`, `StatCards`, `TransparencyBanner`, `RecentActivity`, `QuickActions` e `StatusChip`.
- `main_layout.dart`: dividir em `NavigationShell`, `ResponsiveBody`, `PageRouter`.
- `reports_page.dart`: extrair cada gráfico em `widgets/reports/`.
- `FinancialPage.dart`: extrair `FinancialHeader`, `FinancialStats`, `TransactionTab`, `TransactionList` e `TransactionItem`.
- `material_requisition_widgets.dart`: isolar cards e filas de requisição.

Passo 5 - Reutilização de widgets e identidade visual
- Criar componentes de design system em `widgets/common/`:
  - `AppCard`, `AppButton`, `AppTextField`, `SectionTitle`, `DataTableCard`, `EmptyStateTile`, `StatusBadge`.
- Usar tokens de cores/fontes em `themes/app_theme.dart` e `constants/ui_tokens.dart`.
- Garantir todos os widgets `const` onde possível.

Passo 6 - Clean Arch na prática
- Implementar `UseCase` para operações: `GetProjects`, `AddTransaction`, `ApproveRequisition`, `GetDashboardOverview`.
- Use `Repository` em `domain/repositories` e `impl` em `data/repositories`.
- Injetar dependências com `Provider` ou `get_it` se desejar.

Passo 7 - Rotas e navegação
- Centralizar rotas em `presentation/routes.dart` com `RouteSettings` e `onGenerateRoute`.
- Manter fallback para `MainLayout` e evitar rota hardcoded em widgets.

Passo 8 - QA de migração incremental
1. Atualiza a `home_page.dart` para usar `HomeViewModel`, mantendo layout igual.
2. Testa fluxo manual com app rodando (desktop e mobile). 3. Repetir por módulo.

---

## Planejamento detalhado página por página

### home_page.dart
- Criar `HomeViewModel` com estado: `stats`, `recentActivity`, `quickActions`.
- Extrair widgets:
  - `home_page/home_header.dart`
  - `home_page/stats_grid.dart`
  - `home_page/transparency_banner.dart`
  - `home_page/recent_activity_list.dart`
  - `home_page/quick_actions_grid.dart`
- Substituir navegação por constantes em `routes.dart`.

### main_layout.dart
- Criar `MainLayoutViewModel` com `selectedIndex` e `pageList`.
- Extrair:
  - `navigation/sidebar_menu.dart` (já existente)
  - `navigation/mobile_drawer.dart` (já existente)
  - `layout/page_router.dart`.
- Remover valores mágicos, usar enum `AppPage`.

### reports_page.dart
- Criar `ReportsViewModel` para dados de gráficos e filtros.
- Dividir em widgets:
  - `reports/bar_chart_card.dart`
  - `reports/gauge_card.dart`
  - `reports/donut_card.dart`
  - `reports/line_chart_card.dart`
- Implementar use case `GetReportData`.

### FinancialPage.dart
- Criar `FinancialViewModel` com transação completa e tabs.
- Mover `TransactionList` e `TransactionListItem` para `widgets/financial/` (já existente).
- Usar `FinancialFilterBar` + `FinancialStatCard` no novo widget de apresentação.

### projects_page.dart / ProjectDetailsPage.dart
- `ProjectsViewModel`: lista, filtro, seleção.
- `ProjectDetailsViewModel`: abas (Resumo/Financeiro/Diário/Equipe).
- Reusar `widgets/projects/*` e adaptar para receber interface do ViewModel.

### material_requisition_page.dart
- Criar `MaterialRequisitionViewModel`.
- Organizar UI em `widgets/material_requisition/*` (cards, lista, diálogo).

### HrPage.dart / employee_registration_page.dart / job_role_registration_page.dart / team_page.dart
- `HrViewModel` central.
- Internamente, abas ou separação em módulos `hr/employees`, `hr/job_roles`, `hr/teams`.
- Criar `widgets/hr/employee_card.dart`, `widgets/hr/job_role_card.dart`, `widgets/hr/team_card.dart`.

### budget_types_page.dart / budgets_page.dart
- `BudgetViewModel`, `BudgetTypeViewModel`.
- Reusar widgets de `budget_type/*` e `budgets/*`.

### suppliers_page.dart / purchases_page.dart / inventory_page.dart / items_page.dart
- `SupplyChainViewModel` ou específicos: `SupplierViewModel`, `PurchaseViewModel`, `InventoryViewModel`, `ItemViewModel`.
- Separar formulários de cadastro em `widgets/supplier/*`, `widgets/purchases/*`, etc.

### login_page.dart / subscription_page.dart
- `LoginViewModel`, `SubscriptionViewModel`.
- Widget forms em `widgets/login` e `widgets/subscription`.

### dailyLogsPage.dart / daily_log_details_page.dart
- `DailyLogViewModel` + dialogs.
- Componentizar em `widgets/daily_log/`.

### Page nomeada adicional
- `ProjectDetailsPage`, `HrPage`, etc devem ter viewmodels próprios.

---

## Atualizar README para documentação da mudança
Adicionar esses itens a este README para registrar e acompanhar:
- Status de cada módulo (planejado/em andamento/concluído).
- Lista de páginas a refatorar e widget library em items de check-list.
- Convenção de nomes (snake_case para arquivos, PascalCase para classes, viewmodels com sufixo `ViewModel`).
- Critérios de aceitação do Clean Arch: camada presentation sem dependência direta em data;
  domain independente do Flutter.

---

## Como usar este documento

Cole este arquivo no início de cada nova sessão e diga qual item dos **Próximos passos** quer trabalhar. O assistente terá contexto completo sem precisar reexplicar a estrutura do projeto.
