alter table public.projects
  add column if not exists latitude numeric(10,7);

alter table public.projects
  add column if not exists longitude numeric(10,7);

alter table public.projects
  add column if not exists "geofenceSideMeters" numeric(10,2) not null default 120;

alter table public.projects
  add column if not exists geofence_side_meters numeric(10,2);

create index if not exists idx_projects_geofence_coordinates
  on public.projects (latitude, longitude)
  where latitude is not null and longitude is not null;
