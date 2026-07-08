# Granith ERP

**ERP moderno para construtoras, obras e operacoes que precisam sair da planilha e operar com rastreabilidade, controle financeiro e visao gerencial.**

O Granith ERP e uma plataforma de gestao empresarial criada para centralizar a rotina completa de uma empresa de obras: projetos, orcamentos, medicoes, diario de obra, requisicoes, compras, estoque, financeiro, recursos humanos, frota, geofencing, clientes, permissoes, portal do cliente, relatorios e assistentes de IA.

Mais do que um conjunto de cadastros, o sistema foi desenhado para conectar as areas da empresa. Uma requisicao pode virar compra, a compra pode alimentar estoque e financeiro, a obra concentra custo realizado, o DRE consolida resultado e o gestor enxerga o impacto operacional sem depender de informacoes espalhadas.

## Resumo executivo

| Ponto | Estado atual |
| --- | --- |
| Produto | MVP avancado em estagio beta operacional |
| Plataforma principal | Flutter Web com suporte responsivo para desktop, tablet e mobile |
| Backend | Supabase com Postgres, Auth, Storage, Realtime, migrations e Edge Functions |
| Modulos de negocio | 27 areas de navegacao ja estruturadas no ERP |
| Banco de dados | 26 migrations Supabase versionadas |
| Qualidade | 132 arquivos de teste entre models, services, controllers, viewmodels e widgets |
| Integracoes | OAuth Google, Google Maps/geocoding, Supabase e assistentes Gemini em desenvolvimento |
| Uso ideal hoje | Demonstracao comercial, validacao com usuarios, piloto controlado e evolucao para producao |

O projeto ja passou da fase de prototipo. Ele possui arquitetura real, banco versionado, telas implementadas, testes, regras de permissao, portal do cliente, integracoes externas e uma linha clara de evolucao para mobile operacional e uso em producao.

## O quao completo ele e?

O Granith ERP esta em um ponto forte para apresentacao comercial: ja mostra o fluxo completo de uma construtora, com modulos integrados e profundidade suficiente para demonstrar valor real. O posicionamento mais honesto e vendavel hoje e:

| Cenario | Situacao |
| --- | --- |
| Demo para cliente, parceiro ou investidor | Pronto para demonstrar a visao do produto e seus principais fluxos |
| Piloto interno ou com cliente controlado | Viavel, desde que acompanhado de validacao operacional e ajustes de seguranca |
| Uso administrativo real em ambiente fechado | Bem encaminhado, principalmente para validar processos e dados |
| Producao publica ampla | Requer hardening final de seguranca, release mobile/Android e revisao de infraestrutura |

Em termos praticos, o sistema ja cobre a maior parte do ciclo operacional e administrativo. O que falta nao e "criar o ERP do zero", mas finalizar polimento, seguranca de producao, regras finas por perfil, DRE definitivo, mobile de campo e alguns fluxos avancados.

## Diferenciais

- **Obra como centro de controle:** projetos concentram orcamentos, medicoes, equipes, diarios, requisicoes, compras, custos e indicadores.
- **Fluxo ponta a ponta:** orcamento aprovado, obra, requisicao, compra, estoque, financeiro e relatorios conversam entre si.
- **Rastreabilidade financeira:** transacoes podem carregar origem e referencia, permitindo saber se um valor veio de compra, obra, medicao, lancamento manual ou custo operacional.
- **Permissoes por responsabilidade:** o ERP separa acesso interno, administrativo e cliente, com base em papeis e permissoes.
- **Portal do cliente:** clientes podem acessar informacoes da propria conta/projeto sem entrar na area interna da empresa.
- **Base pronta para mobile de campo:** diario de obra, geofencing, ponto, beneficios e registros operacionais ja fazem parte da estrategia do produto.
- **Assistentes de IA por area:** IA operacional, RH, comercial, suprimentos e administrativa, com contexto de negocio e trilha para evoluir com seguranca no backend.
- **Arquitetura escalavel:** Flutter no front, Supabase no backend, migrations versionadas, services por dominio e testes cobrindo pontos importantes.

## Modulos do ERP

### Painel e gestao executiva

O painel inicial organiza a visao geral da operacao, indicadores recentes e atalhos para os principais fluxos. A proposta e entregar para a diretoria uma leitura rapida do estado da empresa, sem depender de relatorios manuais.

