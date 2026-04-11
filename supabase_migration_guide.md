# Migracao Firebase Data -> Supabase

## Objetivo

- Manter autenticacao no Firebase Auth.
- Migrar dados e storage para Supabase.
- Fazer o app Flutter enviar o JWT do Firebase para o Supabase.

## Configuracao do app Flutter

Execute o app com:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co ^
  --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICA
```

Opcional para debug do auth:

```bash
--dart-define=USE_FIREBASE_AUTH_EMULATOR=true
```

## Configuracao no Supabase

1. No painel do Supabase, habilite Third-party Auth com Firebase Auth.
2. Informe o `project_id` do Firebase.
3. Garanta que os usuarios tenham o claim `role=authenticated`.

## Claims no Firebase

Foram adicionados:

- `functions/index.js`
- `functions/scripts/backfill_supabase_role_claims.js`

Fluxo recomendado:

1. Deploy das functions.
2. Rodar o backfill para usuarios antigos.
3. Forcar novo `getIdToken(true)` apos login se necessario.

## Tabelas que ja foram preparadas para Supabase no app

- `users`
- `budget_types`
- `budgets`
- `items`
- `job_roles`
- `employees`
- `projects`
- `teams`
- `usage_stats`

## Buckets ja esperados no app

- `project-images`

## Blocos ainda grandes para migrar totalmente

- `financial_transactions`
- `inventory`
- `purchases`
- `suppliers`
- `material_requisitions`
- `daily_logs`
- `storage` de imagens e anexos fora de `project-images`

## Observacao importante

O app agora inicia com Supabase obrigatorio. Sem `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`, a inicializacao falha de forma explicita.
