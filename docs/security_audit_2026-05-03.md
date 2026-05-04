# Relatorio de seguranca - Granith ERP

Data: 2026-05-03  
Escopo: aplicativo Flutter, Supabase/Postgres, Supabase Edge Function, Firebase/Firestore/Storage, dependencias NPM/Dart e arquivos de configuracao do repositorio.

## Atualizacao pos-migracao

Este relatorio registra o estado encontrado no inicio da auditoria. Depois dele, o app foi migrado para Supabase no runtime: Firestore, Firebase Auth, Firebase Storage, Firebase Functions e configuracoes mobile do Firebase foram removidos do codigo/dependencias. Firebase permanece apenas para Hosting. Os riscos ainda atuais devem ser avaliados pelo advisor do Supabase e pelos pontos pendentes descritos no guia de migracao.

## Resumo executivo

O projeto tem riscos criticos de autorizacao no backend. O problema central e que a API do Supabase esta expondo tabelas no schema `public` sem RLS efetivo, enquanto parte do app ainda usa Firebase com Firestore rules totalmente abertas. A seguranca atual depende demais do cliente Flutter, o que nao e suficiente: qualquer pessoa com uma chave publica e uma sessao valida pode tentar chamar diretamente PostgREST/GraphQL/Storage/Firebase.

Prioridade imediata:

1. Corrigir RLS no Supabase antes de expor o app em producao.
2. Fechar Firestore rules ou remover Firebase das rotas ainda em uso.
3. Rotacionar o token de Management API do Supabase usado localmente.
4. Corrigir vulnerabilidades NPM em `functions/`.
5. Remover policies permissivas e exposicao GraphQL/Storage ampla.

## Fontes e verificacoes executadas

- `npm audit --json` na raiz: 0 vulnerabilidades.
- `npm audit --json` em `functions/`: 17 vulnerabilidades, incluindo 1 critica.
- `npm outdated --json` na raiz e em `functions/`.
- `flutter pub outdated --json` / `dart pub outdated --json`: nenhum pacote retornado como `isCurrentAffectedByAdvisory=true`; houve falha de decodificacao de advisories do pub.dev para alguns pacotes, entao este resultado nao deve ser tratado como varredura Dart perfeita.
- `npx supabase db lint --linked --output json --fail-on none`: sem erros de schema.
- Supabase Management API Security Advisors: 75 lints de seguranca.
- Varredura local de secrets, Supabase, Firebase, Storage e chamadas `.from(...)`.
- Documentacao consultada:
  - Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
  - Supabase secure data: https://supabase.com/docs/guides/database/secure-data
  - Supabase API keys: https://supabase.com/docs/guides/getting-started/api-keys
  - Supabase Storage access control: https://supabase.com/docs/guides/storage/security/access-control

## Achados criticos

### 1. RLS ausente em tabelas publicas do Supabase

Severidade: Critica  
Evidencia local:

- `supabase_schema.sql` cria 23 tabelas em `public`.
- `supabase/migrations/20260503100000_base_schema.sql` e migrations seguintes nao contem `enable row level security`, `force row level security` ou `create policy`.

Evidencia remota, Security Advisor:

- `rls_disabled_in_public` em 22 tabelas:
  - `public.budgets`
  - `public.budget_types`
  - `public.job_roles`
  - `public.employees`
  - `public.teams`
  - `public.suppliers`
  - `public.purchases`
  - `public.inventory`
  - `public.inventory_movements`
  - `public.material_requisitions`
  - `public.daily_logs`
  - `public.financial_transactions`
  - `public.users`
  - `public.employee_benefits`
  - `public.benefits`
  - `public.salary_history`
  - `public.talent_candidates`
  - `public.usage_stats`
  - `public.items`
  - `public.system_settings`
  - `public.projects`
  - `public.project_measurements`

Impacto:

- Dados financeiros, RH, estoque, fornecedores, compras, projetos, medicoes e usuarios podem ficar acessiveis pela API se houver grants para `anon`/`authenticated`.
- A documentacao do Supabase orienta RLS em todas as tabelas de schemas expostos, especialmente `public`.

Correcao recomendada:

