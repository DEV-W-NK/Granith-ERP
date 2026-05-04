# Clean Architecture Migration

## Estrutura base criada

```text
lib/
|-- app/
|   |-- app.dart
|   |-- bootstrap.dart
|   |-- auth_wrapper.dart
|   |-- di/
|   |-- initialization/
|   `-- routing/
`-- features/
    |-- auth/
    |   |-- data/
    |   `-- presentation/
    |-- home/
    |   `-- presentation/
    `-- projects/
        |-- data/
        `-- presentation/
```

## Objetivo desta etapa

- Tirar `main.dart` da função de orquestração.
- Concentrar bootstrap, rotas e providers em `app/`.
- Começar a expor módulos pelo caminho `features/<modulo>/...`.
- Manter compatibilidade com os imports antigos para a migração ser gradual.

## Próximos passos recomendados

1. Mover implementações reais de `services`, `controllers` e `ViewModels` para dentro de `features/`.
2. Criar `domain/entities`, `domain/repositories` e `domain/usecases` por módulo.
3. Deixar acesso ao Supabase isolado em `data/`/`services`, sem acesso direto em `presentation`.
4. Esvaziar as pastas legadas quando todos os imports estiverem apontando para `features/`.