**Estado:** implementado como entrada principal do ERP, com evolucao prevista para consolidar indicadores executivos mais profundos.

### Projetos e obras

Projetos sao o eixo central do Granith ERP. Cada obra pode guardar cliente, descricao, status, periodo, orcamento, custo atual, progresso, localizacao, tags, equipe, medicoes e relacoes com compras, diarios e financeiro.

**Estado:** modulo implementado e integrado a orcamentos, medicoes, portal do cliente, requisicoes e indicadores de custo.

### Medicoes de obra

As medicoes acompanham progresso fisico e financeiro da obra, com sequencia, valores, descontos, percentual medido, acumulado e saldo contratual.

**Estado:** funcional e conectado ao ciclo de obra e financeiro gerencial.

### Diario de obra

O diario de obra registra rotina de campo, evidencias, responsaveis e historico operacional. Ele e uma base importante para controle de execucao, auditoria e comunicacao com cliente.

**Estado:** implementado com fluxo de assinatura e regras de visibilidade em evolucao.

### Orcamentos comerciais

O modulo de orcamentos trata propostas e orcamentos de obra, com tipos de orcamento, cliente, projeto, itens, valor total, status, datas e possibilidade de vinculacao com a obra.

**Estado:** implementado e conectado ao ciclo comercial e ao projeto.

### Requisicoes de materiais e servicos

Requisicoes representam demandas internas da obra ou setor. Elas ajudam a transformar pedidos soltos em um fluxo controlado de aprovacao, compra, entrega e custo.

**Estado:** implementado, com evolucao para cotacoes de fornecedores e aprovacao por responsabilidade/setor.

### Compras e pedidos

Compras consolidam fornecedor, item, valores, prazos, notas e status. O modulo separa o trabalho de suprimentos da visao financeira ampla, mantendo rastreabilidade para contas a pagar.

**Estado:** implementado e integrado a fornecedores, itens, requisicoes, estoque e financeiro de compras.

### Coletas, entregas e logistica

O ERP ja possui base para rotas de entrega/coleta, paradas, fornecedores, obras e acompanhamento logistico ligado a compras.

**Estado:** modulo em evolucao, ja estruturado para crescer junto com frota, motoristas e controle de entregas.

### Estoque e catalogo de itens

O catalogo padroniza materiais, insumos e unidades. O estoque registra saldos e movimentacoes, permitindo controlar entrada, saida, ajuste, transferencia e consumo vinculado a obra.

**Estado:** implementado, com testes e integracao aos fluxos de compras e movimentacao.

### Fornecedores

Cadastro de fornecedores com dados comerciais e suporte a consulta de CNPJ, apoiando compras, cotacoes e financeiro.

**Estado:** implementado.

### Financeiro

O financeiro centraliza receitas, despesas, contas, transacoes manuais e registros originados por outros modulos. A arquitetura usa origem e referencia para preservar contexto do lancamento.

**Estado:** implementado, com area especifica para compras no financeiro. O DRE gerencial existe e esta no roadmap de refinamento para consolidacao definitiva.

### DRE gerencial e relatorios

Relatorios e DRE ajudam a transformar dados operacionais em leitura de resultado, separando receitas, custos diretos, despesas operacionais e desempenho.

**Estado:** modulo existente, com prioridade declarada para ajuste fino do DRE e confiabilidade dos calculos.

### Recursos Humanos

O RH gerencia colaboradores, cargos, setores, beneficios, historico salarial, equipes e dados funcionais. Informacoes sensiveis podem ser protegidas por permissoes especificas.

**Estado:** implementado, com base pronta para conectar custo real de mao de obra por obra.

### Beneficios

Controle de beneficios, categorias, vinculos com colaboradores e informacoes individuais.

**Estado:** implementado e preparado para uso no futuro aplicativo operacional.

### Equipes

Equipes permitem associar colaboradores, liderancas e estrutura de trabalho aos projetos e rotinas de campo.

**Estado:** implementado.

### Frota e veiculos

Controle de veiculos, dados de cadastro, responsavel, status e base para abastecimento, consumo, custos e historico de uso.

**Estado:** implementado como modulo administrativo, com evolucao natural para abastecimentos, motoristas e fretes internos.

### Geofencing

