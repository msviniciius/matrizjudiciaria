# Status do módulo financeiro

Atualizado em 1º de agosto de 2026.

## Objetivo

O módulo financeiro trabalha com um contrato de honorários por processo, permitindo:

- honorários fixos;
- percentual adicional opcional;
- percentual calculado sobre o valor da causa ou sobre o valor recebido pelo cliente;
- parcelamento de 1 a 12 parcelas;
- ajuste manual dos valores e vencimentos das parcelas;
- um recebimento integral por parcela;
- comprovante individual por recebimento;
- métodos Pix, dinheiro, cartão de crédito e cartão de débito.

O contrato financeiro é opcional na criação do processo. Quando ainda não existe, a tela apresenta **Definir honorários**.

## Onde funciona

O fluxo principal está no show do processo (`LegalCaseShowApp`):

1. A seção **Honorários do processo** inicia minimizada.
2. **Mostrar detalhes** expande os valores contratados e as parcelas.
3. **Definir honorários** cria o contrato.
4. **Editar honorários** altera o contrato e o cronograma.
5. Cada parcela pendente possui **Registrar recebimento**.
6. O recebimento exige valor integral, data/hora, forma de pagamento e comprovante.

## Modelos

- `FinancialContract`: contrato único por processo.
- `FinancialInstallment`: parcelas do contrato.
- `FinancialPayment`: recebimento único vinculado à parcela.
- Active Storage: documento do contrato e comprovante de cada pagamento.

## Migrations

As migrations do módulo estão em `db/migrate/`:

- criação de contratos financeiros;
- criação de parcelas;
- criação de pagamentos;
- flag `receivables.migrated_to_financial_contract`.

A flag de migração evita dupla contagem: contas legadas só deixam de aparecer quando forem explicitamente marcadas como migradas.

Aplicar no ambiente de execução:

```bash
bin/rails db:migrate
```

## Commits principais

- `b3f50c7` — modelos e migrations financeiras.
- `58c6f29` / `59f8d58` — cálculo e divisão de parcelas.
- `b5e1bae` — fluxo financeiro no show do processo.
- `866f3ea` / `6d6fe0e` — edição manual e preservação de vencimentos.
- `3902ccf` — recebimentos, métodos e comprovantes.
- `2f185c8` / `6bd55e9` / `4b03032` — integração ao painel de contas a receber e migração explícita.
- `d14b217` — nomenclatura de honorários.
- `1cbc59c` — checkbox de percentual opcional assume `false`.
- `64c3613` — seção minimizada e alinhamento do botão de recebimento.

## Verificações

- Testes React do Legal Case Show: **21/21 passando**.
- RuboCop e sintaxe Ruby: aprovados nas áreas alteradas.
- Revisões de código das tarefas financeiras: aprovadas.
- Testes Rails ficaram limitados pela indisponibilidade do PostgreSQL local.

## Pendências conhecidas

- O arquivo `db/schema.rb` possui uma alteração local preexistente e não deve ser incluído automaticamente em commits.
- A suíte frontend completa possui uma falha preexistente no teste de atualização de responsável do Dashboard; os testes do Legal Case Show permanecem passando.
- A flag `migrated_to_financial_contract` deve ser marcada apenas quando uma conta legada tiver sido realmente substituída por um contrato financeiro.

## Retomada do trabalho

Ao continuar este módulo, verificar primeiro:

```bash
git status --short
git log --oneline -15
npm test -- --run app/frontend/legal_case_show/LegalCaseShowApp.test.tsx
```

Não incluir `db/schema.rb` sem revisar a origem da alteração.
