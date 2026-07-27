# Fluxo completo do ecossistema Granith

> Estado atual validado em 27/07/2026 nos projetos Granith ERP, Granith Mobile
> e nas migrations do Supabase. Este documento descreve o que o código faz
> hoje, e não apenas a arquitetura desejada.

## Como ler este documento

- **ERP Web:** cadastro, planejamento, aprovação, auditoria e gestão.
- **Mobile:** operação de campo, execução de rotas, ponto, evidências e trabalho
  offline.
- **Supabase:** fonte de verdade compartilhada, autenticação, RLS, Realtime,
  Storage e Edge Functions.
- **SQLite:** memória operacional do aparelho e filas para sincronização.
- **Firebase:** Hosting do ERP e entrega de notificações FCM ao Mobile.
- Uma seta contínua representa uma gravação ou dependência direta.
- Uma seta tracejada representa leitura, análise ou atualização derivada.

## 1. Mapa mestre

```mermaid
flowchart TB
  subgraph Pessoas["Pessoas e perfis"]
    ADM["Administrador"]
    GES["Gerente"]
    COO["Coordenador"]
    SUP["Supervisor"]
    FUN["Funcionário"]
    MOT["Motorista"]
    CLI["Cliente"]
  end

  subgraph Web["Granith ERP Web"]
    LOGIN_WEB["Login Google, e-mail ou usuário interno"]
    ERP_OP["Operacional<br/>Projetos, medições, diários, requisições e tarefas"]
    ERP_RH["RH<br/>Funcionários, cargos, equipes e benefícios"]
    ERP_COM["Comercial<br/>Orçamentos e tipos"]
    ERP_SUP["Suprimentos<br/>Itens, fornecedores, compras, rotas e estoque"]
    ERP_FIN["Financeiro<br/>Entradas, saídas, compras a pagar, ponto, DRE e resultado"]
    ERP_ADM["Administrativo<br/>Acessos, frota, cercas e configurações"]
    ERP_IA["IAs especializadas por módulo"]
    PORTAL["Portal do cliente"]
  end

  subgraph App["Granith Mobile Android"]
    LOGIN_APP["Login Google ou usuário interno"]
    APP_HOME["Workspace do funcionário"]
    APP_FIELD["Obras, tarefas, materiais, diário e medições"]
    APP_TIME["Ponto e geofence"]
    APP_ROUTE["Rotas, GPS, checkpoints e comprovantes"]
    APP_STOCK["Estoque, veículo e combustível"]
    APP_INFO["Equipe, benefícios, documentos e relatórios próprios"]
    APP_IA["Assistente local com flutter_gemma"]
    SQLITE["SQLite<br/>cache, documentos, notificações e outboxes"]
  end

  subgraph Backend["Supabase"]
    AUTH["Auth"]
    API["PostgREST e RPC"]
    DB[("PostgreSQL")]
    RLS["RLS, triggers e funções privadas"]
    REALTIME["Realtime"]
    STORAGE["Storage de imagens e evidências"]
    EDGE["Edge Functions"]
    PUSH_QUEUE[("mobile_push_notifications")]
  end

  subgraph Externos["Serviços externos"]
    MAPS["Google Maps e Routes API"]
    GEMINI["Gemini API"]
    FCM["Firebase Cloud Messaging"]
    HOSTING["Firebase Hosting"]
    HF["Hugging Face<br/>download do modelo"]
  end

  ADM --> LOGIN_WEB
  GES --> LOGIN_WEB
  COO --> LOGIN_WEB
  SUP --> LOGIN_WEB
  CLI --> LOGIN_WEB
  FUN --> LOGIN_APP
  MOT --> LOGIN_APP
  SUP --> LOGIN_APP
  COO --> LOGIN_APP

  LOGIN_WEB --> AUTH
  LOGIN_APP --> AUTH
  AUTH --> RLS
  RLS --> API
  API --> DB

  ERP_OP --> API
  ERP_RH --> API
  ERP_COM --> API
  ERP_SUP --> API
  ERP_FIN --> API
  ERP_ADM --> API
  PORTAL --> API
  ERP_OP --> STORAGE

  APP_HOME --> SQLITE
  APP_FIELD --> SQLITE
  APP_TIME --> SQLITE
  APP_ROUTE --> SQLITE
  APP_STOCK --> SQLITE
  APP_INFO --> SQLITE
  SQLITE <--> API
  REALTIME -. atualiza .-> ERP_OP
  REALTIME -. atualiza .-> APP_HOME

  APP_ROUTE --> MAPS
  ERP_ADM --> MAPS
  ERP_IA --> EDGE
  EDGE --> GEMINI
  APP_IA --> HF
  APP_IA --> SQLITE

  DB --> PUSH_QUEUE
  PUSH_QUEUE --> EDGE
  EDGE --> FCM
  FCM --> APP_HOME
  FCM -. solicita sync .-> SQLITE

  HOSTING --> LOGIN_WEB
```

### Resumo operacional

1. O usuário autentica no Supabase.
2. O perfil em `users` define se ele entra no ERP, Mobile ou Portal do Cliente.
3. O vínculo com `employees`, o cargo hierárquico e as permissões liberam os
   módulos.
4. ERP e Mobile gravam na mesma base, mas com responsabilidades diferentes.
5. Triggers do banco criam notificações quando mudanças relevantes precisam
   chegar ao campo.
