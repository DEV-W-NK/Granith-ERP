# Granith ERP

Granith ERP e uma plataforma de gestao empresarial para construtoras, obras e contratos. O objetivo do projeto e concentrar em um unico sistema as rotinas operacionais, financeiras e administrativas da empresa: projetos, orcamentos de obra, requisicoes, compras, estoque, financeiro, recursos humanos, frota, geofencing, clientes, permissoes e indicadores gerenciais.

O sistema foi desenhado para uso principal em ambiente web desktop, com suporte responsivo para mobile e tablet. A experiencia mobile completa deve evoluir em conjunto com o aplicativo operacional de campo, principalmente para diario de obra, ponto, geofencing, lancamento de combustivel e registros executados fora do escritorio.

O Granith Mobile deve funcionar como o braco operacional do ERP. Ele nao deve tentar replicar toda a complexidade administrativa do sistema web; sua funcao e servir como ferramenta diaria dos colaboradores para registrar ponto, consultar beneficios, acompanhar dados individuais, lancar informacoes de campo e alimentar o ERP com dados operacionais confiaveis.

## Visao Tecnica

O Granith ERP utiliza Flutter como camada de interface e Supabase como backend principal. A aplicacao consome dados em tempo real quando necessario, centraliza regras de negocio em services/controllers e mantem os modulos conectados por referencias de dominio, como `projectId`, `requisitionId`, `purchaseId`, `financialTransactionId` e `referenceId`.

Stack principal:

| Camada | Tecnologia |
| --- | --- |
| Interface | Flutter |
| Plataformas | Web, Android, iOS |
| Backend | Supabase Postgres + PostgREST |
| Autenticacao | Supabase Auth |
| Arquivos | Supabase Storage |
| Tempo real | Supabase Realtime |
| Estado | Riverpod na orquestracao do app e Provider/ChangeNotifier em modulos legados durante migracao |
| Graficos | fl_chart |
| Mapas | Google Maps |
| Banco local de apoio | Modelos Dart e controllers de dominio |

## Ambiente Local De Desenvolvimento

As chaves de desenvolvimento devem ficar em `.env.local`, que e ignorado pelo Git. Use `.env.example` como base:

```powershell
Copy-Item .env.example .env.local
notepad .env.local
.\scripts\run_dev.ps1 -Device chrome
```

O script `scripts/run_dev.ps1` carrega as variaveis abaixo, repassa para o Flutter por `--dart-define`, gera `web/env.js` localmente para o carregamento do Google Maps no navegador e gera `ios/Flutter/Secrets.xcconfig` para builds iOS locais:

| Variavel | Uso |
| --- | --- |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | chave publica/anon do Supabase |
| `GEMINI_API_KEY` | chave Gemini usada somente em desenvolvimento |
| `GEMINI_MODEL` | modelo Gemini, hoje `gemini-2.5-flash` |
| `GOOGLE_MAPS_API_KEY` | chave Google Maps usada em geocoding e mapas |
| `GOOGLE_OAUTH_WEB_CLIENT_ID` | Client ID web do OAuth Google para configurar no Supabase |
| `GOOGLE_OAUTH_ANDROID_CLIENT_ID` | Client ID Android do OAuth Google |
| `GOOGLE_OAUTH_IOS_CLIENT_ID` | Client ID iOS do OAuth Google |
| `GOOGLE_OAUTH_CLIENT_SECRET` | client secret web, somente local e painel Supabase |
| `GOOGLE_OAUTH_REDIRECT_URL` | URL local de retorno autorizada no Google/Supabase |

Tambem existe uma configuracao de exemplo em `.vscode/launch.json`, mas o fluxo recomendado para web/iOS e usar o script acima porque ele cria `web/env.js` e `ios/Flutter/Secrets.xcconfig` sem versionar segredo.

Para configurar Gemini, Maps e OAuth na mesma passada:

1. Preencha `.env.local` com `GEMINI_API_KEY`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_OAUTH_WEB_CLIENT_ID` e `GOOGLE_OAUTH_CLIENT_SECRET`.
2. Rode `.\scripts\run_dev.ps1 -CheckOnly` para validar quais chaves foram encontradas sem abrir o Flutter.
3. Configure no Supabase: Authentication > Providers > Google, usando o `GOOGLE_OAUTH_WEB_CLIENT_ID` e o `GOOGLE_OAUTH_CLIENT_SECRET`.
4. Configure no Google Cloud as URLs autorizadas. Em desenvolvimento web, inclua a origem do Flutter, por exemplo `http://localhost:61886`, e a callback do Supabase indicada no painel do provedor Google.
5. Rode `.\scripts\run_dev.ps1 -Device chrome` para iniciar o ERP com Supabase, Gemini e Maps carregados do mesmo `.env.local`.

Nao envie as chaves de Maps/OAuth pelo chat. Edite o `.env.local` diretamente na maquina ou defina variaveis de ambiente do usuario; o script usa variaveis do sistema quando uma chave nao existir no arquivo.

Exemplo para definir fora do arquivo:

```powershell
[Environment]::SetEnvironmentVariable("GOOGLE_MAPS_API_KEY", "sua-chave", "User")
[Environment]::SetEnvironmentVariable("GOOGLE_OAUTH_WEB_CLIENT_ID", "seu-client-id", "User")
[Environment]::SetEnvironmentVariable("GOOGLE_OAUTH_CLIENT_SECRET", "seu-client-secret", "User")
```

Importante: as variaveis OAuth sao lidas pelo script apenas como checklist local. O client secret nao e enviado por `--dart-define`, nao entra no Flutter e deve ser configurado no painel do Supabase.

Para builds Android, use JDK 21. O `flutter doctor -v` deve apontar para o JBR do Android Studio ou outro JDK 21. Se o terminal usar Java 25 via `JAVA_HOME`, configure o Flutter com:

```powershell
flutter config --jdk-dir="D:\Desenvolvimento\Android Studio\jbr"
```

## Autenticacao OAuth Google

O login com Google usa Supabase Auth. Para funcionar em desenvolvimento e producao, o provedor Google deve estar habilitado no painel do Supabase, com Client ID e Client Secret configurados.

URLs de retorno esperadas:

- ERP web: origem atual da aplicacao, por exemplo `http://localhost:<porta>` em desenvolvimento e o dominio final em producao.
- Granith Mobile: `granithmobile://login-callback/`.

Quando a conta Google tiver o mesmo e-mail de um usuario administrativo ja cadastrado em `users`, o ERP preserva o papel e as permissoes desse perfil pelo fallback de e-mail. Isso evita criar um usuario comum separado apenas porque o `auth.uid()` do Google e diferente do ID semeado no ERP.

## Falhas De Seguranca Conhecidas Em Desenvolvimento

Atencao: o uso atual de chaves pelo cliente Flutter e aceito somente para desenvolvimento. Antes de producao, isso precisa ser corrigido.

- `GEMINI_API_KEY`: nao deve ficar no Flutter Web, app mobile, `.vscode`, `web/env.js`, `--dart-define` de build publico ou qualquer bundle entregue ao usuario. Qualquer pessoa pode extrair a chave do navegador/aplicativo. A correcao obrigatoria e mover chamadas Gemini para backend seguro, preferencialmente Supabase Edge Function ou outro proxy proprio, com autenticacao, rate limit, auditoria, controle de escopo por usuario e bloqueio de operacoes de escrita pela IA.
- `GOOGLE_MAPS_API_KEY`: chave de Maps em navegador/mobile tambem fica exposta. Enquanto estiver no cliente, ela deve ser restrita no Google Cloud por HTTP referrer, package name, SHA-1/SHA-256 e APIs permitidas. Para operacoes sensiveis ou com custo alto, usar backend/proxy e limitar cotas.
- OAuth Google: o `Client Secret` do OAuth fica somente no painel do Supabase/Google Cloud. O `.env.local` pode ser usado apenas como checklist temporario de desenvolvimento, nunca versionado e nunca enviado ao Flutter. Nao colocar client secret no README, `.vscode`, codigo ou build publico. Revisar URLs de callback, dominios autorizados e chaves por ambiente antes de publicar.
- Supabase: `SUPABASE_PUBLISHABLE_KEY` e publica por natureza, mas so e segura com RLS forte. Nunca usar `service_role` no app cliente.
- Arquivos locais com segredo: `.env.local`, `web/env.js` e `ios/Flutter/Secrets.xcconfig` sao ignorados pelo Git. Se uma chave real for colada em arquivo versionado por acidente, considerar a chave comprometida e rotacionar no provedor.