- Criar migration de RLS para todas as tabelas expostas.
- Iniciar em staging, porque habilitar RLS sem policies quebra o app.
- Usar `TO authenticated` nas policies, checks explicitos de `auth.uid() is not null` e funcoes auxiliares em schema nao exposto, por exemplo `private`.
- Remover acesso direto do cliente para operacoes administrativas sensiveis; usar Edge Functions/RPCs com autorizacao server-side.

### 2. Firestore rules permitem leitura e escrita por qualquer pessoa

Severidade: Critica  
Evidencia:

- `firestore.rules`:
  - `allow read, write: if true;`
- O app ainda usa `FirebaseFirestore` em varios servicos:
  - `daily_log_service.dart`
  - `financial_service.dart`
  - `HrService.dart`
  - `inventory_service.dart`
  - `material_requisition_service.dart`
  - `ProjectBudgetService.dart`
  - `purchase_service.dart`
  - `supplier_service.dart`
  - `reports_controller.dart`
  - `utils/seeder.dart`

Impacto:

- Se essas rules estiverem implantadas, qualquer cliente com a configuracao Firebase do app consegue ler e alterar colecoes do ERP.
- A presenca de `google-services.json` e `firebase_options.dart` e normal em apps Firebase, mas com rules abertas vira vetor direto de exploracao.

Correcao recomendada:

- Se Firestore nao for mais fonte oficial: publicar rules deny-by-default.
- Se Firestore ainda for usado: criar rules por colecao, autenticacao, papel e escopo de cliente/funcionario.
- Remover chamadas Firestore remanescentes ou migrar para Supabase com RLS equivalente.

### 3. Escalada de privilegio via `public.users`

Severidade: Critica  
Evidencia:

- `supabase_schema.sql` define `public.users` com `role` e `permissions`.
- `lib/services/auth_service.dart` faz `upsert` em `users` no cliente.
- `lib/services/access_management_service.dart` lista e altera usuarios pelo cliente.
- RLS esta ausente em `public.users`.
- A Edge Function `sync_usage_stats` usa `public.users.role` e `public.users.permissions` para autorizar acesso administrativo.

Impacto:

- Um usuario pode tentar alterar seu proprio `role`/`permissions`, ou outros perfis, diretamente pela API se a tabela estiver exposta.
- Isso compromete autorizacao do app e da Edge Function de billing/infra.

Correcao recomendada:

- `users`: permitir `SELECT` do proprio perfil; admins podem listar.
- Bloquear update direto de `role`, `permissions`, `status`, `clientAccountId` pelo usuario comum.
- Atualizacoes de acesso devem passar por Edge Function/RPC com service role e checagem server-side.
- Criar FK/logica forte ligando `public.users.id` a `auth.users.id`.

### 4. Token de Management API do Supabase em arquivo local do projeto

Severidade: Alta/Critica, dependendo do escopo do token  
Evidencia:

- `supabase_usage.env` contem `GRANITH_MANAGEMENT_API_TOKEN=sbp_...`.
- O arquivo esta ignorado por `.gitignore`, mas existe no working tree.
- `git check-ignore` confirma ignore para `supabase_usage.env`.

Impacto:

- Token `sbp_...` e credencial sensivel de Management API. Se copiado, logado, enviado ou sincronizado fora do ambiente seguro, pode permitir acoes administrativas no Supabase conforme escopo.

Correcao recomendada:

- Rotacionar o token atual.
- Guardar esse segredo no mecanismo de secrets do Supabase/CI ou em gerenciador de senhas.
- Evitar manter token pessoal no diretorio do repo.
- Registrar nos procedimentos: nunca imprimir tokens completos; no maximo 6 caracteres iniciais ou hash SHA-256.

### 5. Dependencias NPM vulneraveis em `functions/`

Severidade: Critica  
Resultado `npm audit` em `functions/`:

- Total: 17 vulnerabilidades.
- Critica: 1.
- Altas: 4.
- Moderadas: 10.
- Baixas: 2.

Principais pacotes afetados:

- `protobufjs`: critica, arbitrary code execution.
- `lodash`: alta, code injection/prototype pollution.
- `node-forge`: alta, falhas em verificacao/assinatura/DoS.
- `path-to-regexp`: alta, ReDoS.
- `picomatch`: alta, ReDoS/metodo injection.
- Cadeia Firebase/Google: `firebase-admin`, `@google-cloud/firestore`, `@google-cloud/storage`, `google-gax`, `uuid`, `teeny-request`.

