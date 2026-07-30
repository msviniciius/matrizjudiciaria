# Correção final: inert global durante sincronização

## Achado

O overlay de sincronização era renderizado dentro de `#react-legal-case-show-root`, mas os controles da sidebar, navbar e topbar pertencem ao layout Rails fora desse root. Apenas o conteúdo React recebia `inert`, deixando esses controles externos alcançáveis pelo teclado.

## Correção

O layout marca as regiões externas interativas com `data-legal-case-sync-background`. Enquanto `syncPending` é verdadeiro, `LegalCaseShowApp` aplica `inert` somente a essas regiões; o root React e o overlay ficam fora dessa seleção. A função de limpeza do efeito remove somente os atributos que ela adicionou, cobrindo sucesso, erro e desmontagem.

## TDD e verificação

- RED: `npm test -- app/frontend/legal_case_show/LegalCaseShowApp.test.tsx` falhou nas duas novas expectativas de `inert` externo.
- GREEN: o mesmo comando passou com 9 testes.
- `git diff --check` não reportou erros.

## Escopo preservado

Não foram alterados `Gemfile.lock`, nem os hunks locais preexistentes de cabeçalho/atalho em `LegalCaseShowApp.tsx`.
