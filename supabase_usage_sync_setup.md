# Sincronizacao Segura de Uso do Supabase

Esta estrutura foi preparada para sincronizar snapshots de uso do Supabase sem expor segredos no Flutter.

## O que foi criado

- Edge Function: `supabase/functions/sync_usage_stats/index.ts`
- Tabela/colunas auxiliares em `usage_stats`
- Funcoes SQL:
  - `public.get_database_usage_mb()`
  - `public.get_storage_usage_mb()`
- Painel no ERP para leitura e sincronizacao manual por admin

## Segredos que voce precisa inserir

No ambiente de Edge Functions do Supabase, configure:

- `GRANITH_MANAGEMENT_API_TOKEN`
- `GRANITH_PROJECT_REF` (opcional, se quiser fixar; o sistema tenta inferir pela URL)

Observacao:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

normalmente ja existem no ambiente da Edge Function do Supabase.

## Como aplicar

1. Execute o SQL novo em `supabase_schema.sql`.
2. Configure os segredos da Edge Function:

```bash
supabase secrets set GRANITH_MANAGEMENT_API_TOKEN=seu_token_seguro
supabase secrets set GRANITH_PROJECT_REF=SUPABASE_PROJECT_REF_REMOVED
```

3. Faça o deploy da função:

```bash
supabase functions deploy sync_usage_stats
```

## Permissao para sincronizar

A Edge Function valida o usuario autenticado e so permite sync se:

- `users.role = 'admin'`

ou se `users.permissions` contiver um destes valores:

- `billing.manage`
- `infra.sync_usage`
- `settings.manage`

## O que a funcao sincroniza hoje

- contagem de requests por servico via Management API:
  - REST
  - Auth
  - Storage
  - Realtime
- tamanho observado do banco via RPC SQL
- tamanho observado do storage via RPC SQL
- serie diaria agregada para o dashboard

Se as funcoes SQL auxiliares ainda nao tiverem sido aplicadas no banco, a sincronizacao continua funcionando com dados parciais. Nesse caso, o painel mostra atividade geral, mas deixa banco e arquivos como indisponiveis ate a migration ser aplicada.

## Limites importantes

Este fluxo melhora muito a observabilidade do projeto, mas ainda nao substitui sozinho:

- compute oficial
- egress oficial
- MAU
- overages de organizacao
- faturamento oficial do Supabase

Para decisoes financeiras finais, continue cruzando com o dashboard oficial de Usage/Billing do Supabase.
