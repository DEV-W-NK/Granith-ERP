# Granith ERP - Auditoria e hardening P0

Data: 28/07/2026

## Resultado

Nao ha P0 conhecido aberto no estado local auditado. Os controles abaixo ainda
precisam ser publicados no Supabase e no Firebase para proteger o ambiente de
producao.

| Risco P0 encontrado | Impacto | Correcao aplicada |
| --- | --- | --- |
| RLS generico para qualquer usuario interno | Leitura e alteracao indevida entre modulos | Politicas granulares por permissao para obras, orcamentos, estoque, compras, financeiro, frota e logistica |
| Autocadastro podia enviar um `employeeId` arbitrario | Escalada para cargo/vinculo de outro funcionario | Vinculo definido pelo banco a partir do e-mail autenticado; identidade e autorizacao ficam imutaveis para o proprio usuario |
| Supervisor podia criar equipe em qualquer obra e incluir a si mesmo | Escalada de acesso por vinculo de equipe | Criacao/vinculo de obra exige permissao gerencial; lider mantem apenas membros da equipe ja atribuida |
| Registros de ponto visiveis para todos os internos | Exposicao de CPF e localizacao precisa | Leitura limitada ao proprio funcionario ou a `time_clock.read/manage` |
| Ponto e operacao mobile confiavam em identidade/cerca do cliente | Fraude operacional | Banco vincula `auth.uid()`, recalcula a cerca, valida precisao, obra atribuida e sequencia entrada/saida |
| Motorista podia alterar campos da rota e pontos GPS | Bonus adulterado e perda do historico | Rota limitada ao motorista designado, taxa travada, distancia calculada no banco e tracking append-only |
| Abastecimento mobile confiava em identidade e calculos do cliente | Fraude de hodometro, consumo ou lancamento financeiro | Veiculo autorizado por vinculo, funcionario e placa canonicos, consumo calculado no banco e telemetria protegida |
| Solicitante podia alterar status e aprovacao da propria requisicao | Aprovacao ou compra forjada | Solicitante edita apenas itens/prioridade enquanto pendente; workflow e identidade ficam travados no banco |
| Autor do diario podia trocar coordenador antes da assinatura | Assinatura por pessoa indevida | Obra, autoria e coordenador sao canonicos; assinatura nao pode alterar campos operacionais |
| Campos acumulados do cronometro de tarefas eram editaveis | Horas e desempenho adulterados | Autoria e tempo sao imutaveis por escrita direta; apenas a RPC transacional controla intervalos e fechamento |
| Operacoes offline de campo aceitavam qualquer autenticado | Injecao de operacoes pendentes e payload excessivo | Permissoes especificas, vinculo obra/veiculo, identidade canonica e limites de payload |
| Imagens de projetos em bucket publico | Bypass de RLS por URL publica | Bucket privado, MIME/tamanho limitados e URLs assinadas no Flutter |
| Exclusao fisica de registros de negocio | Perda de rastreabilidade | Arquivamento logico por RPC e bloqueio de `DELETE` autenticado |
| Ausencia de trilha transversal | Alteracoes criticas sem autoria | `audit_events` imutavel com redacao de campos sensiveis |
| Fluxos com varias escritas independentes | Estado parcial em falhas de rede | RPCs transacionais para aprovacao, compra, entrega, cancelamento e rota |
| CORS com origem curinga | Chamadas web por origens nao confiaveis | Allowlist centralizada e `CORS_ALLOWED_ORIGINS` para dominios adicionais |
| Gemini acessivel sem limite distribuido | Consumo indevido da API | Apenas perfis internos ativos e 30 chamadas por usuario a cada 5 minutos |
| Dispatcher FCM liberado para qualquer employee | Uso indevido da fila de push | Admin, token interno ou permissao operacional explicita |
| Convite aceitava redirect HTTP arbitrario | Phishing e desvio do fluxo de ativacao | Redirect limitado a mesma allowlist de origens confiaveis |
| Hosting sem cabecalhos defensivos | Clickjacking e superficie XSS maior | CSP, HSTS, `nosniff`, `DENY`, Referrer e Permissions Policy |
| Actions referenciadas por tags moveis | Risco de cadeia de suprimentos no CI | Actions fixadas por SHA |
| Secrets disponiveis durante pull requests internos | Exfiltracao antes do merge | PR usa placeholders e permissao somente de leitura; secrets existem apenas no deploy da `main` |
| Supabase JS referenciado apenas por `@2` | Codigo diferente entre deploys | Edge Functions fixadas em `2.101.1` |
| Perfil sem permissoes recebia todos os menus | Interface em modo permissivo | Navegacao agora falha fechada e exibe apenas Inicio |
| Secrets aceitos pelo script Flutter | Risco de inclusao acidental no bundle | Script aceita apenas configuracoes publicas do cliente |

## Credenciais

- Nenhum `.env`, keystore, service account ou arquivo de credenciais esta
  rastreado pelo Git.
- A varredura do estado atual e de todo o historico alcancavel nao encontrou
  token Google, Hugging Face, GitHub, JWT ou chave privada real.
- `SUPABASE_PUBLISHABLE_KEY`, IDs OAuth e a chave Google Maps do cliente sao
  identificadores publicos. A seguranca depende de RLS e de restricoes de
  origem/API no Google Cloud.
- `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, client secret OAuth e service
  account Firebase devem existir somente em Supabase Secrets ou GitHub Secrets.

## Ativacao em producao

Aplicar primeiro o banco, depois as Functions e por ultimo o Hosting:

```powershell
npx supabase db push

npx supabase functions deploy gemini_generate
npx supabase functions deploy dispatch_mobile_push --no-verify-jwt
npx supabase functions deploy manage_internal_user
npx supabase functions deploy sync_usage_stats

firebase deploy --only hosting
```

Os dominios Firebase oficiais ja estao permitidos. Para dominio proprio:

```powershell
npx supabase secrets set CORS_ALLOWED_ORIGINS="https://erp.seudominio.com.br"
```

Nao use `--no-verify-jwt` nas demais Functions. `dispatch_mobile_push` e a
excecao: o `pg_cron` usa lease descartavel validado dentro da propria Function.

## Verificacao executada

- Parser PostgreSQL nas duas migrations P0: aprovado.
- `npx supabase db push --dry-run`: aprovado; nenhuma alteracao remota aplicada.
- `deno check` nas quatro Edge Functions: aprovado.
- `flutter analyze` focado nos arquivos alterados: sem erros ou warnings; os
  avisos restantes sao lints informativos preexistentes.
- 35 testes focados de seguranca, navegacao, projetos e compras: aprovados.
- Varredura de credenciais no working tree e no historico Git: sem segredo real.
- Consulta OSV das dependencias Pub travadas e do Supabase JS: sem advisory conhecido.

O teste pgTAP em `supabase/tests/p0_rls_security.sql` deve ser executado contra
uma instancia local ou staging depois das migrations:

```powershell
npx supabase start
npx supabase test db
```

## Riscos posteriores

Estes itens sao importantes, mas nao foram classificados como P0:

- configurar MFA obrigatorio para administradores;
- habilitar alertas nativos de Secret Scanning e Dependabot no GitHub;
- definir retencao e exportacao da trilha `audit_events`;
- revisar periodicamente usuarios sem permissao e tokens FCM inativos;
- testar restauracao de backup em ambiente isolado;
- adicionar Play Integrity/attestation para elevar a resistencia contra GPS
  falso em aparelhos comprometidos; o banco ja recalcula a cerca e nao confia
  na decisao enviada pelo aplicativo;
- calibrar limites do Gemini com dados reais de uso.
