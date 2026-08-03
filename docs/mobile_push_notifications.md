# Notificacoes mobile

O fluxo de notificacoes do Granith usa o banco como fonte de verdade e o FCM
apenas como transporte para acordar o aplicativo.

## Fluxo

1. Uma acao do ERP ou trigger do banco insere uma linha em
   `mobile_push_notifications`.
2. O `pg_cron` chama `dispatch_mobile_push` a cada minuto usando um lease
   descartavel, valido por dois minutos e consumido uma unica vez.
3. A Edge Function reserva as notificacoes com `FOR UPDATE SKIP LOCKED`.
4. Uma entrega e criada em `mobile_push_deliveries` para cada token ativo.
5. Falhas transitorias recebem retry exponencial independente por aparelho.
6. Tokens definitivamente invalidos sao revogados.
7. O Mobile persiste o push no SQLite e sincroniza os dados operacionais.
8. Leitura e exclusao feitas offline entram em uma fila SQLite e sao
   confirmadas no Supabase na primeira conexao disponivel.
9. Ao tocar na notificacao, o app abre o modulo indicado por `actionRoute`.

## Seguranca

- A service account do Firebase existe somente em Supabase Secrets.
- `dispatch_mobile_push` e publicada sem verificacao JWT no gateway para
  permitir a chamada do `pg_cron`.
- A Function nao fica aberta: exige lease descartavel, token interno ou sessao
  de usuario com permissao operacional.
- Destinatarios nao atualizam livremente a linha da notificacao. Leitura e
  dispensa passam por RPCs que validam `auth.uid()` e o vinculo com funcionario.
- A entrega por dispositivo e acessivel somente por `service_role`.

## Ativacao

Depois de atualizar o repositorio:

```powershell
npx supabase db push
npx supabase functions deploy dispatch_mobile_push --no-verify-jwt
```

No SQL Editor do mesmo projeto, configure o job uma unica vez:

```sql
select public.configure_mobile_push_dispatch_cron(
  'https://SEU_PROJECT_REF.supabase.co/functions/v1/dispatch_mobile_push',
  '* * * * *'
);
```

O URL nao contem segredo. Substitua apenas `SEU_PROJECT_REF`.

## Verificacao

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'granith-mobile-push-dispatch';

select id, status, attempts, "nextAttemptAt", "errorMessage", "createdAt"
from public.mobile_push_notifications
order by "createdAt" desc
limit 20;

select
  "notificationId",
  "deviceTokenId",
  status,
  attempts,
  "nextAttemptAt",
  "errorMessage"
from public.mobile_push_deliveries
order by "createdAt" desc
limit 50;
```

No aparelho, valide estes cenarios:

- app aberto: alerta local, persistencia no SQLite e refresh do modulo;
- app em segundo plano: toque abre o modulo correspondente;
- app encerrado: toque restaura a sessao e abre o modulo;
- aparelho offline: leitura/exclusao permanecem locais e sincronizam ao voltar;
- dois aparelhos: cada token possui status e retry independentes.
