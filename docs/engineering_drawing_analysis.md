# Análise local de plantas

O P2 do Granith Engenharia separa o processamento pesado do aplicativo Flutter.
O worker não possui sessão, chave do Supabase ou acesso direto ao banco.

## Fluxo

```text
Revisão imutável no Storage
  -> Flutter confirma escala e pacote de regras
  -> RPC cria job e registra a confirmação
  -> Flutter baixa e valida o SHA-256
  -> worker local recebe somente caminho temporário e configuração
  -> PDFium extrai texto, objetos e raster
  -> Tesseract executa OCR quando necessário
  -> OpenCV identifica linhas, trajetos e candidatos a símbolo
  -> regras geram sugestões com evidências
  -> Flutter valida o SHA-256 do resultado
  -> JSON é enviado ao Storage privado
  -> RPC persiste páginas e apontamentos
  -> engenheiro aceita ou rejeita cada apontamento
  -> somente apontamento aceito pode gerar RFI, ocorrência ou tarefa
```

## Estrutura no banco

| Responsabilidade | Tabela |
| --- | --- |
| Pacotes versionados | `engineering_rule_packs` |
| Execuções | `engineering_analysis_jobs` |
| Escala confirmada | `engineering_analysis_scales` |
| Extração por página | `engineering_analysis_pages` |
| Apontamentos | `engineering_findings` |
| Solicitações técnicas | `engineering_rfis` |
| Ocorrências | `engineering_occurrences` |
| Ações executáveis | `granith_tasks` |

Os resultados do worker ficam em `engineering-derived` no caminho:

```text
<projectId>/<analysisJobId>/analysis-<sha256>.json
```

## Segurança

- acesso e RLS continuam vinculados à obra;
- o cliente não envia insert/update direto para jobs ou apontamentos;
- criação, conclusão e revisão usam RPCs `security definer` com validação
  explícita da obra;
- a escala precisa existir antes do job;
- o SHA-256 da entrada precisa ser igual ao da revisão;
- pacote, versão e hash precisam corresponder ao job;
- páginas e resultados são append-only;
- ações operacionais exigem `engineering_findings.status = accepted`;
- o worker não recebe credenciais.

## Pacotes ISO/ABNT

Um pacote é imutável depois de criado. Alterações técnicas exigem uma nova
versão. Apenas `isActive` pode ser alterado na mesma versão.

O pacote inicial referencia ABNT NBR 6492, ABNT NBR 10068 e ISO 128, mas contém
somente regras assistivas próprias. O conteúdo integral de normas licenciadas
não deve ser copiado para o repositório.

## Worker Windows

Código:

```text
D:\Projetos\granith_engenharia\worker
```

Build:

```powershell
cd D:\Projetos\granith_engenharia
.\scripts\build_analysis_worker.ps1
```

O protocolo é JSON Lines em stdin/stdout. Os eventos possíveis são `ready`,
`progress`, `result` e `error`.

Para OCR, distribua Tesseract 5 e os modelos `por` e `eng`, ou configure
`TESSERACT_PATH`. PDFs vetoriais continuam sendo analisados sem OCR.

## Implantação

```powershell
cd D:\Projetos\Granith-ERP
npx supabase db push
```

Não existe Edge Function para a análise: o processamento acontece no Windows.
Somente os registros auditáveis são sincronizados com o Supabase.
