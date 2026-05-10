# Auditoria de seguranca - Granith ERP

Data: 2026-05-10  
Escopo: Flutter Web/Android/iOS, Supabase Postgres/Auth/Storage/Edge Functions, Firebase Hosting, scripts locais, dependencias NPM/Dart e configuracao de build.

## Resumo executivo

O projeto evoluiu bastante desde a auditoria de 2026-05-03. A migracao para Supabase esta mais madura: ha baseline de RLS, grants de `anon` foram removidos, GraphQL foi desabilitado, `usage_stats` foi endurecido e a Edge Function `sync_usage_stats` valida JWT antes de usar `service_role`.

Mesmo assim, ainda ha pontos que bloqueiam producao segura:

1. A chave Gemini e chamada diretamente pelo cliente Flutter.
2. O bucket `project-images` continua publico e o codigo gera URLs publicas para imagens de obra e diario.
3. Algumas migrations novas criam tabelas sem `GRANT` para `authenticated`, porque a baseline revogou privilegios padrao.
4. Varias policies ainda tratam qualquer `employee` como usuario interno com CRUD amplo.
5. O build Android de release esta assinado com debug key.
6. Firebase Hosting nao define headers de seguranca para o app web.
7. A autorizacao de IA e de alguns modulos ainda depende demais de UI/cliente e de policies amplas.

## Verificacoes executadas

- `git status --short --branch`: branch limpa em `main`.
- Varredura de arquivos e configuracoes com `rg --files`.
- Varredura de secrets com regex local, sem imprimir valores.
- `git ls-files` e `git check-ignore` para confirmar arquivos sensiveis ignorados.
- `npm audit --json`: 0 vulnerabilidades na raiz.
- `flutter pub outdated --json`: nenhum pacote atual marcado com advisory ativo; ha pacotes atualizaveis.
- `dart analyze`: falhou com 456 warnings/infos, sem achado direto de seguranca, mas inviabiliza usar analyze como gate sem saneamento ou baseline.
- `npx supabase --version`: CLI 2.95.6; disponivel 2.98.2.
- Revisao estatica das migrations Supabase, services Flutter, Edge Function e configuracoes web/mobile.

Limites desta auditoria:

- Nao rodei Supabase Security Advisor remoto porque o repositorio nao possui `supabase/config.toml` vinculado nesta copia.
- Nao rodei teste dinamico contra um projeto Supabase real com usuarios `admin`, `employee` e `client`.
- `osv-scanner` nao esta instalado no ambiente.

## Pontos positivos

- `.gitignore` ignora `.env.local`, `web/env.js`, `ios/Flutter/Secrets.xcconfig`, `supabase/.env.*` e `supabase_usage.env`.
- A varredura de secrets encontrou apenas uma chave Gemini em `.env.local`, arquivo ignorado.
- `service_role` aparece apenas como segredo esperado da Edge Function, nao no cliente Flutter.
- `sync_usage_stats` valida Authorization, consulta o usuario via Supabase Auth e so entao usa client com `service_role`.
- O antigo risco de `projectRef` vindo do corpo foi corrigido: a funcao usa `GRANITH_PROJECT_REF`/URL do projeto.
- GraphQL foi removido com `drop extension if exists pg_graphql`.
- `usage_stats` agora permite leitura autorizada e escrita por `service_role`.

## Achados criticos e altos

### 1. Gemini roda no cliente e expoe chave e dados sensiveis

Severidade: Critica antes de producao.

Evidencia:

- `scripts/run_dev.ps1` inclui `GEMINI_API_KEY` em `--dart-define`.
- `lib/services/gemini_ai_service.dart` le `GEMINI_API_KEY` via `String.fromEnvironment`.
- `lib/services/gemini_ai_service.dart` chama `https://generativelanguage.googleapis.com` direto do app.
- `lib/services/ai_assistant_service.dart` carrega contexto real do banco e envia para o Gemini.

Impacto:

- Em Flutter Web, qualquer chave em `--dart-define` pode ser extraida do bundle ou das chamadas de rede.
- Em mobile, a chave tambem pode ser extraida do binario.
- Dados operacionais, RH, comercial, suprimentos e administrativos podem ser enviados ao provedor de IA diretamente do cliente.
- Nao ha rate limit server-side, controle central de custo, auditoria robusta por usuario nem redacao de PII antes do envio.

Acao recomendada:

