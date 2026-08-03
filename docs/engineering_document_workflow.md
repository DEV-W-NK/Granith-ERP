# Documentação técnica do Granith Engenharia

## Escopo

O módulo de engenharia usa o Supabase como fonte de verdade para documentos,
revisões, anotações, decisões, assinaturas e publicações. O arquivo original e
o PDF assinado ficam em buckets privados diferentes.

| Conteúdo | Destino |
| --- | --- |
| PDF original | `engineering-documents` |
| PDF assinado | `engineering-derived` |
| Metadados e SHA-256 | `engineering_document_revisions` |
| Anotações por página | `engineering_annotations` |
| Decisões | `engineering_document_review_events` |
| Assinaturas | `engineering_signature_requests` |
| Publicações | `engineering_client_document_publications` |

## Fluxo

```text
Upload PDF
  -> validação PDFium
  -> SHA-256 e quantidade de páginas
  -> revisão draft imutável
  -> underReview
  -> approved | rejected | revisionRequested
  -> assinatura PAdES, quando obrigatória
  -> publicação explícita
  -> client_portal_engineering_documents
  -> URL privada com validade de 10 minutos
```

Revisões não recebem `UPDATE` ou `DELETE` direto do cliente. As transições usam
as RPCs `submit_engineering_revision`, `review_engineering_revision`,
`request_engineering_signature`, `publish_engineering_revision` e
`unpublish_engineering_revision`.

## PAdES e ICP-Brasil

O executável Windows não recebe certificado A1/A3, PIN ou chave privada. A Edge
Function `engineering_pades` entrega uma URL temporária do original ao provedor
e recebe o PDF assinado por webhook autenticado.

Políticas configuradas:

- `PAdES-AD-RB`, OID `2.16.76.1.7.1.11.1.3`;
- `PAdES-AD-RT`, OID `2.16.76.1.7.1.12.1.3`.

O contrato HTTP enviado ao provedor contém `requestId`, `sourceUrl`,
`callbackUrl`, `policy`, `policyOid` e `fileName`. O callback deve usar:

```http
POST /functions/v1/engineering_pades
x-granith-pades-token: <PADES_WEBHOOK_SECRET>
Content-Type: application/json
```

```json
{
  "action": "callback",
  "requestId": "uuid",
  "signedPdfUrl": "https://provedor/resultado/uuid.pdf",
  "certificate": {
    "subject": "CN=...",
    "serial": "...",
    "issuer": "CN=...",
    "validFrom": "2026-01-01T00:00:00Z",
    "validTo": "2027-01-01T00:00:00Z"
  }
}
```

Para arquivos pequenos, o provedor também pode enviar `signedPdfBase64`. A URL
é aceita somente por HTTPS e quando sua origem coincide com
`PADES_PROVIDER_URL` ou com o secret opcional
`PADES_ALLOWED_DOWNLOAD_ORIGIN`.

O backend valida tamanho, cabeçalho PDF e calcula um novo SHA-256 antes de
registrar a assinatura como concluída.

## Deploy

```powershell
npx supabase db push
npx supabase secrets set PADES_PROVIDER_URL="https://provedor/assinar"
npx supabase secrets set PADES_PROVIDER_TOKEN="TOKEN"
npx supabase secrets set PADES_WEBHOOK_SECRET="SEGREDO_ALEATORIO"
npx supabase functions deploy engineering_pades --no-verify-jwt
```

O provedor é obrigatório para produzir uma assinatura criptográfica real. Sem
ele, a solicitação permanece na fila e a publicação de documentos que exigem
assinatura continua bloqueada.
