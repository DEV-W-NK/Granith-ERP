-- EMQX Serverless supports HTTP actions, not direct PostgreSQL sinks.
-- Telemetry is therefore ingested by a dedicated Edge Function using the
-- service role internally. Keep the old broker database role unable to log in
-- or write so it cannot become an alternate ingestion path.

alter role granith_iot_ingest nologin;

drop policy if exists iot_telemetry_insert_mqtt_bridge on public.iot_telemetry;

revoke insert on public.iot_telemetry from granith_iot_ingest;
revoke usage on schema public from granith_iot_ingest;
