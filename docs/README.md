# Granith ERP: Visão de Negócio e Arquitetura

## Visão de negócio

O Granith ERP é uma plataforma vertical para empresas de engenharia e construção. O problema que ele resolve não é apenas cadastrar projetos: é manter rastreável a passagem entre planejamento, execução de obra, suprimentos, financeiro e relacionamento com o cliente.

Em uma operação comum, informações ficam distribuídas entre planilhas, mensagens, controles de estoque, documentos e sistemas isolados. O Granith cria uma linha operacional única:

```text
Orçamento -> Projeto/obra -> Equipe e execução -> Requisição
        -> Cotação e compra -> Entrega/estoque -> Financeiro e DRE
        -> Portal do cliente, relatórios e indicadores
```

O ERP é a fonte administrativa do ecossistema. Ele cadastra, planeja, aprova, audita e consolida os eventos enviados pelo Mobile e pelo Granith Engenharia.

## Desafios técnicos

### Dados relacionais sem perder o fluxo operacional

Obra, equipe, funcionário, coordenador, requisição, compra, rota, item e lançamento financeiro são entidades diferentes, mas precisam continuar conectadas. A arquitetura usa PostgreSQL no Supabase, migrations versionadas e relações explícitas para preservar origem, responsável, obra e status de cada evento.

### Permissões que refletem a empresa real

O acesso não pode depender apenas de uma tela escondida no navegador. O sistema combina usuário autenticado, funcionário vinculado, papel, escopo e RLS para limitar projetos, documentos, valores, rotas e dados de cliente. Usuários internos permitem atender colaboradores que não possuem conta Google.

### Atualização consistente após cada ação

Inserções e mudanças de status precisam aparecer imediatamente nas listas e indicadores. Os módulos adotam refresh após mutações, atualização de estado local quando segura e Realtime/debounce onde a mudança também pode vir de outro produto do ecossistema.

### Integração de eventos de campo

Uma rota executada, um ponto batido, uma foto de entrega ou uma requisição criada no celular devem manter significado no ERP. Por isso, cada fluxo tem estados e registros próprios, evitando transformar eventos de campo em simples anotações sem contexto.

## Arquitetura técnica

```text
Flutter Web
  telas, controllers, services e componentes compartilhados
        |
        v
Supabase Auth + PostgREST + Realtime
        |
        v
PostgreSQL com RLS, views, RPCs e migrations
        |
        +--> Storage privado para evidências e documentos
        +--> Edge Functions para ações sensíveis
        +--> Firebase Cloud Messaging para o Mobile
```

| Camada | Decisão |
| --- | --- |
| Interface | Flutter Web responsivo, com componentes reutilizáveis e layout operacional denso |
| Estado | `provider`/`ChangeNotifier` no núcleo existente e `flutter_riverpod` em fluxos pontuais |
| Backend | `supabase_flutter` para Auth, PostgreSQL, Storage, Realtime e RPC |
| Segurança | RLS no banco e Edge Functions para ações que não devem depender do cliente |
| Mapas | `google_maps_flutter` para contexto geográfico, rotas e cercas de obra |
| Relatórios | `pdf` e `printing` para documentos e exportações |
| Indicadores | `fl_chart` para leitura gerencial de financeiro, obra e desempenho |
| Entrega | Firebase Hosting e GitHub Actions |

## Bibliotecas e por que elas existem

| Biblioteca | Papel no produto |
| --- | --- |
| `supabase_flutter` | Cliente para autenticação, banco, Storage, Realtime e chamadas RPC |
| `provider` | Mantém o estado de telas e módulos legados de forma simples e previsível |
| `flutter_riverpod` | Isola fluxos mais recentes que precisam de dependências e estado reativo |
| `google_maps_flutter` | Exibe obras, rotas e geofences no contexto operacional |
| `google_sign_in` | Integra o login corporativo Google ao Supabase Auth |
| `fl_chart` | Traduz dados financeiros e operacionais em indicadores legíveis |
| `pdf` e `printing` | Geração, visualização e impressão de relatórios de negócio |
| `image_picker` e `file_picker` | Captura de evidências e anexos de operação |
| `intl` | Moeda, data, idioma e formatação compatíveis com a operação brasileira |

## Lógicas de resolução de problemas

### Da requisição à compra e ao financeiro

A requisição não termina no pedido do funcionário. Ela pode consultar catálogo e estoque, seguir para cotação, pedido de compra, recebimento e lançamento financeiro. O objetivo é manter a origem da necessidade até o custo efetivo da obra.

### Funcionário, equipe, obra e coordenador

O vínculo do usuário ao funcionário é a base para permissões, Mobile, ponto, benefícios, veículo e equipe. Projetos nascem com coordenação definida e permitem mudança rastreável, evitando acesso baseado apenas em e-mail.

### Rotas e entregas

O ERP planeja a rota e vincula motorista por funcionário/veículo ativo. O Mobile executa checkpoints, tracking, comprovantes e quilômetros reais. O ERP recebe o histórico para acompanhamento, sem tentar reproduzir a experiência de navegação do motorista no navegador.

### Ponto e custo de mão de obra

O ponto usa eventos com localização e geofence como evidência. O cálculo de custo considera as horas realmente registradas por funcionário e obra, em vez de assumir jornada fixa mensal, o que preserva férias, feriados e variações operacionais.

### Notificações sem expor credenciais

Eventos relevantes são persistidos e encaminhados por Edge Function ao FCM. O navegador não recebe service account, chave Gemini ou credencial de servidor. O Mobile recebe o push, persiste a notificação e agenda sincronização do contexto afetado.

### IA com fronteira de segurança

Assistentes por módulo chamam `gemini_generate` no Supabase. A função valida sessão, modelos permitidos e limites antes de chamar o provedor. O Flutter Web nunca contém `GEMINI_API_KEY`.

## Documentos especializados

| Documento | Conteúdo |
| --- | --- |
| [Fluxo completo do ecossistema](fluxo_completo_granith.md) | Herança de dados entre ERP, Mobile, Engenharia e Supabase |
| [Modelo de dados](data_model_mer_der.md) | Entidades e relações principais |
| [Contrato ERP/Mobile](erp_mobile_operational_contract.md) | Responsabilidades de cada produto e sincronização |
| [Push Mobile](mobile_push_notifications.md) | FCM, destinos, retry e ativação |
| [Auditoria RLS](rls_audit.md) | Regras de acesso e pontos de validação |
| [Integração Engenharia](engineering_ecosystem_integration.md) | Documentos técnicos, entregas, relatórios e notificações |

## Limites e maturidade

O Granith ERP é uma base funcional avançada e um caso de estudo de integração Flutter/Supabase. Antes de operação comercial ampla, exige homologação de regras fiscais e trabalhistas, revisão contínua de RLS, observabilidade, política de backup, SMTP próprio e validação com usuários reais de obra.
