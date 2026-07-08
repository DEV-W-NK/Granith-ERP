alter table public.purchase_delivery_routes
  add column if not exists "encodedPolyline" text not null default '',
  add column if not exists "routeDistanceMeters" integer not null default 0,
  add column if not exists "routeDurationSeconds" integer not null default 0,
  add column if not exists "optimizedStopIds" jsonb not null default '[]'::jsonb;

alter table public.purchase_delivery_route_stops
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists "completedLatitude" double precision,
  add column if not exists "completedLongitude" double precision,
  add column if not exists "completedAccuracyMeters" numeric(10,2),
  add column if not exists "proofPhotoDataUrl" text not null default '',
  add column if not exists "signatureDataUrl" text not null default '',
  add column if not exists "signedByName" text not null default '',
  add column if not exists "occurrenceNotes" text not null default '';

create index if not exists idx_purchase_delivery_routes_driver_today
  on public.purchase_delivery_routes ("driverId", status, "scheduledDate");

create index if not exists idx_purchase_delivery_stops_completed
  on public.purchase_delivery_route_stops ("routeId", status, "completedAt");