- Mover Gemini para uma Supabase Edge Function ou backend proprio.
- Remover `GEMINI_API_KEY` dos `dart-define` publicos.
- A Edge Function deve validar JWT, permissao por area de IA, limite de taxa, limite de custo, tamanho de prompt, escopo de tabelas/colunas e logs de auditoria.
- Redigir PII e dados financeiros/salariais quando nao forem indispensaveis.
- Rotacionar a chave se ela ja foi usada em qualquer build publico ou compartilhada fora da maquina local.

### 2. Bucket `project-images` e publico

Severidade: Alta.

Evidencia:

- `supabase/migrations/20260503100000_base_schema.sql` cria `project-images` com `public = true`.
- `lib/services/service_projetos.dart` usa `getPublicUrl`.
- `lib/controllers/daily_log_controller.dart` tambem salva fotos de diario no mesmo bucket e usa URL publica.

Impacto:

- Supabase Storage trata bucket publico como arquivo acessivel por qualquer pessoa que tenha a URL.
- Policies em `storage.objects` ainda protegem listagem/upload/delete, mas nao tornam o conteudo privado quando a URL publica e conhecida.
- Imagens de obra e diario podem conter informacao operacional, local, pessoas, documentos ou evidencias de campo.

Acao recomendada:

- Separar buckets:
  - `public-assets` apenas para imagens realmente publicas.
  - `project-images-private` ou `project-documents` privado para obras, diarios e evidencias.
- Usar `download()` autenticado ou signed URLs com expiracao curta.
- Definir `allowed_mime_types` e `file_size_limit` no bucket.
- Validar assinatura real do arquivo e tamanho antes do upload; diario de obra hoje confia basicamente no nome/extensao.

### 3. Migrations novas criam tabelas sem grants apos revoke de default privileges

Severidade: Alta operacional; risco de remediacao insegura.

Evidencia:

- A baseline revoga privilegios padrao em `supabase/migrations/20260503200000_enable_rls_security_baseline.sql`.
- Tabelas criadas depois sem `grant ... to authenticated`:
  - `purchase_delivery_routes`
  - `purchase_delivery_route_stops`
  - `material_requisition_supplier_quotes`
  - `ai_conversations`
  - `ai_messages`
  - `ai_usage_events`
  - `ai_model_pricing`

Impacto:

- Mesmo com RLS/policies, o cliente pode receber `permission denied for table`.
- A pressa para corrigir em producao pode levar alguem a conceder privilegios amplos demais.

Acao recomendada:

- Criar migration explicita com grants minimos:
  - rotas/cotacoes: somente operacoes realmente usadas pelo app, depois refinar RLS por permissao.
  - `ai_conversations`: `select, insert, update`.
  - `ai_messages`: `select, insert`.
  - `ai_usage_events`: `select, insert`.
  - `ai_model_pricing`: `select` para internos e `insert/update` apenas se a policy de pricing exigir.
- Manter sem `delete` salvo necessidade real.

### 4. Policies `internal_crud` ainda sao amplas demais

Severidade: Alta.

Evidencia:

- A baseline aplica `for all ... using (private.is_internal_user())` para catalogos e operacoes como `budget_types`, `job_roles`, `items`, `suppliers`, `purchases`, `inventory`, `inventory_movements`, `vehicles`, `vehicle_fuel_logs`, `material_requisitions`, `daily_logs` e `teams`.
- Migrations posteriores refinam parte de `teams`, `daily_logs` e `material_requisitions`, mas varios modulos continuam com CRUD amplo para qualquer `employee`.
- Veiculos/frota e logistica de compras tambem usam `private.is_internal_user()` para CRUD.

Impacto:

- Qualquer funcionario autenticado pode chamar PostgREST diretamente com a publishable key e tentar criar, alterar ou excluir dados de modulos que talvez a UI nao mostre.
- Em ERP, UI nao e controle de seguranca. O controle real precisa ficar no banco ou backend.

Acao recomendada:

- Trocar `internal_crud` por policies separadas por operacao:
  - `*.read`
  - `*.write`
  - `*.approve`
  - `*.delete`
  - `inventory.adjust`
  - `purchases.consolidate`
  - `fleet.manage`
- Para delete, exigir permissao mais forte ou bloquear e usar soft delete/auditoria.
- Criar testes RLS por perfil: admin, financeiro, comprador, RH, colaborador comum e cliente.

### 5. Cliente pode ler `budgets` diretamente se tiver projeto/conta propria

Severidade: Alta se valores de orcamento forem condicionalmente ocultos.

Evidencia:

- `budgets` contem `totalValue` e `items`.
- A policy `budgets_select_by_role` permite cliente por `clientAccountId` ou projeto acessivel.
- O app possui flags como `client_portal_show_budget_values`, mas flag de UI nao impede chamada direta ao REST.