6. O FCM acorda o Mobile e informa quais caches devem ser sincronizados.
7. Sem rede, o Mobile opera sobre SQLite e mantém alterações em filas locais.
8. Na primeira conexão disponível, as filas são enviadas ao Supabase.

## 2. Camadas e dependências técnicas

```mermaid
flowchart LR
  subgraph ERP["ERP Web"]
    EUI["Screens e Widgets"]
    ESTATE["Controllers e ViewModels"]
    ESERVICE["Services"]
    EBUS["AppDataRefreshBus"]
    ESUPA["AppSupabase.client"]

    EUI --> ESTATE
    ESTATE --> ESERVICE
    ESERVICE --> ESUPA
    ESERVICE --> EBUS
    EBUS -. invalida e recarrega .-> ESTATE
  end

  subgraph MOBILE["Mobile"]
    MUI["Pages"]
    MPROVIDER["Riverpod Providers"]
    MREPO["Repositories"]
    MLOCAL["SQLite Databases"]
    MREMOTE["Supabase Client"]
    MOUTBOX["Outboxes"]

    MUI --> MPROVIDER
    MPROVIDER --> MREPO
    MREPO --> MLOCAL
    MREPO --> MREMOTE
    MLOCAL --> MOUTBOX
    MOUTBOX -. retry ao conectar .-> MREMOTE
  end

  ESUPA --> GATE["Auth, RLS e RPC"]
  MREMOTE --> GATE
  GATE --> PG[("PostgreSQL")]
  PG --> TRIGGER["Triggers de consistência e eventos"]
  TRIGGER --> PG
```

### O que “herda” o quê na arquitetura

| Origem | Herança/dependência | Efeito |
| --- | --- | --- |
| Tela do ERP | Controller/ViewModel e Service | A tela não deve acessar regra de banco diretamente. |
| Service do ERP | `AppSupabase.client` | Centraliza as operações remotas. |
| Escrita do ERP | `AppDataRefreshBus` | As listas relacionadas são recarregadas após salvar. |
| Tela Mobile | Provider e Repository | A interface recebe estado local/remoto pelo Riverpod. |
| Repository Mobile | SQLite + Supabase | Lê cache primeiro e sincroniza quando possível. |
| Qualquer escrita autenticada | RLS/RPC | O banco valida identidade, papel e permissão. |
| Mudança operacional relevante | Trigger de notificação | Uma linha é criada na fila de push. |

## 3. Identidade, vínculo e permissões

```mermaid
flowchart TB
  START["Abrir Granith"] --> METHOD{"Forma de login"}
  METHOD -->|Google| GOOGLE["OAuth Google"]
  METHOD -->|E-mail e senha| EMAIL["Supabase Auth"]
  METHOD -->|Usuário e senha| USERNAME["Converte para<br/>usuario@internal.granith.local"]

  GOOGLE --> AUTH["Sessão Supabase Auth"]
  EMAIL --> AUTH
  USERNAME --> AUTH
  AUTH --> PROFILE["Carregar public.users"]
  PROFILE --> ACTIVE{"Perfil ativo?"}
  ACTIVE -->|Não| BLOCK["Bloquear acesso"]
  ACTIVE -->|Sim| TYPE{"users.role"}

  TYPE -->|client| ACCOUNT["client_accounts"]
  ACCOUNT --> CLIENT_RLS["RLS limita conta, obras,<br/>orçamentos, medições e diários"]
  CLIENT_RLS --> CLIENT_PORTAL["Portal do Cliente"]

  TYPE -->|employee ou admin| LINK{"Vínculo com funcionário"}
  LINK -->|employee_id ou employeeId| EMP["employees.id"]
  LINK -->|fallback| EMP_EMAIL["employees.email = JWT email"]
  EMP_EMAIL --> EMP
  EMP --> ROLE["employees.role"]
  PROFILE --> PERMS["users.permissions"]
  TYPE --> ADMIN["Admin tem precedência"]
  ROLE --> ACCESS["Acesso por hierarquia"]
  PERMS --> ACCESS
  ADMIN --> ACCESS
  ACCESS --> ERP_MENU["Módulos do ERP"]
  ACCESS --> MOBILE_MENU["Módulos do Mobile"]
  ACCESS --> RLS["Políticas RLS"]
```

### Hierarquia efetiva do funcionário

| Nível | Papel persistido | Herda acesso do nível anterior | Capacidades Mobile principais |
| ---: | --- | --- | --- |
| 1 | `funcionario` | Base | Obras vinculadas, ponto, equipe, documentos, benefícios próprios, tarefas atribuídas e veículo quando permitido. |
| 2 | `supervisor` | Funcionário | Requisitar material, diário, equipe, medições, estoque e criação de tarefas sob sua supervisão. |
| 3 | `coordenador` | Supervisor | Hierarquia Mobile, horas externas, visão e gestão ampliadas, tarefas relacionadas. |
| 4 | `gerente` | Coordenador | Resumo executivo e visão gerencial. |
| 5 | `admin` em `users` | Todos | Bypass administrativo previsto pelas funções privadas e permissões globais. |

Permissões específicas podem liberar módulos como `manualWorkHours`,
`fuelLogsWrite`, `deliveryRoutesUse`, `inventoryOperate`,
`vehicleChecklistWrite`, `measurementsEvidenceWrite`,
`executiveBriefRead` e `offlineAssistantUse`, mesmo quando o setor ou cargo
normal não liberaria a função.