Raizes observadas:

- `protobufjs` vem por `firebase-functions@4.9.0`, `firebase-admin@13.7.0`, `google-gax` e `@google-cloud/firestore`.
- `path-to-regexp` vem por `express` usado por `firebase-functions@4.9.0`.
- `lodash` vem por `firebase-functions-test`.
- `node-forge` vem por `firebase-admin@13.7.0`.

Correcao recomendada:

- Atualizar `firebase-admin` para `13.8.0` ou versao mais recente validada.
- Planejar upgrade de `firebase-functions` de `4.9.0` para serie atual compativel.
- Rodar `npm audit fix` com cuidado e revisar lockfile.
- Reexecutar testes/emuladores apos atualizar.

## Achados altos

### 6. Policy permissiva em `client_accounts`

Severidade: Alta  
Evidencia remota:

- Security Advisor: `rls_policy_always_true`.
- Tabela `public.client_accounts` possui policy `Acesso Total` para `ALL` com `USING` e `WITH CHECK` sempre verdadeiros.

Impacto:

- Mesmo com RLS ligado, a policy efetivamente libera acesso irrestrito.
- Clientes poderiam visualizar/alterar contas de outros clientes se grants permitirem.

Correcao recomendada:

- Remover policy `Acesso Total`.
- Criar policies separadas:
  - Admin/access manager: acesso total.
  - Cliente: `SELECT` apenas da propria conta por `portal_auth_user_id = auth.uid()::text` ou vinculo equivalente.
  - Escrita de cliente: normalmente negar, exceto campos explicitamente permitidos por RPC.

### 7. GraphQL exposto para anon e authenticated

Severidade: Alta  
Evidencia remota:

- `pg_graphql_anon_table_exposed`: 24 objetos.
- `pg_graphql_authenticated_table_exposed`: 24 objetos.
- Objetos incluem `users`, `financial_transactions`, `salary_history`, `projects`, `project_measurements`, `client_accounts`, `usage_stats` e `GranithERP`.

Impacto:

- Objetos aparecem no schema GraphQL para publico e usuarios logados.
- Mesmo quando RLS for corrigida, a visibilidade do schema pode facilitar enumeracao e abuso.

Correcao recomendada:

- Revogar `SELECT` de `anon` onde nao houver necessidade publica.
- Revogar `SELECT` amplo de `authenticated` para tabelas sensiveis.
- Considerar desabilitar GraphQL/Data API para schemas que nao devem ser acessados diretamente.

### 8. Bucket publico `project-images` permite listagem

Severidade: Alta  
Evidencia remota:

- Security Advisor: `public_bucket_allows_listing`.
- Bucket `project-images` tem policy ampla `Allow select for everyone` em `storage.objects`.

Impacto:

- Clientes podem listar objetos do bucket, nao apenas acessar URLs ja conhecidas.
- Imagens de projetos podem revelar nomes, IDs, historico visual ou estrutura de pastas.

Correcao recomendada:

- Se as imagens precisam ser publicas: remover policy de listagem ampla e manter acesso por URL publica sem listagem.
- Se as imagens nao devem ser publicas: tornar bucket privado, usar signed URLs e policies por projeto/cliente.
- Validar upload por tipo MIME, tamanho maximo e ownership.

### 9. Firebase Storage amplo para qualquer usuario autenticado

Severidade: Alta  
Evidencia:

- `storage.rules`:
  - `allow read, write: if request.auth != null;`
- `daily_log_controller.dart` faz upload em `daily_logs/{projectId}/{fileName}`.

Impacto:

- Qualquer usuario autenticado no Firebase pode ler/escrever qualquer objeto do bucket.
- Sem regra por projeto/usuario, um cliente ou funcionario indevido pode sobrescrever anexos.

Correcao recomendada:

- Restringir por path e papel.
- Validar content type e tamanho.
- Se Storage Firebase for legado, bloquear escrita e migrar para Supabase Storage com RLS.

### 10. Seeder disponivel no cliente

