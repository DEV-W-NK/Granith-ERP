# Modelo de Dados - Granith ERP

Este levantamento usa como fonte principal `supabase_schema.sql` e considera o estado atual do app em Flutter. A fonte de verdade e o Supabase. O app nao usa mais Firestore para dados operacionais; Firebase permanece apenas para Hosting.

## Contexto de Dados

| Modulo | Entidades principais | Backend lido hoje |
| --- | --- | --- |
| Acesso e portal | `users`, `client_accounts`, `system_settings` | Supabase |
| Comercial | `budget_types`, `budgets`, `projects`, `project_measurements` | Supabase |
| Obras | `projects`, `daily_logs`, `teams`, `employees` | Supabase |
| Suprimentos | `items`, `suppliers`, `purchases`, `inventory`, `inventory_movements`, `material_requisitions` | Supabase |
| RH | `employees`, `job_roles`, `benefits`, `employee_benefits`, `salary_history`, `talent_candidates` | Supabase |
| Financeiro | `financial_transactions`, `project_measurements`, `usage_stats` | Supabase |

## MER Conceitual

```mermaid
flowchart LR
  CLIENTE["Cliente / Conta"] --> PORTAL["Portal do Cliente"]
  CLIENTE --> PROJETO["Projetos / Obras"]
  CLIENTE --> ORCAMENTO["Orcamentos"]

  ORCAMENTO --> PROJETO
  PROJETO --> MEDICAO["Medicoes"]
  MEDICAO --> FINANCEIRO["Financeiro"]

  PROJETO --> DIARIO["Diario de Obra"]
  PROJETO --> EQUIPE["Equipes"]
  RH["RH / Funcionarios"] --> EQUIPE
  RH --> BENEFICIOS["Beneficios e Salarios"]
  RH --> TALENTOS["Banco de Talentos"]

  PROJETO --> REQUISICAO["Requisicoes de Material"]
  REQUISICAO --> COMPRA["Compras"]
  FORNECEDOR["Fornecedores"] --> COMPRA
  ITEM["Catalogo de Itens"] --> COMPRA
  COMPRA --> ESTOQUE["Estoque"]
  ESTOQUE --> MOVIMENTO["Movimentacoes"]
  MOVIMENTO --> PROJETO

  COMPRA --> FINANCEIRO
  PROJETO --> FINANCEIRO
  FINANCEIRO --> RELATORIOS["Relatorios / DRE"]
  USO["Uso do Sistema"] --> RELATORIOS
```

## DER Mermaid

