# Granith ERP

Granith ERP e uma plataforma de gestao empresarial para construtoras, obras e contratos. O objetivo do projeto e concentrar em um unico sistema as rotinas operacionais, financeiras e administrativas da empresa: projetos, orcamentos de obra, requisicoes, compras, estoque, financeiro, recursos humanos, frota, geofencing, clientes, permissoes e indicadores gerenciais.

O sistema foi desenhado para uso principal em ambiente web desktop, com suporte responsivo para mobile e tablet. A experiencia mobile completa deve evoluir em conjunto com o aplicativo operacional de campo, principalmente para diario de obra, ponto, geofencing, lancamento de combustivel e registros executados fora do escritorio.

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

   Essa frente depende do mobile. O objetivo e medir quanto tempo cada funcionario permaneceu dentro da cerca de uma obra. Exemplo: funcionarios X, Y e Z passaram determinada quantidade de horas na obra A. Com isso, o ERP deve calcular o total de mao de obra alocado, identificar desvios e mostrar quanto custa para a empresa manter a equipe naquela obra.

3. **Melhorar a identidade visual do projeto**

   A interface atual esta funcional, mas precisa evoluir visualmente. A paleta deve ser mais coerente, pois o contraste entre dourado e azul de fim de tarde nao esta entregando a melhor leitura visual. A meta e elevar a identidade do ERP ao seu apice, com cores, hierarquia, componentes e acabamento visual mais consistentes.

4. **Fazer o DRE voltar a funcionar corretamente**

   O DRE precisa voltar a consolidar os dados financeiros de forma confiavel. Ele deve ler corretamente receitas, custos diretos, despesas operacionais, compras, gastos vinculados a obras e resultado, entregando uma visao gerencial clara sobre o desempenho da empresa.

5. **Estudar visualizacao 3D de plantas no portal do cliente**

   Essa frente e experimental. O objetivo e permitir que o cliente visualize plantas e modelos 3D vinculados a obra pelo portal. A abordagem recomendada e manter o arquivo tecnico original, como DWG ou equivalente, armazenado com seguranca, e gerar uma versao otimizada para visualizacao, como GLB/glTF ou um derivado de viewer CAD/BIM. Unity deve ser considerado somente se a experiencia exigir navegacao imersiva, simulacao, walkthrough ou interacoes avancadas; para simples visualizacao tecnica, um viewer web/Flutter tende a ser mais leve e sustentavel.
