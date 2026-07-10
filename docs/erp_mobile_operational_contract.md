# Contrato operacional ERP x Mobile

Este documento define o papel de cada sistema para evitar duplicidade de regra,
sincronizacao parcial e telas que parecem atualizadas mas ainda estao com dados
antigos.

## Principios

- O ERP e a fonte de verdade para cadastro, permissao, obra, equipe, beneficio,
  veiculo, rota planejada, compra, requisicao, medicao e fechamento financeiro.
- O Mobile e a ferramenta operacional de campo: ponto, rota, evidencias,
  checkpoints, tracking, ocorrencias, documentos offline e notificacoes.
- Push notification nao substitui banco. Push apenas acorda o app, grava a
  notificacao local e dispara sincronizacao dos alvos informados no payload.
- Toda escrita sensivel precisa passar por RLS, RPC segura ou Edge Function.
- Toda tela que salva dado no ERP deve atualizar a fonte local imediatamente ou
  depender de stream realtime quando a tabela ja suporta isso.

## Alvos de sincronizacao

| Alvo | Fonte de verdade | Quem escreve | Quem consome | Quando sincronizar |
| --- | --- | --- | --- | --- |
| `auth`, `profile`, `permissions` | ERP/Supabase | ERP e funcoes de usuario interno | Mobile e ERP | Alteracao de permissao, cargo, funcionario ou vinculo usuario-funcionario |
| `projects` | ERP | ERP | Mobile, Portal do Cliente e Financeiro | Coordenador/equipe alterados, obra criada/atualizada, cerca alterada |
| `teams` | ERP | ERP | Mobile | Vinculo de equipe, coordenador ou funcionario alterado |
| `benefits` | ERP | ERP | Mobile e Financeiro | Beneficio vinculado/desvinculado de funcionario |
| `vehicles` | ERP | ERP | Mobile | Veiculo ativo atribuido/removido de funcionario |
| `routes` | ERP planeja, Mobile executa | ERP e Mobile | Mobile, ERP Coletas/Entregas | Rota atribuida, checkpoint, KM real, status ou ocorrencia |
| `requisitions` | ERP | ERP e Mobile quando aprovado para campo | ERP e Mobile | Status de material, aprovacao ou entrega |
| `purchases` | ERP | ERP | ERP e Mobile | Compra entregue ou pendente de recebimento |
| `measurements` | ERP | ERP e Mobile com evidencia | ERP, Mobile e Cliente | Medicao criada, aprovada ou rejeitada |
| `timeClock` | Mobile gera, ERP audita | Mobile | ERP Financeiro e Mobile | Entrada, saida, rejeicao de cerca, ajuste ou fechamento |
| `notifications` | Supabase | ERP Edge Function | Mobile | Qualquer evento operacional para funcionario, coordenador ou equipe |

## Payload minimo de push operacional

```json
{
  "category": "project",
  "actionRoute": "projects",
  "sync": "true",
  "syncTargets": ["workspace", "projects", "teams"],
  "syncReason": "project_assignment_changed",
  "projectId": "<uuid>",
  "employeeId": "<uuid>"
}
```

## Regras de responsabilidade

### ERP

- Validar regra de negocio antes de inserir/atualizar.
- Enfileirar notificacao em `mobile_push_notifications` quando a mudanca deve
  chegar ao campo.
- Usar `syncTargets` especificos para evitar sync completo sem necessidade.
- Expor analises gerenciais e financeiras, inclusive ponto/custo por obra.

### Mobile

- Registrar token FCM e manter o vinculo com usuario/funcionario.
- Persistir notificacoes e fila de sync no SQLite.
- Reprocessar sync pendente com backoff quando o app voltar ao primeiro plano.
- Gravar eventos de campo com estado claro: pendente, sincronizado, falhou.
- Mostrar para o funcionario apenas a operacao e resumo proprio; analise
  gerencial deve ficar no ERP.

## Checklist por nova funcionalidade

- Existe tabela, RLS ou RPC para a escrita?
- Existe migration para todos os campos usados por ERP e Mobile?
- A tela do ERP atualiza lista/stream depois de salvar?
- A mudanca gera push quando precisa acordar o app?
- O push tem `category`, `syncTargets`, `syncReason` e ids de entidade?
- O Mobile salva notificacao e fila local antes de tentar sincronizar?
- O Mobile aguenta ficar offline e reprocessa depois?
- Ha validacao local ou teste focado para o fluxo critico?