## 4. Dependência funcional entre módulos

```mermaid
flowchart TB
  ACCESS["Acessos e usuários"] --> EMP["Funcionários"]
  EMP --> JOB["Cargos e setores"]
  EMP --> TEAMS["Equipes"]
  EMP --> BENEFITS["Benefícios e salários"]
  EMP --> VEHICLES["Veículos"]
  EMP --> TASKS["Tarefas"]
  EMP --> ROUTES["Rotas"]
  EMP --> CLOCK["Ponto"]

  CLIENTS["Clientes"] --> BUDGETS["Orçamentos"]
  CLIENTS --> PROJECTS["Projetos e obras"]
  BUDGET_TYPES["Tipos de orçamento"] --> BUDGETS
  BUDGETS -->|aprovação cria| PROJECTS

  PROJECTS --> TEAMS
  PROJECTS --> GEOFENCE["Cerca da obra"]
  PROJECTS --> MEASUREMENTS["Medições"]
  PROJECTS --> DAILY["Diário de obra"]
  PROJECTS --> REQ["Requisições"]
  PROJECTS --> TASKS
  PROJECTS --> CLOCK
  PROJECTS --> FIN["Financeiro"]
  PROJECTS --> PORTAL["Portal do cliente"]

  ITEMS["Catálogo de itens"] --> REQ
  ITEMS --> STOCK["Estoque"]
  REQ --> QUOTES["Cotações de fornecedores"]
  SUPPLIERS["Fornecedores"] --> QUOTES
  QUOTES --> PURCHASES["Pedidos de compra"]
  SUPPLIERS --> PURCHASES
  PURCHASES --> PAYABLE["Compras a pagar"]
  PURCHASES --> ROUTES
  PURCHASES --> STOCK
  STOCK --> MOVEMENTS["Entradas, baixas e transferências"]
  MOVEMENTS --> PROJECTS

  MEASUREMENTS -. receita e progresso .-> FIN
  CLOCK -. horas e custo de mão de obra .-> FIN
  BENEFITS -. custo de pessoas .-> FIN
  PAYABLE --> FIN
  FIN --> DRE["DRE"]
  FIN --> RESULT["Resultado administrativo"]
  FIN --> REPORTS["Relatórios"]
```

## 5. Ciclo de vida de uma obra

```mermaid
flowchart TB
  START{"Origem da obra"}
  START -->|Cadastro manual| FORM["Formulário de projeto"]
  START -->|Proposta comercial| BUDGET["Orçamento pendente"]
  BUDGET --> DECISION{"Aprovar orçamento?"}
  DECISION -->|Não| REJECT["Orçamento rejeitado ou expirado"]
  DECISION -->|Sim| AUTO_PROJECT["Criar ou reutilizar projeto<br/>sourceBudgetId = budget.id"]
  FORM --> PROJECT["Projeto"]
  AUTO_PROJECT --> PROJECT

  PROJECT --> CLIENT["Conta do cliente"]
  PROJECT --> COORD["Coordenador"]
  PROJECT --> TEAM["Equipe e líder"]
  PROJECT --> GEO["Local e cerca"]
  PROJECT --> VALUE["Prazo, orçamento e status"]

  COORD --> NOTIFY["Push de atribuição e sync"]
  TEAM --> NOTIFY
  NOTIFY --> MOBILE["Workspace Mobile atualizado"]

  PROJECT --> EXEC{"Execução"}
  EXEC --> DAILY["Diários e assinatura do coordenador"]
  EXEC --> MEASURE["Medições, evidências e progresso"]
  EXEC --> MATERIAL["Requisições de materiais"]
  EXEC --> TASK["Tarefas e cronômetros"]
  EXEC --> TIME["Ponto e horas da equipe"]
  EXEC --> DOCS["Documentos offline"]

  DAILY --> PORTAL["Portal do cliente"]
  MEASURE --> PORTAL
  PROJECT --> PORTAL

  MATERIAL --> PURCHASE["Compra, entrega e estoque"]
  TIME --> LABOR["Análise de ponto e custos"]
  MEASURE -. compõe visão gerencial .-> FINANCE["Financeiro e DRE"]
  PURCHASE --> FINANCE
  LABOR --> FINANCE
```

### Dados herdados pela obra

| Origem | Dados que chegam ao projeto | Observação |
| --- | --- | --- |
| Orçamento aprovado | Nome, cliente, descrição, valor, prazo, conta do cliente e `sourceBudgetId` | A aprovação cria o projeto automaticamente se ainda não existir. |
| Formulário de projeto | Dados completos e coordenador selecionado | A exigência do coordenador está principalmente na interface. |
| Conta do cliente | Identificação usada pelo Portal do Cliente e RLS | O cliente vê apenas projetos vinculados à sua conta. |
| Coordenador | `coordinatorId` e nome denormalizado | A troca gera push e pedido de sincronização. |
| Equipe | `teams.projectId`, líder e membros | A equipe herda a obra; a obra não armazena todos os membros diretamente. |
| Cerca | Latitude, longitude e lado em metros | O Mobile baixa a cerca das obras atribuídas. |

## 6. Requisição, cotação, compra, financeiro e estoque