## Granith Mobile

O mobile deve ser simples, rapido e orientado ao uso diario. O foco nao e gestao completa da empresa, mas sim coleta e consulta de dados individuais e operacionais.

Principais funcoes esperadas:

| Area | Funcao |
| --- | --- |
| Ponto | Registrar entrada, saida e permanencia vinculada a obra, empresa ou atividade autorizada |
| Geofencing | Validar presenca fisica em obras quando o cargo exigir deslocamento |
| Beneficios | Permitir que o colaborador consulte beneficios ativos e informacoes individuais |
| Desempenho individual | Exibir dados pessoais de produtividade, registros e historico autorizado |
| Diario de obra | Permitir registros objetivos de campo quando aplicavel |
| Combustivel | Lancar abastecimentos, quilometragem e notas fiscais no futuro modulo de frota |

Nem todo trabalho produtivo acontece dentro da cerca de uma obra. Gerencia, diretoria, coordenacao, engenharia e funcoes administrativas podem estar em cartorio, reunioes, escritorio, fornecedores ou trabalhando em projetos dentro da empresa. Para esses casos, o mobile deve permitir lancamento controlado de horas por atividade ou projeto, sem exigir presenca fisica na obra.

Regras esperadas para horas fora da obra:

- O lancamento deve exigir motivo, projeto/obra vinculada e periodo trabalhado.
- Perfis operacionais comuns continuam sujeitos a geofence quando o trabalho for presencial na obra.
- Perfis de gerencia, diretoria, coordenacao e engenharia podem apontar horas produtivas fora da cerca quando houver permissao.
- Horas lancadas fora da cerca devem ficar rastreaveis para aprovacao, auditoria e custo de mao de obra por obra.
- O ERP deve diferenciar hora validada por geofence, hora lancada manualmente e hora administrativa sem vinculo direto com obra.

## Arquitetura

A estrutura do projeto separa telas, widgets, models, controllers, services e regras auxiliares. O padrao atual prioriza componentes reutilizaveis por modulo e services responsaveis por persistencia no Supabase.

Principais responsabilidades:

| Pasta | Responsabilidade |
| --- | --- |
| `lib/screens` | Entrada visual das paginas do ERP |
| `lib/widgets` | Componentes de UI organizados por modulo |
| `lib/models` | Entidades de dominio e serializacao |
| `lib/controllers` | Estado e regras de tela |
| `lib/services` e `lib/Services` | Integracao com Supabase e servicos externos |
| `lib/app` | Bootstrap, providers e injecao de dependencias |
| `lib/constants` | Codigos, permissoes e constantes de dominio |
| `lib/utils` | Utilitarios, seeder e funcoes de apoio |
| `supabase/migrations` | Evolucao do schema do banco |
| `test` | Testes unitarios e de widgets |

## Modulos Do ERP

### Projetos e Obras

Projetos representam o centro operacional do ERP. Eles conectam orcamentos aprovados, custos realizados, compras, diario de obra, equipes, geofencing, financeiro e indicadores de execucao.

Cada obra deve concentrar informacoes como status, progresso, valores previstos, custos atuais, localizacao, cerca operacional e historico de movimentacoes relacionadas.

### Orcamentos de Obra

Orcamento de obra e o orcamento comercial e contratual do projeto. Ele define escopo, valores, itens previstos, custos estimados, margem e base de comparacao entre previsto e realizado.

Esse modulo nao deve ser confundido com orcamento de compra. O orcamento de obra pertence ao ciclo comercial e ao planejamento do projeto; a compra pertence ao ciclo operacional.

### Requisicoes e Compras

Requisicoes representam demandas internas de materiais ou servicos. O fluxo correto e:

1. O funcionario ou setor solicita o item.
2. Compras monta o orcamento de compra com fornecedor, valor, prazo e observacoes.
3. A coordenacao do setor solicitante aprova ou recusa.
4. Compras consolida a compra com nota fiscal, previsao de entrega e dados finais.
5. O financeiro recebe uma conta a pagar originada por compra.

Compras nao deve acessar todo o financeiro. O vinculo com financeiro acontece por uma transacao com origem de compra, mantendo rastreabilidade sem expor movimentacoes financeiras gerais.

### Financeiro