Impacto:

- Se a regra de negocio permitir esconder valores do portal, o cliente ainda pode consultar a tabela `budgets` diretamente pela API.

Acao recomendada:

- Criar view/RPC sanitizada para portal, como foi feito para `client_portal_projects`.
- Revogar select direto de cliente em `public.budgets`.
- Separar colunas de valor/itens detalhados em tabela/view com permissao propria se esses dados forem sensiveis.

### 6. Android release assinado com debug key

Severidade: Alta antes de distribuir APK/AAB.

Evidencia:

- `android/app/build.gradle.kts` usa `signingConfig = signingConfigs.getByName("debug")` no build `release`.
- `applicationId` ainda e `com.example.project_granith`.

Impacto:

- Build de release nao esta pronto para distribuicao.
- Identidade do app, update path e integracoes OAuth/Maps ficam fragilizadas.

Acao recomendada:

- Criar keystore de release, armazenar senha fora do repo, configurar signing por variavel/CI secret.
- Trocar `applicationId` para dominio real da empresa.
- Configurar OAuth/Maps por package name e SHA-1/SHA-256 de release.
- Considerar `flutter build apk/appbundle --obfuscate --split-debug-info=...` para release.

### 7. Firebase Hosting sem headers de seguranca

Severidade: Media/Alta para Web.

Evidencia:

- `firebase.json` possui apenas `hosting.public`, `ignore` e `rewrites`; nao ha `headers`.
- `web/index.html` usa script inline e `document.write`, o que dificulta CSP forte.

Impacto:

- Menor protecao contra clickjacking, MIME sniffing, vazamento de referrer e XSS.
- CSP sera mais dificil enquanto houver scripts inline.

Acao recomendada:

- Adicionar headers no Firebase Hosting:
  - `Content-Security-Policy` inicialmente em modo `Report-Only`.
  - `X-Content-Type-Options: nosniff`.
  - `Referrer-Policy: strict-origin-when-cross-origin`.
  - `Permissions-Policy` restritiva.
  - `frame-ancestors 'none'` via CSP.
- Remover `document.write` e preferir criacao segura de `script`.
- Ajustar CSP para Supabase, Google Maps e assets do Flutter.

## Achados medios

### 8. Fluxo Auth implicit e vinculacao administrativa por e-mail

Severidade: Media.

Evidencia:

- `Supabase.initialize` usa `AuthFlowType.implicit`.
- Migrations permitem resolver perfil por `auth.uid()` ou `email`, preservando admin semeado quando OAuth cria UID diferente.

Impacto:

- Implicit flow entrega tokens ao cliente via fragmento de URL. Em app client-only isso e suportado, mas PKCE e o caminho mais robusto para public clients/OAuth moderno.
- Resolver admin por e-mail exige disciplina forte: e-mail confirmado, MFA e controle de provedores. Se a conta de e-mail for comprometida, o papel admin e herdado.

Acao recomendada:

- Migrar o fluxo principal para PKCE onde possivel.
- Exigir e-mail confirmado e MFA para admins.
- Apos primeiro login, vincular o perfil administrativo ao `auth.uid()` real e reduzir dependencia permanente de fallback por e-mail.

### 9. CORS wildcard na Edge Function

Severidade: Media.

Evidencia:

- `supabase/functions/_shared/cors.ts` usa `Access-Control-Allow-Origin: *`.

Impacto:

- A funcao valida Authorization, entao isso nao abre acesso sozinho.
- Ainda assim, em producao e melhor restringir origem para reduzir superficie e erros de integracao.

Acao recomendada:

- Responder origem dinamicamente apenas para dominios permitidos.
- Manter `Authorization` obrigatorio e `OPTIONS` sem dados sensiveis.

### 10. IA por area nao tem gate forte no cliente/backend

Severidade: Media/Alta, dependendo dos dados por modulo.

Evidencia:

- Rotas `/ai/*` usam `_canAccessInternalApp`, ou seja, qualquer `employee`/`admin`.
- `AiAssistantService` decide contexto por area e carrega tabelas diretamente.
- A seguranca real acaba dependendo das RLS existentes, que ainda sao amplas em varios modulos.

Impacto:

- Colaborador comum pode usar areas de IA para resumir dados de modulos que talvez nao deveria consultar.

Acao recomendada:

- Criar permissoes por area: `ai.operational.use`, `ai.hr.use`, `ai.commercial.use`, `ai.supplies.use`, `ai.admin.use`.
- Enforce no backend/Edge Function, nao apenas no menu.

### 11. Muitas consultas ainda usam `select()`

Severidade: Media.

Evidencia:

- Ainda ha chamadas `.select()` sem lista de colunas em services/controllers.

Impacto:

- Se uma coluna sensivel for adicionada no futuro, ela pode vazar automaticamente para clientes autorizados por linha.

Acao recomendada:

- Usar selects explicitos em todos os services.
- Para dados sensiveis por coluna, usar view/RPC ou column privileges.

### 12. Falta pipeline de seguranca/CI

Severidade: Media.

Evidencia:

- Nao ha `.github` no repositorio.
- `dart analyze` falha com 456 issues, entao hoje nao serve como gate.
- `osv-scanner` nao esta instalado.

Acao recomendada:

- Adicionar CI com:
  - `flutter test`
  - `dart analyze` com baseline ou limpeza gradual
  - `npm audit --audit-level=high`
  - scanner OSV
  - secret scanning (`gitleaks` ou equivalente)
  - `supabase db lint`
  - testes RLS automatizados em banco local/staging

### 13. APIs externas chamadas direto do cliente

Severidade: Baixa/Media.

Evidencia:

- Google Geocoding usa chave no cliente.
- ReceitaWS e BrasilAPI sao chamados direto do app.

Impacto:

- Enderecos e CNPJs consultados saem do ambiente do ERP.
- Chaves/cotas de Maps precisam estar muito bem restritas.

Acao recomendada:

- Para Maps, restringir por referrer/package/SHA/API/cota.
- Para consultas recorrentes/custosas, usar backend com cache e rate limit.
- Documentar privacidade: quais dados vao para terceiros.

### 14. Logs de debug podem expor detalhes de operacao

Severidade: Baixa/Media.

Evidencia:

- Ha varios `debugPrint`/`print` com nomes de projeto, erros de upload e erros de servico.

Impacto:

- Em web/mobile, console e crash logs podem acumular informacao operacional.

Acao recomendada:

- Remover `print`.
- Envolver logs verbosos em `kDebugMode`.
- Sanitizar mensagens antes de enviar para usuario/log remoto.

## Plano de remediacao

### 0-48 horas

1. Mover Gemini para backend ou desabilitar IA em build publico ate isso estar pronto.
2. Tornar fotos de obra/diario privadas ou separar buckets publicos/privados.
3. Criar migration de grants minimos para tabelas novas sem privilegio.
4. Configurar signing real de Android e trocar `applicationId`.
5. Adicionar headers de seguranca no Firebase Hosting, pelo menos `nosniff`, `Referrer-Policy`, `Permissions-Policy` e CSP report-only.
6. Rodar Supabase Security Advisor no projeto real e comparar com esta auditoria.

### 1 semana

1. Refatorar RLS de `internal_crud` para permissoes granulares.
2. Criar view/RPC sanitizada para budgets do portal do cliente.
3. Migrar Auth principal para PKCE e exigir MFA para admins.
4. Restringir CORS da Edge Function.
5. Criar testes RLS com perfis reais.

### 2-4 semanas

1. Adicionar pipeline CI de seguranca.
2. Remover todos os `select()` amplos.
3. Implementar trilha de auditoria para operacoes criticas: acesso, financeiro, compras, RH, alteracoes de permissao e IA.
4. Formalizar classificacao de dados: publico, interno, cliente, confidencial, sensivel.
5. Criar rotina mensal: dependency audit, Supabase Advisor, revisao de secrets, backup/restore testado.

## Checklist de aceite para producao

- Nenhuma chave secreta no bundle web/mobile.
- IA chama apenas backend autenticado.
- Bucket com dados de obra/diario privado ou com signed URLs.
- Nenhuma tabela publica nova sem RLS e grants minimos.
- Nenhuma policy sensivel usando apenas `private.is_internal_user()` para escrita ampla.
- Cliente nao consegue consultar orcamentos/valores ocultos por API direta.
- Android/iOS com bundle id real, signing real e chaves restritas.
- Firebase Hosting com headers de seguranca.
- Supabase Security Advisor sem erros criticos/altos nao justificados.
- Testes RLS provam isolamento entre admin, funcionario comum, financeiro, comprador, RH e cliente.

## Referencias consultadas

- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage buckets: https://supabase.com/docs/guides/storage/buckets/fundamentals
- Supabase serving assets: https://supabase.com/docs/guides/storage/serving/downloads
- Supabase Auth PKCE: https://supabase.com/docs/guides/auth/sessions/pkce-flow
- Supabase Auth implicit flow: https://supabase.com/docs/guides/auth/sessions/implicit-flow
- Firebase Hosting headers: https://firebase.google.com/docs/hosting/full-config