```mermaid
flowchart TB
  NEED["Necessidade na obra"] --> ITEM{"Item já existe?"}
  ITEM -->|Sim| CATALOG["Selecionar catálogo/estoque<br/>e guardar o ID no item"]
  ITEM -->|Não| NEW_ITEM["Descrever novo item"]
  CATALOG --> REQ["Requisição pending"]
  NEW_ITEM --> REQ

  REQ --> APPROVAL{"Aprovar requisição?"}
  APPROVAL -->|Não| REJECTED["rejected"]
  APPROVAL -->|Sim| APPROVED["approved"]

  APPROVED --> STOCK_DECISION{"Atender com estoque interno?"}
  STOCK_DECISION -->|Sim| OUTBOUND["Baixa manual do estoque<br/>vinculada à obra"]
  OUTBOUND --> MOVEMENT["inventory_movements"]

  STOCK_DECISION -->|Não ou insuficiente| QUOTATION["Cadastrar cotações"]
  QUOTATION --> COMPARE["Comparar valor, frete,<br/>prazo e pagamento"]
  COMPARE --> SELECT["Selecionar cotação"]
  SELECT --> CREATE_PO["Gerar um ou mais pedidos"]
  CREATE_PO --> WAITING["Purchase awaitingApproval"]
  WAITING --> PO_APPROVAL{"Aprovar pedido?"}
  PO_APPROVAL -->|Não| CANCELLED["Purchase cancelled"]
  PO_APPROVAL -->|Sim| PENDING["Purchase pending"]
  PENDING --> CONSOLIDATE["Consolidar compra"]
  CONSOLIDATE --> ORDERED["Purchase ordered"]
  CONSOLIDATE --> PAYABLE["financial_transactions<br/>conta a pagar pending"]

  ORDERED --> FULFILL{"Forma de atendimento"}
  FULFILL -->|Entrega direta| DELIVERY["Entrega na obra"]
  FULFILL -->|Coleta| ROUTE["Adicionar em rota de coleta/entrega"]
  ROUTE --> DELIVERY

  DELIVERY --> CONFIRM["Confirmar recebimento"]
  CONFIRM --> DELIVERED["Purchase delivered"]
  DELIVERED --> STOCK_IN["Entrada automática no estoque"]
  STOCK_IN --> MOVEMENT_IN["inventory_movements<br/>tipo entrada e purchaseId"]
  DELIVERED --> DB_TRIGGER["Trigger verifica todas as compras<br/>da requisição"]
  DB_TRIGGER --> REQ_DONE["Requisição delivered"]
  PAYABLE --> FINANCE["Compras a pagar e DRE"]
```

### O que é automático neste fluxo

| Transição | Tipo atual |
| --- | --- |
| Cotação selecionada → pedido aguardando aprovação | Ação explícita no ERP. |
| Aprovação do pedido → `pending` | Ação explícita no ERP. |
| Consolidação → `ordered` + conta a pagar | Ação explícita; a conta financeira é criada pelo service. |
| Confirmação da entrega → estoque + movimento | Ação explícita; os lançamentos são automáticos após confirmar. |
| Compra entregue → requisição entregue | Trigger automático no banco quando todas as compras vinculadas fecharam. |
| Estoque existente → baixa para obra | Manual; atualmente não há reserva nem fechamento automático da requisição. |

## 7. Planejamento e execução de rotas

```mermaid
flowchart TB
  VEHICLE["Veículo ativo"] --> ASSIGN["assignedEmployeeId"]
  ASSIGN --> DRIVER["Funcionário motorista"]
  DRIVER --> DRIVER_ID["purchase_delivery_routes.driverId<br/>= employees.id"]

  ORDERED["Compras ordered sem rota"] --> CANDIDATES["Candidatas à logística"]
  CANDIDATES --> PLAN["ERP cria rota"]
  DRIVER_ID --> PLAN
  PLAN --> STOPS["Gerar paradas de coleta e entrega"]
  PLAN --> PUSH["Push route + sync"]
  PUSH --> APP["Minha rota hoje no Mobile"]

  APP --> COMPUTE["Google Routes API<br/>ordena e calcula trajeto"]
  COMPUTE --> NAV["Navegação interna no mapa"]
  NAV --> TRACK["Tracking foreground/background"]
  TRACK --> SQLITE["Pontos e checkpoints no SQLite"]
  SQLITE --> SYNC["Sync periódico e ao reconectar"]
  SYNC --> TRACK_DB[("purchase_delivery_route_tracking_points")]

  NAV --> EXTERNAL{"Abrir externamente?"}
  EXTERNAL -->|Google Maps| GMAPS["Google Maps"]
  EXTERNAL -->|Waze| WAZE["Waze"]

  TRACK --> STOP["Concluir checkpoint"]
  STOP --> PROOF["Foto, assinatura ou ocorrência"]
  PROOF --> NEXT{"Há outra parada?"}
  NEXT -->|Sim| NAV
  NEXT -->|Não| COMPLETE["Concluir rota"]
  COMPLETE --> KM["Persistir KM real"]
  KM --> BONUS["bonusValue = actualDistanceKm × kmRate"]
  BONUS --> ERP_VIEW["ERP exibe status, trajeto e KM"]
```

O ERP planeja e acompanha; o motorista executa no Mobile. Motoristas elegíveis
são funcionários vinculados a veículos ativos, não registros de texto livres.

## 8. Ponto, geofence e custo de mão de obra

