# Auditoria RLS Supabase

Use este checklist antes de liberar o repositorio, publicar migrations ou mexer
em modulo compartilhado com o app mobile.

## Como rodar

1. Abra o SQL Editor do Supabase.
2. Execute `supabase/sql/rls_audit.sql`.
3. Revise tabelas criticas com `rls_enabled = false`, `policy_count = 0` ou
   grants amplos para `anon`.

## Tabelas criticas para o Granith

- `employees`
- `user_profiles`
- `projects`
- `project_team_members`
- `employee_benefits`
- `vehicle_fleet`
- `purchase_delivery_routes`
- `purchase_delivery_route_stops`
- `purchase_delivery_route_tracking_points`
- `time_clock_afd_events`
- `mobile_device_tokens`
- `mobile_push_notifications`
- `mobile_work_hour_entries`
- `mobile_geofence_events`
- `mobile_geofence_service_events`

## Resultado esperado

- Tabelas operacionais com dados internos devem ter RLS ativa.
- Leitura anonima deve ser excecao, normalmente apenas para superficies publicas.
- Escrita de funcionario/mobile deve ser limitada por usuario autenticado,
  vinculo com funcionario ou RPC/Edge Function.
- Service role pode operar filas e dispatch, mas nao deve estar exposta no app.
- Funcoes SECURITY DEFINER precisam fixar `search_path`.