```mermaid
erDiagram
  CLIENT_ACCOUNTS ||--o{ USERS : "vincula perfil cliente"
  CLIENT_ACCOUNTS ||--o{ PROJECTS : "possui"
  CLIENT_ACCOUNTS ||--o{ BUDGETS : "recebe propostas"
  BUDGET_TYPES ||--o{ BUDGETS : "classifica"
  PROJECTS ||--o{ BUDGETS : "origina/aprova"
  PROJECTS ||--o{ PROJECT_MEASUREMENTS : "mede contrato"
  JOB_ROLES ||--o{ EMPLOYEES : "define cargo"
  JOB_ROLES ||--o{ TALENT_CANDIDATES : "vaga pretendida"
  EMPLOYEES ||--o{ TEAMS : "lidera"
  PROJECTS ||--o{ TEAMS : "aloca"
  SUPPLIERS ||--o{ PURCHASES : "fornece"
  ITEMS ||..o{ PURCHASES : "item logico"
  PROJECTS ||--o{ PURCHASES : "consome"
  PURCHASES ||--o{ INVENTORY : "ultima entrada"
  INVENTORY ||--o{ INVENTORY_MOVEMENTS : "movimenta"
  PROJECTS ||--o{ INVENTORY_MOVEMENTS : "baixa/transferencia"
  PURCHASES ||--o{ INVENTORY_MOVEMENTS : "entrada"
  PROJECTS ||--o{ MATERIAL_REQUISITIONS : "solicita"
  PURCHASES ||--o{ MATERIAL_REQUISITIONS : "atende"
  PROJECTS ||--o{ DAILY_LOGS : "registra"
  PROJECTS ||--o{ FINANCIAL_TRANSACTIONS : "gera"
  SUPPLIERS ||--o{ FINANCIAL_TRANSACTIONS : "cobra"
  EMPLOYEES ||--o{ EMPLOYEE_BENEFITS : "recebe"
  BENEFITS ||--o{ EMPLOYEE_BENEFITS : "define"
  EMPLOYEES ||--o{ SALARY_HISTORY : "historico"

  USERS {
    string id PK
    string email UK
    string displayName
    string status
    string_array permissions
    string role
    string clientAccountId
    string clientAccountName
    timestamptz lastLogin
    timestamptz created_at
    timestamptz updated_at
  }

  CLIENT_ACCOUNTS {
    string id PK
    string name
    string ownerEmail UK
    string contactEmail
    string contactPhone
    string status
    string portalAccessStatus
    string portalAuthUserId
    timestamptz portalInvitedAt
    timestamptz portalLastAccessAt
    string notes
  }

  SYSTEM_SETTINGS {
    string id PK
    string workspace_name
    string support_email
    string support_phone
    bool client_portal_show_budgets
    bool client_portal_show_budget_values
    bool client_portal_show_current_costs
    timestamptz updated_at
  }

  BUDGET_TYPES {
    string id PK
    string name UK
    string description
    string category
    bool isActive
    string iconName
    string color
  }

  JOB_ROLES {
    string id PK
    string title UK
    string sector
    string description
    numeric hourlyRate
    string_array requirements
    bool isActive
  }

  ITEMS {
    string id PK
    string name UK
    string description
    string unit
    numeric weight
    numeric width
    numeric height
    numeric length
  }

  PROJECTS {
    string id PK
    string name
    string client
    string description
    string status
    timestamptz startDate
    timestamptz endDate
    numeric budget
    numeric currentCost
    string location
    string_array tags
    int teamSize
    string projectKey UK
    string clientAccountId FK
    numeric estimatedProgress
    numeric measuredAmount
    int measurementCount
    timestamptz lastMeasurementAt
  }

  PROJECT_MEASUREMENTS {
    string id PK
    string projectId FK
    string projectName
    string projectClient
    string title
    int sequence
    string status
    timestamptz measurementDate
    numeric grossAmount
    numeric discountAmount
    numeric netAmount
    numeric accumulatedGrossAmount
    numeric measurementPercentage
    numeric accumulatedPercentage
    numeric contractBalance
    string createdBy
  }

  BUDGETS {
    string id PK
    string clientName
    string projectName
    numeric totalValue
    bigint creationDate
    bigint expirationDate
    int status
    jsonb items
    string projectId FK
    string budgetTypeId FK
    string clientAccountId FK
  }

  EMPLOYEES {
    string id PK
    string name
    string email UK
    string phone
    string jobTitle
    string jobRoleId FK
    string sector
    string role
    string status
    timestamptz admissionDate
    timestamptz dismissalDate
    string cpf UK
    string ctps
    numeric baseSalary
    string educationLevel
  }

  TEAMS {
    string id PK
    string name UK
    string description
    string_array memberIds
    string leaderId FK
    string projectId FK
    bool isActive
  }

  SUPPLIERS {
    string id PK
    string name
    string cnpj UK
    bool isActive
  }

  PURCHASES {
    string id PK
    string itemId
    string itemName
    string supplierId FK
    string supplierName
    string projectId FK
    string projectName
    string requisitionId
    string financialTransactionId
    numeric quantity
    numeric totalValue
    int status
    timestamptz purchaseDate
    timestamptz deliveryDate
  }

  INVENTORY {
    string id PK
    string name
    string name_normalized UK
    string unit
    numeric quantity
    numeric minQuantity
    string lastPurchaseId FK
    timestamptz lastEntryDate
  }

  INVENTORY_MOVEMENTS {
    string id PK
    string itemId FK
    string itemName
    numeric quantity
    string type
    string projectId FK
    string projectName
    string purchaseId FK
    string referenceId
    timestamptz date
    string userId
  }

  MATERIAL_REQUISITIONS {
    string id PK
    string projectId FK
    string projectName
    string requesterName
    string requesterId
    timestamptz requestDate
    string status
    jsonb items
    string priority
    string approvedBy
    string purchaseId FK
  }

  DAILY_LOGS {
    string id PK
    string projectId FK
    string projectName
    timestamptz date
    string weatherMorning
    string weatherAfternoon
    jsonb manpower
    string activitiesDescription
    string impediments
    string_array photoUrls
    string createdByUserId
    string status
  }

  FINANCIAL_TRANSACTIONS {
    string id PK
    string description
    numeric amount
    string type
    string status
    string origin
    string category
    timestamptz dueDate
    timestamptz paymentDate
    string projectId FK
    string supplierId FK
    string referenceId
    string createdBy
  }

  BENEFITS {
    string id PK
    string name UK
    string type
    string description
    bool isActive
  }

  EMPLOYEE_BENEFITS {
    string id PK
    string employeeId FK
    string benefitId FK
    string benefitName
    numeric monthlyValue
    timestamptz startDate
    timestamptz endDate
    bool isActive
    jsonb history
  }

  SALARY_HISTORY {
    string id PK
    string employeeId FK
    numeric previousSalary
    numeric newSalary
    timestamptz effectiveDate
    string reason
    string updatedBy
  }

  USAGE_STATS {
    string id PK
    string tenantId
    int totalReads
    int totalWrites
    string projectRef
    int totalApiRequests
    numeric databaseUsedMB
    numeric storageUsedMB
    jsonb dailyOperations
    timestamptz periodStart
    timestamptz periodEnd
  }

  TALENT_CANDIDATES {
    string id PK
    string name
    string email
    string phone
    string status
    string jobRoleId FK
    string notes
  }
```

## Regras de Integridade Relevantes

- `projects.status`: `planning`, `inProgress`, `completed`.
- `budgets.status`: inteiro `0..3` (`pending`, `approved`, `rejected`, `expired`).
- `purchases.status`: inteiro `0..4` (`awaitingApproval`, `pending`, `ordered`, `delivered`, `cancelled`).
- `material_requisitions.status`: `pending`, `approved`, `rejected`, `purchased`, `delivered`.
- `financial_transactions`: toda movimentacao deve ter `type`, `origin`, `category`, `dueDate` e, quando aplicavel, `projectId`, `supplierId` e `referenceId`.
- `project_measurements` recalcula progresso medido, saldo contratual e acumulados do projeto.
- `employee_benefits` e `salary_history` preservam historico operacional de RH; reajustes devem ser append-only.

## Observacoes Para Migracao

- `suppliers`, `purchases`, `inventory`, `inventory_movements`, `material_requisitions`, `daily_logs`, `financial_transactions`, `benefits`, `employee_benefits` e `salary_history` sao lidos e gravados pelo app via Supabase.
- O seeder atualizado popula apenas o Supabase.
- `auth.users` do Supabase nao e criado pelo seeder do app. O seeder cria registros em `public.users` para gestao de acesso, mas contas reais de login continuam dependendo do Supabase Auth.
