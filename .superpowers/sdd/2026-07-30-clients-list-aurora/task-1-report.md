# Task 1 — Snapshot JSON de clientes

## Status

Concluída. `GET /clients.json` agora responde o contrato de snapshot por meio de `ClientsSnapshot`, preservando a listagem HTML e o filtro pela unidade ativa.

## Commit

`feat: expose clients listing snapshot`

## RED → GREEN

- RED: adicionada a integração que exige a estrutura do snapshot, o cliente da unidade ativa, sua contagem de processos e a exclusão de cliente de outra unidade. A primeira execução local foi bloqueada antes dos testes por `PG::ConnectionBad` em `127.0.0.1:5432`.
- GREEN: a execução com acesso ao PostgreSQL local concluiu com `9 runs, 40 assertions, 0 failures, 0 errors, 0 skips`.

## Comandos

- `source .env && bin/rails test test/controllers/clients_controller_test.rb` — bloqueado inicialmente pela conexão PostgreSQL indisponível no sandbox.
- `source .env && bin/rails test test/controllers/clients_controller_test.rb` — GREEN, fora do sandbox com acesso ao PostgreSQL local.
- `ruby -c app/presenters/clients_snapshot.rb`
- `ruby -c app/controllers/clients_controller.rb`
- `ruby -c test/controllers/clients_controller_test.rb`
- `git diff --check`

## Preocupações

Nenhuma pendência de implementação. As mudanças locais preexistentes em `Gemfile.lock`, `LegalCaseShowApp.tsx` e `docs/superpowers/plans/` não foram incluídas.
