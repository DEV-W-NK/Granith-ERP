-- Granith Engenharia: calibrated worker options and immutable rule pack v1.1.

alter table public.engineering_rule_packs
  drop constraint if exists engineering_rule_packs_code_key;

alter table public.engineering_rule_packs
  add column if not exists "analysisOptions" jsonb not null default '{}'::jsonb;

alter table public.engineering_rule_packs
  drop constraint if exists engineering_rule_pack_analysis_options_object;
alter table public.engineering_rule_packs
  add constraint engineering_rule_pack_analysis_options_object
  check (jsonb_typeof("analysisOptions") = 'object');

create or replace function private.prepare_engineering_rule_pack()
returns trigger
language plpgsql
security definer
set search_path = public, private, extensions, pg_temp
as $$
declare
  canonical_payload text;
begin
  canonical_payload := jsonb_build_object(
    'code', new.code,
    'version', new.version,
    'title', new.title,
    'authority', new.authority,
    'references', to_jsonb(new."references"),
    'disciplines', to_jsonb(new.disciplines),
    'rules', new.rules,
    'analysisOptions', new."analysisOptions"
  )::text;

  if tg_op = 'INSERT' then
    new."createdByUserId" := coalesce(
      nullif(new."createdByUserId", ''),
      (select auth.uid())::text,
      'migration'
    );
    new."contentSha256" := encode(digest(canonical_payload, 'sha256'), 'hex');
    return new;
  end if;

  if (
    new.code,
    new.version,
    new.title,
    new.description,
    new.authority,
    new."references",
    new.disciplines,
    new.rules,
    new."analysisOptions",
    new."contentSha256",
    new."createdByUserId",
    new."createdAt"
  ) is distinct from (
    old.code,
    old.version,
    old.title,
    old.description,
    old.authority,
    old."references",
    old.disciplines,
    old.rules,
    old."analysisOptions",
    old."contentSha256",
    old."createdByUserId",
    old."createdAt"
  ) then
    raise exception using
      errcode = '55000',
      message = 'Rule packs are immutable. Create a new version.';
  end if;

  return new;
end;
$$;

revoke all on function private.prepare_engineering_rule_pack()
  from public, anon, authenticated;

insert into public.engineering_rule_packs (
  id,
  code,
  version,
  title,
  description,
  authority,
  "references",
  disciplines,
  rules,
  "analysisOptions",
  "createdByUserId"
)
values (
  'granith-abnt-iso-base-v1-1',
  'GRANITH_ABNT_ISO_BASE',
  '1.1.0',
  'Representacao tecnica - base assistiva calibrada',
  'Regras calibradas em corpus publico versionado. Exigem revisao profissional.',
  'Granith',
  array['ABNT NBR 6492', 'ABNT NBR 10068', 'ISO 128'],
  array['Geral', 'Arquitetura', 'Eletrica', 'Hidraulica', 'Mecanica'],
  '[
    {
      "code": "DOC-SCALE-001",
      "kind": "declared_scale",
      "category": "document_control",
      "severity": "high",
      "title": "Escala da prancha",
      "allowSecondaryScales": true,
      "suggestedAction": "Confirmar carimbo, formato da folha e escala principal; escalas secundarias sao preservadas como evidencia."
    },
    {
      "code": "DOC-REV-001",
      "kind": "required_text",
      "category": "document_control",
      "severity": "medium",
      "title": "Identificacao de revisao nao localizada",
      "termGroups": [[
        "REVISAO",
        "REVISOES",
        "REV.",
        "REV",
        "QUADRO DE REVISOES",
        "EMISSAO INICIAL"
      ]],
      "suggestedAction": "Conferir a identificacao e o historico de revisoes no carimbo."
    },
    {
      "code": "DOC-RESP-001",
      "kind": "required_text",
      "category": "document_control",
      "severity": "medium",
      "title": "Responsabilidade tecnica nao localizada",
      "termGroups": [[
        "RESPONSAVEL TECNICO",
        "RESP. TECNICO",
        "RESP TECNICO",
        "RESP. TEC.",
        "RESP TEC",
        "AUTOR DO PROJETO",
        "PROJETISTA",
        "R.T.",
        "RT"
      ]],
      "suggestedAction": "Conferir responsavel tecnico, registro e assinatura aplicaveis."
    },
    {
      "code": "GEO-CONT-001",
      "kind": "line_continuity",
      "category": "geometry",
      "severity": "medium",
      "title": "Possivel trajeto interrompido",
      "endpointTolerance": 0.0045,
      "minimumNormalizedLength": 0.055,
      "maxFindingsPerPage": 3,
      "suggestedAction": "Inspecionar o ponto final no papel vegetal e validar se pertence a um trajeto tecnico."
    },
    {
      "code": "SYM-LEG-001",
      "kind": "symbol_legend",
      "category": "symbols",
      "severity": "low",
      "title": "Legenda nao localizada",
      "scope": "document",
      "minimumSymbols": 12,
      "legendTerms": [
        "LEGENDA",
        "SIMBOLOGIA",
        "QUADRO DE LEGENDAS",
        "LEGENDA DAS INDICACOES"
      ],
      "suggestedAction": "Validar se todos os simbolos utilizados estao documentados no conjunto."
    },
    {
      "code": "OCR-QUAL-001",
      "kind": "ocr_quality",
      "category": "ocr",
      "severity": "medium",
      "title": "OCR requer conferencia",
      "minimumAverageConfidence": 0.62,
      "suggestedAction": "Disponibilizar OCR portugues e ingles ou usar arquivo vetorial/digitalizacao de maior qualidade."
    }
  ]'::jsonb,
  '{
    "minimumVectorCharacters": 24,
    "minimumTextQuality": 0.72,
    "maskExtractedText": true,
    "maskTextPaddingNormalized": 0.0008,
    "maxLineSegmentsPerPage": 8000,
    "maxSymbolCandidatesPerPage": 2500
  }'::jsonb,
  'migration'
)
on conflict (code, version) do nothing;

update public.engineering_rule_packs
set "isActive" = (version = '1.1.0')
where code = 'GRANITH_ABNT_ISO_BASE';