O financeiro concentra entradas, saidas, contas a pagar, contas a receber, transacoes manuais e transacoes originadas por outros modulos.

As transacoes financeiras usam origem e referencia para rastrear de onde vieram. Exemplos:

| Origem | Uso |
| --- | --- |
| `manual` | Lancamentos administrativos ou operacionais diretos |
| `purchase` | Contas a pagar geradas por compras |
| `budget` | Movimentos vinculados a orcamentos |
| `laborCost` | Custos de mao de obra |
| `materialUsage` | Consumo de materiais |

O DRE deve consolidar essas informacoes para leitura gerencial, separando receitas, custos diretos, despesas operacionais e resultado.

### Estoque e Catalogo de Itens

O catalogo de itens padroniza materiais e insumos usados por compras, requisicoes, estoque e orcamentos. O estoque registra entradas, saidas, ajustes e movimentacoes de materiais.

Esse modulo deve sustentar decisoes como: comprar, consumir saldo existente, transferir ou ajustar inventario.

### Recursos Humanos

O RH gerencia colaboradores, cargos, setores, beneficios, salarios, equipes e informacoes funcionais. O acesso a dados sensiveis, como salario, deve ser controlado por permissao especifica.

O modulo tambem deve se conectar futuramente ao custo real de mao de obra por obra, especialmente quando combinado com ponto mobile e geofencing.

### Frota

O modulo de frota deve controlar cadastro de veiculos, modelo, ano, placa, responsavel, status, abastecimentos, consumo real, custos e historico de uso.

Esses dados permitem comparar consumo esperado com consumo real e avaliar se um veiculo antigo ainda vale a pena para a empresa.

### Motoristas, Rotas e Fretes Internos

O controle de motoristas e fretes internos deve ser tratado como uma evolucao futura da frota. A ideia e permitir que motoristas recebam ou confirmem entregas e coletas vinculadas a obras, fornecedores e materiais.

Entregas acontecem nas obras. Coletas acontecem em fornecedores. O sistema deve registrar a conclusao da entrega ou coleta, quilometragem rodada, veiculo utilizado, motorista responsavel e, quando possivel, sugerir rotas menores para reduzir custo e tempo.

Essa frente deve se conectar a compras, estoque, obras e frota, mas nao faz parte do escopo imediato do mobile inicial.

### Geofencing

O geofencing deve associar obras a areas geograficas validas. A ideia operacional e permitir que registros de campo, ponto e presenca sejam vinculados a obra correta.

A cerca deve ser usada como base para metricas de permanencia, custo de mao de obra, produtividade e divergencias entre planejamento e execucao.

### Clientes e Permissoes

O ERP possui controle de usuarios, clientes, papeis e permissoes. A tela de permissoes deve usar nomes legiveis para usuario final, mantendo codigos internos apenas como referencia tecnica.

Permissoes criticas devem separar acesso por responsabilidade. Exemplos: compras pode ver suas contas originadas por compra, mas nao deve ver todo o financeiro; RH pode gerenciar colaboradores sem necessariamente ver salarios, salvo permissao especifica.

### Portal do Cliente e Visualizacao 3D

O portal do cliente deve evoluir para apresentar documentos, andamento da obra e arquivos tecnicos de forma acessivel. Para plantas e modelos 3D, o ERP deve preservar o arquivo original de engenharia, mas entregar ao cliente uma visualizacao otimizada para navegador ou app.

A direcao tecnica recomendada e converter arquivos CAD/BIM no backend para um formato de visualizacao, em vez de tentar ler DWG diretamente no Flutter. Para visualizacao simples, o formato ideal tende a ser `glTF/GLB`. Para fidelidade tecnica de CAD/BIM, camadas, propriedades e medicoes, o caminho mais robusto e usar um servico especializado de conversao e viewer, como Autodesk Platform Services.

## Fluxo Operacional Principal

```text
Orcamento de obra aprovado
        |
        v
Projeto / Obra
        |
        v
Requisicao de material ou servico
        |
        v
Orcamento de compra feito por Compras
        |
        v
Aprovacao da coordenacao responsavel
        |
        v
Compra consolidada com NF e prazo
        |
        v
Conta a pagar no Financeiro
        |
        v
Entrega, estoque, custo realizado e indicadores
```

## Regras De Dominio Importantes

