# PATCH — ARCHITECTURE.md
# Adicione os blocos abaixo nas seções correspondentes do seu ARCHITECTURE.md
# ─────────────────────────────────────────────────────────────────────────────


## ── 1. Seção "Supply Chain — Compras" ────────────────────────────────────────
# Adicione após a descrição atual do purchase_model.dart:

### Expansão: Nota Fiscal de Compras
Campos a adicionar em `purchase_model.dart`:
```dart
String? nfNumber          // número da NF (ex: "000.123.456")
String? nfStoragePath     // path no Supabase Storage (ex: 'invoices/{purchaseId}.pdf')
String? nfDownloadUrl     // URL pública ou signed URL do PDF/imagem
DateTime? nfIssuedAt      // data de emissão da NF
```

- NF é anexada **ao criar o pedido de compra** (não na entrega)
- Upload via `StorageService.uploadFile()` → path salvo em `nfStoragePath`
- `nfDownloadUrl` fica disponível no card da compra para download/visualização
- Campo `nfNumber` é texto livre — sem validação de chave NF-e por ora
- Se o fornecedor não emitir NF no momento, campos ficam `null` e podem ser
  preenchidos posteriormente via edição do pedido


## ── 2. Seção "Regras de negócio" ────────────────────────────────────────────
# Adicione as linhas abaixo na tabela de regras:

| 26 | Compras | NF anexada ao criar o pedido: número (texto) + PDF no Storage | 🔲 |
| 27 | Compras | NF opcional — pedido pode ser criado sem NF e editado depois  | 🔲 |


## ── 3. Seção "Próximos passos" ──────────────────────────────────────────────
# Adicione após o item atual de Compras (ou no final da lista):

11. **Compras — Nota Fiscal** expandir `purchase_model` com `nfNumber` +
    `nfStoragePath` + `nfDownloadUrl` + `nfIssuedAt`; adicionar upload de
    PDF/imagem no formulário de criação de pedido; exibir botão de download
    no card da compra


## ── 4. Seção "Dependências (pubspec.yaml)" ──────────────────────────────────
# Confirme que estas dependências já estão listadas (necessárias para NF):

```yaml
supabase_flutter: ^2.12.0   # storage para PDFs de NF
file_picker: ^8.0.0         # seleção de PDF/imagem no device
```
# Nota: estas já estavam previstas para o módulo de Banco de Talentos,
# então provavelmente já estão no pubspec.yaml ou na lista de pendências.