```mermaid
flowchart TB
  PROJECT["Projeto com coordenadas e cerca"] --> ASSIGN["Projeto/equipe atribuídos"]
  ASSIGN --> SYNC["Mobile sincroniza workspace e cercas"]
  SYNC --> LOCAL_GEO["Cercas no SQLite"]

  EMP["Funcionário abre Ponto"] --> GPS["Capturar localização e precisão"]
  LOCAL_GEO --> EVAL["Comparar posição com cercas ativas"]
  GPS --> EVAL
  EVAL --> DECISION{"Dentro da cerca válida?"}

  DECISION -->|Sim| PUNCH["Registrar entrada/saída"]
  DECISION -->|Não| BLOCK["Bloquear ou registrar exceção"]
  DECISION -->|Sem cerca sincronizada| UNKNOWN["Status unknown e orientação para sincronizar"]

  PUNCH --> AFD_LOCAL["Evento local imutável"]
  BLOCK --> GEO_EVENT["Evento de geofence/exceção"]
  AFD_LOCAL --> OUTBOX["Fila SQLite"]
  GEO_EVENT --> OUTBOX
  OUTBOX --> CLOUD["time_clock_afd_events<br/>e mobile_work_hour_entries"]

  CLOUD --> PAIR["ERP pareia entrada e saída"]
  PAIR --> HOURS["Tempo real trabalhado"]
  HOURS --> COST["Rateio do salário pelo tempo registrado"]
  COST --> EMP_VIEW["Funcionário vê suas horas no Mobile"]
  COST --> ERP_ANALYSIS["ERP: Ponto e Custos"]
  ERP_ANALYSIS --> BY_EMP["Ranking por funcionário"]
  ERP_ANALYSIS --> BY_PROJECT["Custo por obra"]
  ERP_ANALYSIS --> EXCEPTIONS["Eventos fora da cerca e inconsistências"]
  ERP_ANALYSIS --> PDF["PDF por período, obra e filtros"]
```

O cálculo usa as horas efetivamente pareadas no período. Não presume uma carga
fixa de 220 horas, evitando distorções com férias, feriados e afastamentos.

## 9. Tarefas compartilhadas

```mermaid
flowchart TB
  CREATOR["Supervisor, coordenador ou gestor"] --> CREATE["Criar tarefa"]
  CREATE --> PRIORITY["Prioridade<br/>low, medium, high ou urgent"]
  CREATE --> SUPERVISOR["Responsável supervisor"]
  CREATE --> ASSIGNEE["Executor"]
  CREATE --> SOURCE{"Origem"}
  SOURCE -->|Geral| GENERAL["Sem vínculo"]
  SOURCE -->|Obra| PROJECT["projectId"]
  SOURCE -->|Orçamento| BUDGET["budgetId"]

  PRIORITY --> TASK[("granith_tasks")]
  SUPERVISOR --> TASK
  ASSIGNEE --> TASK
  GENERAL --> TASK
  PROJECT --> TASK
  BUDGET --> TASK

  TASK --> PUSH["Push para o executor"]
  PUSH --> MOBILE["Tarefa no Mobile"]
  TASK --> ERP["Tarefa no ERP"]

  MOBILE --> ACTION{"Ação no cronômetro"}
  ERP --> ACTION
  ACTION -->|Iniciar| RPC_START["RPC start"]
  ACTION -->|Pausar| RPC_PAUSE["RPC pause"]
  ACTION -->|Concluir| RPC_COMPLETE["RPC complete"]

  RPC_START --> SERVER_TIME["activeTimerStartedAt no servidor"]
  SERVER_TIME --> RUNNING["Cronômetro continua<br/>com navegador e app fechados"]
  RPC_PAUSE --> ENTRY["Fechar time entry e acumular segundos"]
  RPC_COMPLETE --> ENTRY
  ENTRY --> HISTORY[("granith_task_time_entries")]

  MOBILE -->|sem rede| LOCAL_TASK["Atualizar tarefa local"]
  LOCAL_TASK --> TASK_OUTBOX["task_outbox"]
  TASK_OUTBOX -->|primeira conexão| ACTION
  RPC_COMPLETE --> NOTIFY_SUP["Notificar supervisor"]
```

Regras centrais:

- apenas uma tarefa pode ter cronômetro ativo por executor;
- apenas uma entrada de tempo pode permanecer aberta por tarefa;
- o tempo é calculado por timestamp do servidor, não por um `Timer` local;
- o executor controla o cronômetro;
- supervisores e níveis superiores criam/gerenciam tarefas conforme RLS;
- ações offline usam o horário ocorrido no aparelho, limitado pelo RPC a uma
  janela segura de sete dias.

## 10. Notificações e sincronização orientada a eventos

```mermaid
sequenceDiagram
  participant ERP as ERP ou trigger
  participant DB as PostgreSQL
  participant Q as mobile_push_notifications
  participant EDGE as dispatch_mobile_push
  participant FCM as Firebase FCM
  participant APP as Granith Mobile
  participant SQL as SQLite
  participant API as Supabase API

  ERP->>DB: Salva vínculo, status ou atribuição
  DB->>Q: Enfileira destinatário, categoria e syncTargets
  EDGE->>Q: Busca notificações pendentes
  EDGE->>FCM: Envia aos tokens ativos
  alt Entrega bem-sucedida
    FCM->>APP: Foreground ou background
    APP->>SQL: Persiste notificação
    APP->>SQL: Persiste solicitação de sync
    APP->>API: Atualiza apenas os alvos indicados
    API-->>SQL: Renova caches locais
    EDGE->>Q: Marca enviada
  else Falha temporária
    EDGE->>Q: Registra tentativa e próximo retry
    EDGE->>EDGE: Backoff exponencial
  else Token inválido
    EDGE->>DB: Desativa token
  end
```