Geofencing associa obras a areas geograficas validas. Isso permite validar presenca fisica, registros de campo e futuramente horas produtivas por obra.

**Estado:** implementado com Google Maps/geocoding e base para o mobile de campo.

### Permissoes, usuarios e clientes

O ERP possui gestao de usuarios, papeis, permissoes, clientes e acesso ao portal. A proposta e separar claramente colaborador interno, administrador e cliente.

**Estado:** implementado, com refinamento continuo das permissoes no banco e na interface.

### Portal do cliente

Clientes podem acessar uma area propria para acompanhar projetos e informacoes autorizadas. O sistema tambem possui configuracoes para controlar visibilidade de orcamentos, valores e custos.

**Estado:** implementado e conectado ao modelo de clientes/projetos, com evolucao prevista para documentos e visualizacao tecnica.

### Assistentes de IA

O produto ja possui areas de IA separadas por contexto: operacional, recursos humanos, comercial, suprimentos e administrativo. A ideia e que cada assistente ajude o usuario a interpretar dados e tomar decisoes dentro da area permitida.

**Estado:** funcional em desenvolvimento. Para producao, a chamada da IA deve migrar para backend seguro, com rate limit, auditoria, controle de custo e escopo por usuario.

### Configuracoes e assinatura

O sistema inclui configuracoes gerais, controle de workspace, uso da plataforma e base para billing/assinatura.

**Estado:** implementado como infraestrutura administrativa do ERP.

## Fluxo operacional principal

```text
Orcamento comercial aprovado
        |
        v
Projeto / Obra
        |
        v
Medicoes, diario, equipes e geofencing
        |
        v
Requisicao de material ou servico
        |
        v
Cotacao / compra com fornecedor
        |
        v
Entrega, estoque ou consumo direto na obra
        |
        v
Conta a pagar / transacao financeira
        |
        v
DRE, relatorios e indicadores gerenciais
```

## Arquitetura tecnica

| Camada | Tecnologia / abordagem |
| --- | --- |
| Interface | Flutter |
| Plataformas | Web, Android, iOS, Windows, Linux e macOS pela base Flutter |
| Backend | Supabase Postgres + PostgREST |
| Autenticacao | Supabase Auth e OAuth Google |
| Arquivos | Supabase Storage |
| Tempo real | Supabase Realtime quando aplicavel |
| Estado | Provider/ChangeNotifier em modulos legados e Riverpod na orquestracao mais recente |
| Mapas | Google Maps e geocoding |
| Graficos | fl_chart |
| IA | Gemini em desenvolvimento, com roadmap para proxy seguro no backend |
| Banco | Schema versionado por migrations Supabase |
| Testes | `flutter_test` com cobertura de models, services, controllers, viewmodels e widgets |

### Estrutura do repositorio

| Pasta | Responsabilidade |
| --- | --- |
| `lib/screens` | Paginas principais do ERP |
| `lib/widgets` | Componentes e views por modulo |
| `lib/models` | Entidades de dominio e serializacao |
| `lib/controllers` | Estado e regras de tela |
| `lib/ViewModels` e `lib/features` | ViewModels e modulos em migracao para arquitetura mais organizada |
| `lib/services` | Integracao com Supabase e servicos externos |
| `lib/app` | Bootstrap, providers, roteamento e injecao de dependencias |
| `lib/constants` | Permissoes, tokens visuais e constantes de dominio |
| `supabase/migrations` | Evolucao versionada do banco |
| `supabase/functions` | Edge Functions |
| `test` | Testes automatizados |
| `docs` | Auditorias, modelo de dados e documentacao tecnica |

## Seguranca e governanca

O Granith ERP ja possui uma base importante de seguranca:

- Autenticacao com Supabase Auth.
- Separacao entre usuario interno, administrador e cliente.
- Modelo de permissoes por codigo.
- Migrations com baseline de RLS e policies.
- GraphQL desabilitado no Supabase.
- Uso de Edge Function para sincronizacao de estatisticas com validacao de JWT.
- Arquivos sensiveis como `.env.local`, `web/env.js` e `ios/Flutter/Secrets.xcconfig` ignorados pelo Git.
- Auditorias tecnicas documentadas em `docs/`.

Antes de producao publica ampla, os pontos mais importantes sao:

- Mover chamadas Gemini para backend seguro.
- Revisar buckets privados e URLs assinadas para imagens/documentos sensiveis.
- Refinar RLS por permissao e operacao em todos os modulos criticos.
- Configurar assinatura Android de release e identificadores reais do app.
- Adicionar headers de seguranca no hosting web.
- Validar cenarios com usuarios reais: admin, financeiro, comprador, RH, colaborador e cliente.

Esse cuidado nao diminui o produto. Pelo contrario: mostra que o ERP esta sendo tratado como sistema empresarial real, com responsabilidade sobre dados financeiros, operacionais e pessoais.

## Granith Mobile

O mobile e o braco operacional do ERP. Ele nao precisa replicar toda a administracao do sistema web; o foco e coletar dados de campo e dar ao colaborador acesso rapido ao que ele precisa no dia a dia.

Funcoes previstas para o mobile:

| Area | Funcao |
| --- | --- |
| Ponto | Entrada, saida e permanencia vinculada a obra, empresa ou atividade autorizada |
| Geofencing | Validacao de presenca fisica em obras |
| Beneficios | Consulta individual de beneficios |
| Diario de obra | Registro objetivo de campo |
| Frota | Lancamentos futuros de combustivel, quilometragem e notas |
| Produtividade | Historico autorizado de registros individuais |

O ERP tambem considera que nem todo trabalho produtivo acontece dentro de uma cerca. Gerencia, diretoria, coordenacao, engenharia e administrativo podem registrar horas por atividade/projeto com justificativa e aprovacao, mantendo rastreabilidade de custo.

## Como rodar localmente

As chaves de desenvolvimento devem ficar em `.env.local`, que e ignorado pelo Git. Use `.env.example` como base.

```powershell
Copy-Item .env.example .env.local
notepad .env.local
.\scripts\run_dev.ps1 -CheckOnly
.\scripts\run_dev.ps1 -Device chrome
```

O script `scripts/run_dev.ps1` carrega variaveis do `.env.local`, repassa para o Flutter por `--dart-define`, gera `web/env.js` localmente para o Google Maps no navegador e gera `ios/Flutter/Secrets.xcconfig` para builds iOS locais.

### Variaveis principais

| Variavel | Uso |
| --- | --- |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | Chave publica/anon do Supabase |
| `GEMINI_API_KEY` | Chave Gemini usada em desenvolvimento |
| `GEMINI_MODEL` | Modelo Gemini configurado |
| `GOOGLE_MAPS_API_KEY` | Chave Google Maps |
| `GOOGLE_OAUTH_WEB_CLIENT_ID` | Client ID web do OAuth Google |
| `GOOGLE_OAUTH_ANDROID_CLIENT_ID` | Client ID Android |
| `GOOGLE_OAUTH_IOS_CLIENT_ID` | Client ID iOS |
| `GOOGLE_OAUTH_IOS_REVERSED_CLIENT_ID` | URL scheme iOS do Google Sign-In |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Client secret web, apenas local/Supabase |
| `GOOGLE_OAUTH_REDIRECT_URL` | URL local de retorno web |

Nao versionar segredos. O `SUPABASE_PUBLISHABLE_KEY` e publico por natureza, mas deve ser usado sempre com RLS forte. Nunca usar `service_role` no cliente Flutter.

### Credenciais e secrets

Use estes arquivos locais, ambos ignorados pelo Git:

```powershell
Copy-Item .env.example .env.local
Copy-Item supabase/.env.example supabase/.env.local
```

- `.env.local`: variaveis usadas pelo cliente Flutter em desenvolvimento. O script `scripts/run_dev.ps1` carrega apenas as chaves seguras para `--dart-define`.
- `supabase/.env.local`: secrets das Edge Functions, como `SUPABASE_SERVICE_ROLE_KEY`, `GRANITH_MANAGEMENT_API_TOKEN`, `GRANITH_PUSH_DISPATCH_TOKEN` e credenciais Firebase Admin.

Para conferir se estao ignorados:

```powershell
git check-ignore .env.local
git check-ignore supabase/.env.local
git check-ignore web/env.js
git check-ignore ios/Flutter/Secrets.xcconfig
```

Nao use `--dart-define-from-file=.env.local` se o arquivo tiver client secret ou service role. Isso pode embutir segredo no bundle Flutter. Prefira `scripts/run_dev.ps1`.

