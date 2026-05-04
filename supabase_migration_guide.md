# Migracao Supabase - Granith ERP

## Status atual

- O app Flutter usa Supabase Auth, Postgres/PostgREST Realtime e Supabase Storage.
- Firebase ficou apenas como alvo de Hosting (`firebase.json` + `.firebaserc`).
- Firebase Functions, Firestore, Firebase Auth, Firebase Storage e configuracoes mobile do Firebase foram removidos do runtime do app.
- O seeder grava somente no Supabase.

## Configuracao do app Flutter

Execute o app com:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICA
```

Sem `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`, a inicializacao falha de forma explicita.

## Supabase

1. Configure os provedores usados pelo app em Supabase Auth.
2. Para e-mail/senha ou magic link, habilite o provedor de e-mail.
3. Para Google, configure OAuth diretamente no Supabase Auth.
4. Mantenha tabelas protegidas por RLS e policies; nao confie em validacao feita apenas no cliente.
5. Mantenha o bucket `project-images` no Supabase Storage.

## Seeder

O seeder atual faz `upsert` apenas no Supabase. Em ambiente protegido por RLS, rode seed com usuario admin autorizado ou com ambiente operacional usando service role fora do app cliente. Um usuario comum do app pode ser bloqueado pelas policies.

## Ponto tecnico pendente

Fluxos que alteram varias tabelas em sequencia, como entrega de compra -> financeiro -> estoque -> custo do projeto, ja usam Supabase, mas ainda rodam como chamadas client-side sequenciais. Para integridade forte em producao, mova esses fluxos para RPC/Edge Function com transacao SQL.