### Eventos que geram push atualmente

| Evento | Destinatário principal | Alvos de sincronização |
| --- | --- | --- |
| Coordenador adicionado/removido da obra | Coordenador antigo/novo | `auth`, `workspace`, `projects`, `teams` |
| Equipe vinculada à obra | Membros relacionados | `workspace`, `projects`, `teams` |
| Benefício alterado | Funcionário | `workspace`, `benefits`, `profile` |
| Requisição ou status de material | Solicitante/relacionados | `workspace`, `requisitions`, `purchases` |
| Rota criada ou alterada | Motorista | `workspace`, `routes` |
| Veículo atribuído/removido | Funcionário | `workspace`, `vehicles`, `routes` |
| Cargo, perfil ou permissões alterados | Usuário/funcionário | `auth`, `workspace`, `profile`, `permissions` |
| Nova tarefa ou tarefa alterada | Executor ou supervisor | `tasks` |

Push não é a fonte de verdade. Se a entrega falhar, a informação continua no
Supabase e será obtida pela próxima sincronização.

## 11. Offline first do Mobile

```mermaid
flowchart TB
  BOOT["Iniciar app"] --> OPEN["Abrir bancos SQLite em paralelo"]
  OPEN --> CACHE["Exibir dados locais disponíveis"]
  BOOT --> NETWORK{"Há conexão?"}
  NETWORK -->|Não| OFFLINE["Continuar operação offline"]
  NETWORK -->|Sim| AUTH["Atualizar usuário autenticado"]
  AUTH --> TOKEN["Registrar/renovar token FCM"]
  TOKEN --> WORKSPACE["Atualizar perfil, obras, equipes,<br/>benefícios e veículos"]
  WORKSPACE --> PARALLEL["Pré-carga paralela"]

  PARALLEL --> GEO["Cercas"]
  PARALLEL --> DOCS["Documentos"]
  PARALLEL --> ROUTES["Rotas"]
  PARALLEL --> INVENTORY["Catálogo de estoque"]
  PARALLEL --> TASKS["Tarefas"]
  PARALLEL --> NOTIFICATIONS["Notificações"]
  PARALLEL --> FIELD["Operações de campo pendentes"]

  OFFLINE --> WRITE["Salvar ação no SQLite"]
  WRITE --> OUTBOX["Marcar syncPending/outbox"]
  OUTBOX --> CONNECT["Connectivity detecta primeira conexão"]
  CONNECT --> FLUSH["Enviar filas pendentes"]
  FLUSH --> REMOTE{"Supabase aceitou?"}
  REMOTE -->|Sim| CLEAN["Marcar sincronizado e renovar cache"]
  REMOTE -->|Não| RETRY["Manter fila, erro e próxima tentativa"]
  RETRY --> CONNECT

  PUSH["Push recebido"] --> LOCAL_NOTIFICATION["Salvar no SQLite"]
  LOCAL_NOTIFICATION --> TARGETS["Ler syncTargets"]
  TARGETS --> PARALLEL
```

### Bancos locais atuais

| Banco/repositório | Conteúdo |
| --- | --- |
| `WorkerWorkspaceLocalDatabase` | Perfil, obras, equipes, benefícios, veículos e resumo do workspace. |
| `TimeClockLocalDatabase` | Ponto, eventos e fila de sincronização. |
| `DriverRouteLocalDatabase` | Rotas, paradas, tracking e checkpoints. |
| `FieldOperationLocalDatabase` | Evidências, operações de estoque, veículo e campo. |
| `MobileInventoryCatalogLocalDatabase` | Catálogo usado para requisições e estoque. |
| `GranithTaskLocalDatabase` | Tarefas, pessoas, referências e `task_outbox`. |
| Banco de notificações | Notificações recebidas e solicitações pendentes de sync. |

## 12. Inteligência artificial

```mermaid
flowchart LR
  subgraph ERP["ERP Web"]
    AREA["Selecionar IA<br/>Operacional, RH, Comercial,<br/>Suprimentos ou Administrativa"]
    CHAT["Conversa independente por área"]
    CONTEXT["Contexto permitido do módulo"]
    FUNCTION["Supabase Edge Function<br/>gemini_generate"]
    AREA --> CHAT
    CHAT --> CONTEXT
    CONTEXT --> FUNCTION
  end

  FUNCTION --> GEMINI["Gemini API"]
  GEMINI --> FUNCTION
  FUNCTION --> HISTORY[("ai_conversations, ai_messages e ai_usage_events")]
  HISTORY --> CHAT

  subgraph MOBILE["Mobile offline"]
    DOWNLOAD["Download único do modelo autorizado"]
    MODEL["Arquivo local do modelo"]
    GEMMA["flutter_gemma"]
    FIELD_CONTEXT["Contexto local de campo"]
    OFFLINE_CHAT["Chats especializados offline"]
    DOWNLOAD --> MODEL
    MODEL --> GEMMA
    FIELD_CONTEXT --> GEMMA
    GEMMA --> OFFLINE_CHAT
  end
```

