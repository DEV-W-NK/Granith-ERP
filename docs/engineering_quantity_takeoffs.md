# Quantitativos de engenharia

O P3 do Granith Engenharia transforma uma análise de planta concluída e
revisada em um levantamento quantitativo rastreável.

## Fluxo

1. O usuário escolhe uma análise com status `completed`.
2. O Supabase fixa o perfil de cálculo, sua versão e seu SHA-256.
3. O Flutter baixa o JSON privado da análise e valida seu hash.
4. O worker local executa o comando `quantify`, sem receber credenciais.
5. O resultado é enviado ao bucket privado `engineering-derived`.
6. A RPC valida origem, perfil, hash e formato antes de persistir.
7. Cada grupo exige aceitação ou descarte e associação ao catálogo do ERP.
8. Somente um quantitativo integralmente revisado pode gerar requisição ou
   orçamento.

## Memória de cálculo

`engineering_quantity_elements` mantém a parcela individual de cada página:

- chave determinística do elemento;
- origem vetorial ou OpenCV;
- índice no resultado da página;
- geometria normalizada;
- quantidade bruta e ajustada;
- fórmula e parâmetros;
- evidências do detector.

`engineering_quantity_items` consolida os elementos por classificação. O banco
recalcula a quantidade ajustada durante a revisão:

```text
comprimento =
  bruto * (1 + perda / 100)
  + curvas * adicional_por_curva
  + conexões * adicional_por_conexão

contagem, área e volume =
  bruto * (1 + perda / 100)
```

## Catálogo e estoque

A view `engineering_catalog_items` lê o catálogo canônico `public.items` e
associa o saldo de `public.inventory` pelo nome normalizado. Itens aceitos
precisam apontar para um registro real do catálogo.

Valores ficam em `engineering_quantity_item_costs`, cuja policy permite leitura
somente a `administrator`. O engenheiro funcionário recebe quantidades,
especificações e saldo, mas não recebe preço unitário.

## Saídas operacionais

`generate_requisition_from_engineering_takeoff` cria uma
`material_requisitions` pendente, vinculada à obra e ao funcionário solicitante.

`generate_budget_from_engineering_takeoff` exige perfil administrativo e preço
positivo para todos os itens aceitos, então cria um `budgets` pendente. As RPCs
são idempotentes por quantitativo e devolvem o documento já criado em uma
segunda chamada.

## Segurança

- tabelas operacionais são somente leitura para clientes autenticados;
- alterações passam por RPCs `security definer` com validação explícita;
- resultados derivados são privados e imutáveis após persistência;
- perfil, análise e resultado são vinculados por SHA-256;
- orçamento e requisição só aceitam quantitativos aprovados;
- eventos são registrados pela auditoria da engenharia.