- Orcamento de obra e diferente de orcamento de compra.
- Compras gera contas a pagar, mas nao precisa acessar todo o financeiro.
- Gastos administrativos, como energia, higiene, escritorio e operacao da empresa, devem ser classificados como despesas operacionais, nao como orcamento de obra.
- Custos vinculados a obra devem carregar `projectId` sempre que forem parte do custo realizado daquele projeto.
- Transacoes financeiras precisam preservar origem e referencia para auditoria.
- Permissoes devem ser legiveis para o usuario, mas tecnicamente rastreaveis por codigos internos.
- Dados sensiveis, como salarios, exigem permissao explicita.

## Dados e Integridade

O banco do ERP deve ser tratado como a fonte real da empresa. Por isso, os modulos precisam manter rastreabilidade entre registros e evitar lancamentos isolados sem contexto.

Exemplos de rastreabilidade esperada:

| Registro | Deve apontar para |
| --- | --- |
| Compra | Requisicao, projeto, fornecedor e financeiro |
| Conta a pagar de compra | Compra, fornecedor e projeto quando aplicavel |
| Abastecimento | Veiculo, funcionario, nota fiscal e financeiro |
| Diario de obra | Projeto, equipe, responsavel e periodo |
| Ponto por geofence | Funcionario, obra, horario e cerca |
| Custo de mao de obra | Funcionario, periodo, obra e origem do apontamento |

## Qualidade e Testes

O projeto possui testes unitarios e testes de widgets para validar models, controllers, services e fluxos principais. A evolucao tecnica deve manter testes nos pontos de maior risco: financeiro, compras, requisicoes, permissoes, RH, frota e integracoes com Supabase.

As entregas devem ser acompanhadas por analise estatica, testes direcionados, validacao dos fluxos criticos, revisao de permissoes por perfil e conferencia das regras de RLS no Supabase.

## O Que Precisamos Fazer Agora

1. **Integrar IA aos modulos do ERP para apoiar tomada de decisao**

   A IA deve trabalhar com contexto real do banco de dados da empresa, mas com acesso limitado por modulo e por permissao. Alem das assistencias especificas por area, deve existir um agente dedicado ao CEO, capaz de resumir o estado da empresa com metricas de orcamentos de obras fechadas, compras realizadas, desempenho operacional, indicadores financeiros, riscos e pontos de atencao.

2. **Criar o modulo de tempo gasto por obra dentro da cerca**

   Essa frente depende do mobile. O objetivo e medir quanto tempo cada funcionario permaneceu dentro da cerca de uma obra. Exemplo: funcionarios X, Y e Z passaram determinada quantidade de horas na obra A. Com isso, o ERP deve calcular o total de mao de obra alocado, identificar desvios e mostrar quanto custa para a empresa manter a equipe naquela obra. Tambem deve existir lancamento controlado de horas fora da cerca para gerencia, diretoria, coordenacao, engenharia e funcoes autorizadas que trabalham para a obra sem estar fisicamente nela.

3. **Melhorar a identidade visual do projeto**

   A interface atual esta funcional, mas precisa evoluir visualmente. A paleta deve ser mais coerente, pois o contraste entre dourado e azul de fim de tarde nao esta entregando a melhor leitura visual. A meta e elevar a identidade do ERP ao seu apice, com cores, hierarquia, componentes e acabamento visual mais consistentes.

4. **Fazer o DRE voltar a funcionar corretamente**

   O DRE precisa voltar a consolidar os dados financeiros de forma confiavel. Ele deve ler corretamente receitas, custos diretos, despesas operacionais, compras, gastos vinculados a obras e resultado, entregando uma visao gerencial clara sobre o desempenho da empresa.

5. **Estudar visualizacao 3D de plantas no portal do cliente**

   Essa frente e experimental. O objetivo e permitir que o cliente visualize plantas e modelos 3D vinculados a obra pelo portal. A abordagem recomendada e manter o arquivo tecnico original, como DWG ou equivalente, armazenado com seguranca, e gerar uma versao otimizada para visualizacao, como GLB/glTF ou um derivado de viewer CAD/BIM. Unity deve ser considerado somente se a experiencia exigir navegacao imersiva, simulacao, walkthrough ou interacoes avancadas; para simples visualizacao tecnica, um viewer web/Flutter tende a ser mais leve e sustentavel.