No ERP, a chave Gemini fica na Edge Function e não é enviada ao navegador. No
Mobile, o Hugging Face é usado para baixar o arquivo autorizado; a inferência
acontece localmente com `flutter_gemma`.

## 13. Modelo relacional resumido

```mermaid
erDiagram
  USERS }o--o| EMPLOYEES : "vincula funcionário"
  USERS }o--o| CLIENT_ACCOUNTS : "vincula cliente"
  CLIENT_ACCOUNTS ||--o{ BUDGETS : "recebe orçamento"
  CLIENT_ACCOUNTS ||--o{ PROJECTS : "possui obra"
  BUDGET_TYPES ||--o{ BUDGETS : "classifica"
  BUDGETS |o--o| PROJECTS : "aprovação origina"

  JOB_ROLES ||--o{ EMPLOYEES : "define cargo"
  EMPLOYEES ||--o{ EMPLOYEE_BENEFITS : "recebe"
  BENEFITS ||--o{ EMPLOYEE_BENEFITS : "é atribuído"
  EMPLOYEES ||--o{ SALARY_HISTORY : "possui histórico"
  EMPLOYEES ||--o{ TEAMS : "lidera"
  PROJECTS ||--o{ TEAMS : "recebe equipe"
  EMPLOYEES ||--o{ VEHICLES : "recebe veículo"

  PROJECTS ||--o{ PROJECT_MEASUREMENTS : "possui"
  PROJECTS ||--o{ DAILY_LOGS : "possui"
  PROJECTS ||--o{ MATERIAL_REQUISITIONS : "demanda"
  PROJECTS ||--o{ FINANCIAL_TRANSACTIONS : "classifica"
  PROJECTS ||--o{ INVENTORY_MOVEMENTS : "consome"
  PROJECTS ||--o{ GRANITH_TASKS : "origina"
  BUDGETS ||--o{ GRANITH_TASKS : "origina"

  MATERIAL_REQUISITIONS ||--o{ MATERIAL_REQUISITION_SUPPLIER_QUOTES : "recebe"
  SUPPLIERS ||--o{ MATERIAL_REQUISITION_SUPPLIER_QUOTES : "responde"
  MATERIAL_REQUISITIONS ||--o{ PURCHASES : "gera"
  SUPPLIERS ||--o{ PURCHASES : "fornece"
  PURCHASES ||--o| FINANCIAL_TRANSACTIONS : "gera conta"
  PURCHASES ||--o{ INVENTORY_MOVEMENTS : "gera entrada"
  INVENTORY ||--o{ INVENTORY_MOVEMENTS : "movimenta"

  EMPLOYEES ||--o{ PURCHASE_DELIVERY_ROUTES : "dirige"
  PURCHASE_DELIVERY_ROUTES ||--o{ PURCHASE_DELIVERY_ROUTE_STOPS : "contém"
  PURCHASES ||--o{ PURCHASE_DELIVERY_ROUTE_STOPS : "vira parada"
  PURCHASE_DELIVERY_ROUTES ||--o{ PURCHASE_DELIVERY_ROUTE_TRACKING_POINTS : "registra"

  EMPLOYEES ||--o{ TIME_CLOCK_AFD_EVENTS : "marca ponto"
  PROJECTS ||--o{ TIME_CLOCK_AFD_EVENTS : "localiza"
  EMPLOYEES ||--o{ MOBILE_WORK_HOUR_ENTRIES : "aponta horas"
  PROJECTS ||--o{ MOBILE_WORK_HOUR_ENTRIES : "recebe horas"

  EMPLOYEES ||--o{ GRANITH_TASKS : "supervisiona/executa"
  GRANITH_TASKS ||--o{ GRANITH_TASK_TIME_ENTRIES : "acumula"
  EMPLOYEES ||--o{ GRANITH_TASK_TIME_ENTRIES : "trabalha"

  USERS ||--o{ MOBILE_DEVICE_TOKENS : "registra aparelho"
  EMPLOYEES ||--o{ MOBILE_DEVICE_TOKENS : "recebe push"
  USERS ||--o{ MOBILE_PUSH_NOTIFICATIONS : "recebe"
```

## 14. Matriz de herança de dados

| Entidade principal | Entidades dependentes | O que é herdado/referenciado |
| --- | --- | --- |
| `users` | sessão, RLS, token FCM, conversas de IA | UID, e-mail, papel, permissões e vínculos. |
| `employees` | equipes, benefícios, veículos, rotas, tarefas, ponto | ID do funcionário, nome histórico e papel hierárquico. |
| `client_accounts` | orçamentos, projetos e portal | Conta usada para limitar o que o cliente pode consultar. |
| `budgets` | projetos e tarefas | Um orçamento aprovado pode criar a obra e mantém `projectId`. |
| `projects` | equipe, cerca, medições, diário, requisição, compra, tarefa, ponto e finanças | Identidade da obra e nome denormalizado para histórico. |
| `material_requisitions` | cotações e compras | Origem da necessidade, itens e status consolidado. |
| `purchases` | contas a pagar, paradas de rota, estoque e requisição | Fornecedor, obra, valores, entrega e situação. |
| `purchase_delivery_routes` | paradas e tracking | Motorista, agenda, status, KM e bônus. |
| `granith_tasks` | entradas de tempo | Executor, supervisor, origem e cronômetro persistente. |
| `time_clock_afd_events` | análise de mão de obra | Marcações imutáveis usadas para formar jornadas e custos. |

