# Mapa de seguranca Supabase - Granith ERP

Data: 2026-05-07

## Decisao tecnica

O app Flutter usa `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` via `--dart-define`.
Esses valores aparecem no Network por natureza. A protecao real deve ficar no
Postgres/Supabase:

- RLS em todas as tabelas expostas.
- Policies por papel/permissao.
- Triggers bloqueando campos privilegiados.
- Edge Functions apenas para operacoes com segredo ou regra administrativa.
- Leitura com colunas explicitas no cliente, evitando `select=*`.
- Flags visuais do portal do cliente nao devem ser tratadas como seguranca de
  coluna. Se valores de orcamento/custo nao puderem ser vistos pelo cliente,
  mover a leitura do portal para view/RPC/Edge Function que nunca retorne esses
  campos para `role = client`.

Token de uso unico para cada request nao protege chamadas diretas ao
`/rest/v1`: o PostgREST do Supabase valida o JWT da sessao do Supabase, nao um
token customizado por acao. Para usar token de request seria preciso rotear a
acao por Edge Function/backend, validar o token la, marcar como usado e so entao
executar a operacao server-side. Isso pode ser util para acoes criticas, mas nao
substitui RLS.

## Superficie client-side

| Recurso | Arquivos principais | Controle esperado |
| --- | --- | --- |
| `users` | `lib/services/auth_service.dart`, `lib/services/access_management_service.dart`, `supabase/functions/sync_usage_stats/index.ts` | Usuario le apenas o proprio perfil; admin/access manager gerencia todos. Trigger impede usuario comum de alterar `role`, `permissions`, `status` e vinculos sensiveis. |
| `client_accounts` | `lib/services/client_account_service.dart` | Admin/access manager gerencia; cliente le propria conta por e-mail/user id/vinculo. Trigger limita autoatualizacao de portal. |
| `projects` | `lib/services/service_projetos.dart`, `lib/services/project_measurement_service.dart`, `lib/services/service_orcamentos.dart`, `lib/controllers/reports_controller.dart`, `lib/ViewModels/HomeViewModel.dart` | Equipe interna acessa a tabela bruta. Cliente usa `client_portal_projects`, que remove colunas financeiras. Escrita apenas interna. |
| `client_portal_projects` | `lib/services/service_projetos.dart` | View sanitizada para cliente, filtrada por conta vinculada e sem `budget`/`currentCost`. |
| `project_measurements` | `lib/services/project_measurement_service.dart` | Equipe interna escreve; cliente le apenas medicoes dos projetos permitidos. |
| `budgets` | `lib/services/service_orcamentos.dart` | Equipe interna escreve; cliente le apenas orcamentos da propria conta/projeto. |
| `financial_transactions` | `lib/services/financial_service.dart`, `lib/controllers/reports_controller.dart`, `lib/ViewModels/HomeViewModel.dart` | Leitura por `financial.read`; escrita por `financial.write`. |
| `employees`, `teams` | `lib/services/HrService.dart`, `lib/services/team_service.dart` | `people.manage` tem acesso amplo; mobile hierarquico limita leitura/escrita por papel e equipe. |
| `benefits`, `benefit_categories`, `employee_benefits`, `salary_history` | `lib/services/HrService.dart` | `people.manage`; algumas leituras proprias/hierarquicas para mobile. |
| `daily_logs`, `material_requisitions` | `lib/services/daily_log_service.dart`, `lib/services/material_requisition_service.dart`, widgets de detalhe | Usuario interno le; supervisor/coordenacao podem criar/atualizar conforme policies mobile. |
| `inventory`, `inventory_movements`, `items`, `suppliers`, `purchases`, `budget_types`, `job_roles` | services dos modulos operacionais | CRUD interno via `private.is_internal_user()` ou policy especifica. |
| `system_settings` | `lib/services/system_settings_service.dart` | Leitura autenticada; escrita por `settings.manage`/admin. |
| `usage_stats` | `lib/services/usage_service.dart`, `supabase/functions/sync_usage_stats/index.ts` | Leitura/sync por admin, billing, infra ou settings. Escrita pelo backend da Edge Function. |
| Storage `project-images` | `lib/services/service_projetos.dart`, `lib/controllers/daily_log_controller.dart` | Policies em `storage.objects`: interno escreve; cliente le somente imagens de projeto permitido. |
| Edge Function `sync_usage_stats` | `supabase/functions/sync_usage_stats/index.ts` | Valida bearer JWT, consulta perfil server-side e usa `service_role` apenas dentro da function. |