Severidade: Alta  
Evidencia:

- `lib/screens/main_layout.dart` exibe FloatingActionButton para `DatabaseSeeder().seed()`.
- `lib/utils/seeder.dart` escreve dados em Supabase e Firestore.

Impacto:

- Qualquer usuario que acesse o layout principal pode popular/alterar dados de demonstracao.
- Com RLS/Firestore rules fracas, isso vira escrita administrativa client-side.

Correcao recomendada:

- Remover seeder do app em builds de producao.
- Guardar seeder em script administrativo local/CI.
- Se mantido em dev, proteger por `kDebugMode` e flag local.

## Achados medios

### 11. Edge Function `sync_usage_stats` aceita `projectRef` do corpo

Severidade: Media  
Evidencia:

- `supabase/functions/sync_usage_stats/index.ts` usa `body.projectRef` antes de `GRANITH_PROJECT_REF`.
- A mesma funcao usa `GRANITH_MANAGEMENT_API_TOKEN` para consultar a Management API.

Impacto:

- Usuario autorizado no ERP pode solicitar sincronizacao de outro `projectRef` se o token tiver escopo suficiente.
- Em conjunto com escalada em `users`, o risco aumenta.

Correcao recomendada:

- Ignorar `projectRef` vindo do cliente.
- Usar apenas env var do projeto.
- Retornar erros sanitizados sem detalhes de infraestrutura.

### 12. `set_updated_at` com search_path mutavel

Severidade: Media  
Evidencia remota:

- Security Advisor: `function_search_path_mutable` em `public.set_updated_at`.

Impacto:

- Funcoes sem `SET search_path` fixo podem executar objetos inesperados em cenarios de path manipulation.

Correcao recomendada:

- Recriar a funcao com `set search_path = public, pg_temp` ou caminho minimo adequado.
- Revisar funcoes `security definer` e mover funcoes privilegiadas para schema nao exposto.

### 13. Protecao contra senhas vazadas desativada

Severidade: Media  
Evidencia remota:

- Security Advisor: `auth_leaked_password_protection`.

Impacto:

- Usuarios podem definir senhas ja comprometidas publicamente.

Correcao recomendada:

- Habilitar leaked password protection no Supabase Auth.
- Aumentar politica minima de senha, MFA para administradores e rate limits.

### 14. Rotas e autorizacao client-side insuficientes

Severidade: Media  
Evidencia:

- `AppRouter` abre rotas administrativas como `/access-management`, `/settings`, `/reports`, `/subscription` diretamente.
- Menus exibem modulos administrativos sem checagem forte de permissoes por item.

Impacto:

- A UI pode expor telas indevidas via deep link ou navegacao interna.
- Mesmo corrigindo UI, a protecao real deve ficar no backend/RLS.

Correcao recomendada:

- Adicionar guards de rota por `AuthViewModel`/permissoes.
- Esconder/desabilitar modulos sem permissao.
- Nao depender disso como controle principal: RLS e Edge Functions continuam obrigatorios.

## Achados baixos / manutencao

### 15. Dependencias Dart/Flutter desatualizadas

Severidade: Baixa/Media  
Evidencia:

- `cloud_firestore`, `firebase_auth`, `firebase_core`, `firebase_storage`, `image_picker`, `supabase_flutter` possuem versoes resolviveis mais novas.
- `google_sign_in` tem major upgrade disponivel.

Impacto:

- Nao foi detectado advisory ativo pelo comando, mas manter SDKs de auth/storage atrasados aumenta superficie de bugs e incompatibilidades.

Correcao recomendada:

- Atualizar pacotes em lote pequeno e testar login, upload, Firestore legado e Supabase.

### 16. Chaves Firebase publicas sem evidencia de restricao

Severidade: Baixa isoladamente; Alta junto das rules abertas  
Evidencia:

- `android/app/google-services.json`
- `lib/firebase_options.dart`

Impacto:

- Chaves Firebase de cliente nao sao segredo por si so, mas devem ter restricoes de API/app sempre que possivel.
- Com Firestore rules abertas, elas facilitam abuso.

Correcao recomendada:

- Restringir API keys no Google Cloud por app/bundle/package/SHA.
- Corrigir Firestore/Storage rules.

