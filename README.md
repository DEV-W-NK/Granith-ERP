# Granith ERP

[![CI/CD Firebase Hosting](https://github.com/DEV-W-NK/Granith-ERP/actions/workflows/firebase-hosting.yml/badge.svg)](https://github.com/DEV-W-NK/Granith-ERP/actions/workflows/firebase-hosting.yml)

ERP web para construtoras, obras e operacoes que precisam sair da planilha e trabalhar com rastreabilidade, controle financeiro, estoque, compras, equipes, portal do cliente e visao gerencial.

O Granith ERP centraliza a rotina operacional de uma empresa de obras: projetos, orcamentos, medicoes, diario de obra, requisicoes, compras, estoque, financeiro, RH, frota, geofencing, permissoes, clientes, relatorios e assistentes de IA em evolucao.

> Status: MVP avancado em beta operacional. O projeto esta pronto para demonstracao, validacao com usuarios e pilotos controlados. Para producao ampla, ainda exige hardening final de seguranca, revisao de infraestrutura e amadurecimento de alguns fluxos.

## Visao Rapida

| Area | Estado |
| --- | --- |
| Frontend | Flutter Web responsivo |
| Backend | Supabase, Postgres, Auth, Storage, Realtime, migrations e Edge Functions |
| Deploy web | Firebase Hosting via GitHub Actions |
| Banco | Migrations Supabase versionadas |
| Testes | Models, services, controllers, viewmodels e widgets |
| Integracoes | Supabase, OAuth Google, Google Maps/geocoding, Firebase Hosting e base para IA Gemini |
| Mobile | Projeto Android complementar em evolucao para rotinas de campo |

Deploy web configurado para Firebase Hosting:

```text
https://granith-skyforge.web.app/
```

## Principais Recursos

- Projetos e obras como centro da operacao.
- Orcamentos comerciais e tipos de orcamento.
- Medicoes de obra com progresso e valores.
- Diario de obra com base para evidencias e historico operacional.
- Requisicoes de materiais e servicos.
- Compras, fornecedores, estoque e catalogo de itens.
- Financeiro com contas, transacoes, origem e referencia.
- DRE gerencial e relatorios executivos.
- RH, colaboradores, cargos, setores, beneficios e equipes.
- Frota, veiculos, motoristas e base para logistica.
- Geofencing com Google Maps/geocoding.
- Portal do cliente com acesso separado da area interna.
- Gestao de usuarios, permissoes e acessos internos/clientes.
- Notificacoes e base para integracao com app mobile.
- Assistentes de IA por contexto, com roadmap para backend seguro.

## Fluxo Operacional

```text
Orcamento aprovado
        |
        v
Projeto / Obra
        |
        v
Medicoes, diario, equipe e geofencing
        |
        v
Requisicao de material ou servico
        |
        v
Compra com fornecedor
        |
        v
Entrega, estoque ou consumo direto
        |
        v
Conta a pagar / transacao financeira
        |
        v
DRE, relatorios e indicadores
```

## Modulos

| Modulo | Descricao |
| --- | --- |
| Dashboard | Visao geral da operacao e indicadores principais |
| Projetos | Obras, clientes, status, custos, progresso, equipes e localizacao |
| Orcamentos | Propostas comerciais, tipos, itens, valores e status |
| Medicoes | Progresso fisico/financeiro, valores medidos e acumulados |
| Diario de obra | Historico operacional e registros de campo |
| Requisicoes | Demandas internas para compras, materiais e servicos |
| Compras | Pedidos, fornecedores, itens, notas, entregas e financeiro |
| Estoque | Saldos, movimentacoes, entradas, saidas e transferencias |
| Fornecedores | Cadastro, consulta CNPJ e suporte ao fluxo de compras |
| Financeiro | Receitas, despesas, contas, origem, referencia e compras a pagar |
| Relatorios/DRE | Leitura gerencial de resultado, custos e desempenho |
| RH | Colaboradores, cargos, setores, beneficios e historico |
| Equipes | Associacao de pessoas, liderancas e projetos |
| Frota | Veiculos, responsaveis, status e base para operacao mobile |
| Geofencing | Cercas geograficas para obras e validacao de presenca |
| Acessos | Usuarios, permissoes, clientes e portal do cliente |
| Configuracoes | Parametros gerais, assinatura e administracao do workspace |

## Stack Tecnica

| Camada | Tecnologia |
| --- | --- |
| UI | Flutter |
| Estado | Provider/ChangeNotifier e Riverpod em pontos de orquestracao |
| Backend | Supabase Postgres + PostgREST |
| Auth | Supabase Auth e OAuth Google |
| Storage | Supabase Storage |
| Edge Functions | Deno/Supabase Functions |
| Maps | Google Maps e geocoding |
| Graficos | fl_chart |
| Deploy | Firebase Hosting |
| CI/CD | GitHub Actions |
| Testes | flutter_test |

## Estrutura

```text
lib/
  app/           bootstrap, providers e roteamento
  controllers/   estado e regras de tela
  core/          infraestrutura compartilhada
  features/      modulos novos em arquitetura por feature
  models/        entidades e serializacao
  screens/       paginas principais
  services/      Supabase e integracoes externas
  widgets/       componentes e views por modulo
supabase/
  functions/     Edge Functions
  migrations/    schema e evolucao do banco
  templates/     templates auxiliares
test/            testes automatizados
docs/            auditorias e documentacao tecnica
```

## Como Rodar Localmente

Requisitos:

- Flutter stable.
- Dart SDK compativel com a versao do Flutter.
- Chrome para desenvolvimento web.
- Supabase CLI se for aplicar migrations.
- JDK 21 para builds Android.

Instale dependencias:

```powershell
flutter pub get
```

Crie os arquivos locais de ambiente:

```powershell
Copy-Item .env.example .env.local
Copy-Item supabase/.env.example supabase/.env.local
```

Edite `.env.local` com as chaves de desenvolvimento. Depois rode:

```powershell
.\scripts\run_dev.ps1 -CheckOnly
.\scripts\run_dev.ps1 -Device chrome
```

O script carrega variaveis locais, repassa os valores seguros via `--dart-define`, gera `web/env.js` local para Google Maps no navegador e prepara secrets locais de iOS quando necessario.

## Variaveis Locais

| Variavel | Uso |
| --- | --- |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | Chave publica/anon do Supabase |
| `GOOGLE_MAPS_API_KEY` | Google Maps e geocoding |
| `GOOGLE_OAUTH_WEB_CLIENT_ID` | OAuth Google Web |
| `GOOGLE_OAUTH_ANDROID_CLIENT_ID` | OAuth Google Android |
| `GOOGLE_OAUTH_IOS_CLIENT_ID` | OAuth Google iOS |
| `GOOGLE_OAUTH_IOS_REVERSED_CLIENT_ID` | URL scheme iOS |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Apenas local/Supabase, nunca no cliente Flutter Web |
| `GOOGLE_OAUTH_REDIRECT_URL` | Redirect local do OAuth |
| `GEMINI_API_KEY` | Apenas desenvolvimento local. Para producao, usar backend seguro |
| `GEMINI_MODEL` | Modelo Gemini configurado |

Nunca versionar secrets. O `SUPABASE_PUBLISHABLE_KEY` e publico por natureza, mas so deve ser usado com RLS forte. Nunca usar `service_role` no cliente Flutter.

## Supabase

Migrations ficam em:

```text
supabase/migrations
```

Edge Functions ficam em:

```text
supabase/functions
```

Comandos comuns:

```powershell
supabase login
supabase link --project-ref SEU_PROJECT_REF
supabase db push
```

Secrets de Edge Functions devem ficar em `supabase/.env.local`, que e ignorado pelo Git. Exemplos de secrets server-side:

```text
SUPABASE_SERVICE_ROLE_KEY
GRANITH_MANAGEMENT_API_TOKEN
GRANITH_PUSH_DISPATCH_TOKEN
FIREBASE_SERVICE_ACCOUNT_JSON
```

## CI/CD e Firebase Hosting

O workflow principal fica em:

```text
.github/workflows/firebase-hosting.yml
```

Comportamento:

| Evento | Acao |
| --- | --- |
| Pull request para `main` | Roda `pub get`, `analyze`, `test`, `build web` e publica preview quando os secrets existem |
| Push na `main` | Roda validacao/build e publica no Firebase Hosting live quando os secrets existem |
| `workflow_dispatch` | Permite deploy manual pelo GitHub Actions |

Secrets necessarios no GitHub Actions:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
GOOGLE_MAPS_API_KEY
GOOGLE_OAUTH_WEB_CLIENT_ID
FIREBASE_SERVICE_ACCOUNT_GRANITH_SKYFORGE
```

Configure em:

```text
GitHub > Repository > Settings > Secrets and variables > Actions
```

`FIREBASE_SERVICE_ACCOUNT_GRANITH_SKYFORGE` deve receber o JSON completo da service account do Firebase.

Se algum secret ainda nao estiver configurado, o workflow continua rodando validacao, testes e build com placeholders, mas pula o deploy.

Nao coloque estes secrets no build Flutter Web:

```text
SUPABASE_SERVICE_ROLE_KEY
GOOGLE_OAUTH_CLIENT_SECRET
GEMINI_API_KEY
```

Essas chaves precisam ficar no backend/Edge Functions.

## Testes

Comandos recomendados:

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --release `
  --dart-define=SUPABASE_URL="https://example.supabase.co" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="placeholder" `
  --dart-define=GOOGLE_MAPS_API_KEY="" `
  --dart-define=GOOGLE_OAUTH_WEB_CLIENT_ID=""
```

A suite cobre models, services, controllers, viewmodels e widgets de modulos como projetos, orcamentos, compras, estoque, financeiro, RH, permissoes, portal do cliente, veiculos e relatorios.

## Seguranca

Base atual:

- Supabase Auth.
- Separacao entre usuario interno, admin e cliente.
- Modelo de permissoes por codigo.
- Baseline de RLS em migrations.
- Edge Functions para operacoes server-side sensiveis.
- Arquivos locais sensiveis ignorados pelo Git.
- Historico Git limpo para publicacao do repositorio.

Pontos antes de producao ampla:

- Migrar chamadas Gemini para Edge Function/backend seguro.
- Revisar buckets privados e URLs assinadas.
- Refinar RLS por permissao e operacao critica.
- Validar fluxo de usuarios reais por perfil.
- Configurar SMTP proprio para convites do portal do cliente.
- Revisar headers de seguranca no hosting.

## IA e Gemini

O ERP possui base de assistentes por area. Em desenvolvimento local, a chave Gemini pode ser usada via `.env.local`.

Para producao web, `GEMINI_API_KEY` nao deve ser enviada no `flutter build web`, porque qualquer chave embutida no bundle pode ser lida no navegador. O caminho correto e:

```text
Flutter Web -> Supabase Edge Function -> Gemini API
```

Assim a chave fica protegida no backend, com possibilidade de rate limit, auditoria, permissao por usuario e controle de custo.

## Portal do Cliente e Convites

O portal do cliente usa Supabase Auth e fluxo de Magic Link para convite.

Template versionado:

```text
supabase/templates/client_portal_magic_link.html
```

Enquanto SMTP proprio nao estiver configurado, o remetente pode aparecer como Supabase/Auth e ha limites baixos de envio. Para uso comercial em volume, configurar SMTP proprio com dominio validado e prioridade operacional.

Mais detalhes:

```text
docs/client_portal_email_setup.md
```

## Granith Mobile

O mobile e o complemento operacional do ERP, focado em Android e rotinas de campo. Ele nao replica toda a administracao web; o objetivo e coletar dados e sincronizar informacoes relevantes para colaboradores.

Frentes previstas:

- Minha rota hoje.
- Tracking de rota.
- Evidencias de entrega/coleta.
- Estoque mobile simples.
- Checklist de veiculo.
- Medicoes com evidencia de campo.
- Notificacoes push/local.
- Consulta offline de documentos.
- Assistente local/offline para apoio de campo.

## Roadmap

1. Hardening final de seguranca e RLS.
2. DRE consolidado com alta confiabilidade.
3. IA via backend seguro com auditoria e controle de custo.
4. Mobile de campo com rotas, geofencing, diario, evidencias e notificacoes.
5. Custo real de mao de obra por obra.
6. Logistica de compras, entregas, motoristas e frota.
7. Portal do cliente com documentos e acompanhamento tecnico.
8. Polimento visual e UX para pilotos comerciais.

## Posicionamento

O Granith ERP e uma base real de produto, nao apenas um prototipo. Ele ja possui amplitude de ERP, modulos integrados, banco versionado, testes e deploy automatizado.

O posicionamento atual mais honesto e: **ERP vertical para construtoras em beta avancado, pronto para demonstracao e pilotos controlados, com fluxo ponta a ponta implementado e roadmap claro para producao.**