## RLS ja mapeada em migrations

Migration principal:

- `supabase/migrations/20260503200000_enable_rls_security_baseline.sql`

Complementos:

- `supabase/migrations/20260503210000_disable_unused_graphql_surface.sql`
- `supabase/migrations/20260504143000_mobile_role_hierarchy.sql`
- `supabase/migrations/20260504170000_add_benefit_categories.sql`
- `supabase/migrations/20260505110000_add_benefit_values_reimbursements.sql`
- `supabase/migrations/20260507120000_harden_usage_stats_writes.sql`
- `supabase/migrations/20260507121000_secure_client_project_view.sql`

Pontos importantes da baseline:

- Remove grants amplos de `anon`.
- Habilita RLS nas tabelas publicas existentes.
- Cria funcoes auxiliares no schema `private`.
- Cria policies para admin, funcionario interno e cliente.
- Remove policy ampla `Acesso Total` em `client_accounts`.
- Remove policy publica ampla em `storage.objects`.
- Restringe funcoes de uso de banco/storage a `service_role`.
- Mantem `usage_stats` como leitura autorizada no cliente e escrita apenas por
  `service_role`/Edge Function.
- Fecha leitura direta de `public.projects` para clientes e expõe
  `public.client_portal_projects` sem `budget`, `currentCost` e campos
  financeiros do projeto.

## Ajuste aplicado no cliente

Foram substituidos os pontos mais sensiveis de `select()` amplo por colunas
explicitas usando `lib/core/supabase/supabase_selects.dart`:

- `users`: remove `select=*` do login/perfil e da tela de gerenciamento.
- `client_accounts`: lista, busca por e-mail e retorno de insert/upsert.
- `system_settings`: leitura e retorno de save.
- `usage_stats`: leitura do snapshot atual.
- `financial_transactions`: consultas de item/referencia, dashboard e relatorios.
- `projects`, `inventory`, `daily_logs`: consultas de dashboard/relatorio.

Isso nao esconde as requests, mas reduz vazamento acidental de colunas e deixa o
contrato de leitura explicito.

## Quando usar token de request unico

Use apenas para acoes criticas que forem movidas para backend/Edge Function,
por exemplo:

- alterar `role`/`permissions`;
- convidar cliente;
- aprovar transacao financeira sensivel;
- executar rotinas administrativas.

Formato recomendado se for implementado:

- token aleatorio de 128 bits ou mais;
- hash salvo no banco, nunca token puro;
- vinculo com `auth.uid()`, `session_id`/`jti`, acao e payload esperado;
- expiracao curta, por exemplo 30 a 120 segundos;
- coluna `used_at` preenchida em transacao atomica;
- validacao server-side em Edge Function/RPC.

Nao usar esse modelo para toda leitura do app. O custo e a complexidade crescem
muito e o token continuara visivel no Network da chamada ao backend.

## Checklist de validacao

1. Aplicar todas as migrations em staging.
2. No Supabase SQL Editor, confirmar que nao ha tabela `public` sem RLS:

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
order by tablename;
```

3. Testar com usuario cliente:
   - trocar `id` em `/rest/v1/users`;
   - listar `client_accounts`;
   - consultar `financial_transactions`;
   - consultar projeto de outro cliente;
   - atualizar `role`/`permissions` no proprio `users`.
4. Resultado esperado: vazio, `401`, `403` ou erro de policy.
5. Rodar Supabase Security Advisor e confirmar ausencia de erro critico.