## Desenho RLS recomendado

Modelo base:

- Usar Supabase Auth como fonte de identidade.
- `public.users.id` deve representar `auth.uid()::text`.
- Criar schema `private` para funcoes auxiliares nao expostas.
- Roles do app devem ficar em `raw_app_meta_data` ou em tabela protegida; nunca confiar em `raw_user_meta_data` para autorizacao.
- Policies devem usar `TO authenticated` e checks explicitos.

Funcoes auxiliares sugeridas:

```sql
create schema if not exists private;

create or replace function private.current_user_role()
returns text
language sql
security definer
set search_path = public, pg_temp
as $$
  select u.role
  from public.users u
  where u.id = (select auth.uid())::text
  limit 1
$$;

create or replace function private.current_user_permissions()
returns text[]
language sql
security definer
set search_path = public, pg_temp
as $$
  select coalesce(u.permissions, '{}')
  from public.users u
  where u.id = (select auth.uid())::text
  limit 1
$$;

create or replace function private.has_app_role(required_role text)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select coalesce(private.current_user_role() = required_role, false)
$$;

create or replace function private.has_permission(required_permission text)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select coalesce(required_permission = any(private.current_user_permissions()), false)
$$;
```

Exemplos de policy por dominio:

- `users`
  - `SELECT`: proprio usuario ou admin.
  - `UPDATE`: usuario comum so campos nao privilegiados; admin/access manager via RPC.
  - `role` e `permissions`: nunca editaveis diretamente pelo proprio usuario.
- `client_accounts`
  - Admin/access manager: CRUD.
  - Cliente: `SELECT` apenas da conta vinculada.
  - Sem `ALL USING true`.
- `projects`, `project_measurements`, `budgets`
  - Equipe interna: por permissoes (`projects.read`, `projects.write`, `budgets.read`, `budgets.write`).
  - Cliente: `SELECT` apenas quando `client_account_id` ou `"clientAccountId"` corresponder ao perfil dele.
  - Cliente: sem `INSERT/UPDATE/DELETE`.
- `financial_transactions`, `salary_history`, `employees`, `employee_benefits`
  - Somente admins ou permissoes especificas (`financial.read`, `people.manage`).
- `system_settings`
  - `SELECT` autenticado se necessario.
  - `UPDATE` apenas admin/settings manager.
- `usage_stats`
  - Admin/billing only.
- Catalogos (`items`, `budget_types`, `job_roles`)
  - `SELECT` autenticado se o app precisa.
  - Escrita apenas admin/permissao especifica.

## Plano de remediacao sugerido

### 0-24h

1. Rotacionar `GRANITH_MANAGEMENT_API_TOKEN`.
2. Publicar Firestore rules temporarias deny-by-default, se a operacao permitir.
3. Remover ou esconder o seeder em builds de producao.
4. Remover policy `Acesso Total` de `client_accounts`.
5. Habilitar leaked password protection no Supabase Auth.

### 1-3 dias

1. Criar migration de RLS para todas as tabelas `public`.
2. Criar policies por modulo e permissao.
3. Criar testes de RLS com usuarios admin, employee e client.
4. Fechar listagem publica do bucket `project-images`.
5. Atualizar `functions/` e resolver `npm audit`.

### 1-2 semanas

1. Migrar servicos Firestore restantes ou escrever rules equivalentes ao modelo RLS.
2. Mover operacoes administrativas para Edge Functions/RPCs.
3. Revisar exposicao GraphQL/Data API.
4. Adicionar CI com:
   - `npm audit`
   - `flutter pub outdated` ou scanner OSV equivalente
   - `supabase db lint --linked`
   - consulta automatizada aos Security Advisors

## Criterios de aceite

- Security Advisor sem `ERROR`.
- Nenhuma tabela sensivel em `public` sem RLS.
- Nenhuma policy `USING true`/`WITH CHECK true` em tabela sensivel.
- Firestore sem `allow read, write: if true`.
- `functions/` com `npm audit` sem alta/critica.
- Cliente comum nao consegue:
  - listar outro cliente,
  - editar `role`/`permissions`,
  - ver financeiro/RH,
  - listar bucket inteiro,
  - executar sync de uso sem permissao real.