## 15. O que é manual e o que o sistema propaga

| Ação inicial | Propagação atual |
| --- | --- |
| Aprovar orçamento | Cria/reutiliza projeto e vincula o orçamento ao projeto. |
| Alterar coordenador da obra | Atualiza projeto, gera push e solicita sync do workspace. |
| Vincular equipe à obra | Torna a obra visível à equipe e gera evento de atualização. |
| Atribuir benefício | Atualiza RH e notifica o funcionário. |
| Atribuir veículo ativo | Torna o funcionário elegível como motorista e atualiza o Mobile. |
| Selecionar cotação | Gera pedido(s) aguardando aprovação e marca a requisição como comprada. |
| Consolidar compra | Cria/garante o contas a pagar. |
| Confirmar entrega | Atualiza compra, estoque e movimento; trigger fecha a requisição quando aplicável. |
| Iniciar tarefa | Servidor abre uma entrada de tempo; o relógio independe do cliente aberto. |
| Salvar no ERP | Service emite escopos no `AppDataRefreshBus` para recarregar telas relacionadas. |
| Receber push no Mobile | Salva localmente e sincroniza apenas os alvos do evento. |
| Trabalhar offline | Persiste localmente e envia na primeira conexão disponível. |

## 16. Pontos importantes encontrados no estado atual

1. **Diretoria não é um papel persistido em `employees`.** O enum Mobile possui
   `diretoria`, mas a constraint do banco aceita apenas `funcionario`,
   `supervisor`, `coordenador` e `gerente`. O rank 5 é concedido a `users.role =
   admin`.
2. **O vínculo usuário → funcionário está em transição.** Os fluxos novos usam
   `employee_id`/`employeeId` e fallback por e-mail. Algumas funções RLS mais
   antigas ainda resolvem o funcionário diretamente pelo e-mail do JWT.
3. **Coordenador não é `NOT NULL` no banco.** O formulário manual exige o
   coordenador, porém um projeto criado pela aprovação do orçamento pode passar
   por um caminho diferente. A regra “toda obra nasce com coordenador” ainda não
   está garantida por constraint.
4. **Estoque não reserva requisição automaticamente.** O item pode apontar para
   catálogo/estoque e uma baixa pode ser feita para a obra, mas não há hoje uma
   reserva automática nem um trigger que encerre a requisição por essa baixa.
5. **Medição atualiza progresso e indicadores, mas não cria sozinha uma receita
   financeira.** A relação com o financeiro é de análise/visão gerencial no
   service auditado.
6. **Nomes são parcialmente denormalizados.** Tabelas guardam IDs e também
   campos como `projectName`, `employeeName` e `supplierName`; isso preserva
   contexto histórico, mas alterações no cadastro principal não necessariamente
   renomeiam todo o histórico.
7. **Firebase não é o banco operacional.** Dados de negócio estão no Supabase;
   Firebase permanece para Hosting e FCM.

## 17. Checklist para comparar com outro diagrama

Ao receber o seu diagrama, a comparação deve responder:

- Ele coloca o Supabase como fonte de verdade?
- Separa planejamento/gestão no ERP de execução de campo no Mobile?
- Mostra `users` separado de `employees` e `client_accounts`?
- Representa a hierarquia cumulativa e as permissões específicas?
- Orçamento aprovado gera projeto?
- Projeto concentra coordenador, equipe, cerca e operações da obra?
- Requisição passa por cotação, pedido, aprovação, consolidação e entrega?
- Compra consolidada gera contas a pagar?
- Entrega alimenta estoque e pode fechar a requisição?
- Veículo ativo vinculado ao funcionário define o motorista?
- ERP planeja rota e Mobile executa/tracking?
- Ponto nasce no Mobile e a análise de custo fica no ERP?
- Tarefas usam timestamp/RPC do servidor e não cronômetro volátil?
- Push apenas acorda/sincroniza, sem substituir o banco?
- Mobile mantém cache e outbox no SQLite?
- Gemini do ERP passa pela Edge Function?
- IA do Mobile executa localmente após o download do modelo?

## 18. Fontes usadas para este mapa

Principais pontos de validação:

- `lib/screens/main_layout.dart`
- `lib/app/routing/app_router.dart`
- `lib/services/`
- `lib/core/data/app_data_refresh_bus.dart`
- `supabase/migrations/20260503100000_base_schema.sql`
- `supabase/migrations/20260503200000_enable_rls_security_baseline.sql`
- `supabase/migrations/20260504143000_mobile_role_hierarchy.sql`
- `supabase/migrations/20260509160000_add_purchase_logistics_and_requisition_quotes.sql`
- `supabase/migrations/20260515110000_add_mobile_notification_events.sql`
- `supabase/migrations/20260515123000_mobile_push_sync_requests.sql`
- `supabase/migrations/20260708150000_add_mobile_vehicle_purchase_sync.sql`
- `supabase/migrations/20260727120000_add_shared_tasks_module.sql`
- Mobile: `lib/core/services/mobile_startup_sync_service.dart`
- Mobile: `lib/core/services/mobile_notification_service.dart`
- Mobile: `lib/core/services/location_background_service.dart`
- Mobile: `lib/features/**/data/`