## CI/CD e Firebase Hosting

O projeto possui workflow GitHub Actions em `.github/workflows/firebase-hosting.yml`.

Comportamento:

| Evento | Acao |
| --- | --- |
| Pull request para `main` | Roda `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build web` |
| Push na `main` | Roda validacao/build e publica no Firebase Hosting live |
| `workflow_dispatch` | Permite disparar deploy manual pelo GitHub Actions |

Secrets necessarios no GitHub:

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

`FIREBASE_SERVICE_ACCOUNT_GRANITH_SKYFORGE` deve conter o JSON completo da service account do Firebase. Ele pode ser gerado pelo Firebase Console em `Project settings > Service accounts`, ou pelo assistente `firebase init hosting:github`.

Nao coloque no GitHub Actions:

```text
SUPABASE_SERVICE_ROLE_KEY
GOOGLE_OAUTH_CLIENT_SECRET
GEMINI_API_KEY
```

Essas chaves nao devem ir para Flutter Web. Se a IA precisar funcionar em producao, ela deve passar por Edge Function/backend seguro.

### Convite do portal do cliente

Atualmente o envio de convite para clientes usa o provedor padrao de e-mail do Supabase Auth, sem SMTP proprio configurado. Isso e suficiente para desenvolvimento, validacao e piloto controlado, mas o remetente pode aparecer como Supabase/Auth e ha limites baixos de envio do provedor padrao. Na pratica, para convites em volume, esse limite pode travar a operacao; a migracao para SMTP proprio deve ser feita antes de uma abertura comercial maior do portal.

O ERP envia o convite do portal pelo fluxo de Magic Link (`signInWithOtp`). Por isso, se quiser melhorar a aparencia do e-mail sem configurar SMTP agora, atualize no painel do Supabase:

```text
Authentication > Emails > Magic Link
```

Use como assunto:

```text
Seu acesso ao Portal do Cliente Granith
```

E cole o HTML versionado em:

```text
supabase/templates/client_portal_magic_link.html
```

Essa configuracao melhora o texto, layout e experiencia do primeiro acesso, mas nao troca o remetente. Para remover o remetente padrao do Supabase no futuro, sera necessario configurar SMTP proprio em `Authentication > SMTP Settings`, preferencialmente com dominio proprio e DNS validado com SPF, DKIM e DMARC.

Quando o portal comecar a enviar convites para muitos clientes no mesmo dia, configurar SMTP proprio passa a ser prioridade operacional. Provedores recomendados: Resend, Brevo, SendGrid, Postmark ou AWS SES. O remetente ideal deve usar dominio proprio, por exemplo `portal@seudominio.com.br`.

Mais detalhes operacionais estao em `docs/client_portal_email_setup.md`.

Para builds Android, use JDK 21. Se necessario:

```powershell
flutter config --jdk-dir="D:\Desenvolvimento\Android Studio\jbr"
```

## Testes e validacao

Comandos recomendados durante evolucao:

```powershell
flutter test
dart analyze
```

A base de testes cobre modelos, services, controllers, viewmodels e widgets de modulos como projetos, orcamentos, compras, estoque, financeiro, RH, portal do cliente, permissoes, veiculos e relatorios.

## Roadmap de evolucao

Prioridades mais importantes para transformar o beta operacional em produto pronto para producao:

1. Finalizar hardening de seguranca para producao.
2. Fazer o DRE consolidar dados financeiros com alta confiabilidade.
3. Migrar IA para backend seguro com auditoria, permissao e controle de custo.
4. Evoluir mobile de campo para ponto, geofencing, diario e beneficios.
5. Amarrar custo real de mao de obra por obra.
6. Refinar logistica de compras, entregas, motoristas e frota.
7. Evoluir portal do cliente com documentos, andamento e visualizacao tecnica.
8. Polir identidade visual, responsividade e experiencia de uso para demonstracao comercial.

## Posicionamento

O Granith ERP e uma base real de produto, nao apenas uma ideia. Ele ja tem amplitude de ERP, profundidade nos modulos principais e arquitetura suficiente para crescer com seguranca.

O melhor discurso comercial hoje e: **um ERP vertical para construtoras em beta avancado, pronto para demonstracao e piloto, com fluxo ponta a ponta ja implementado e roadmap claro para producao.**
