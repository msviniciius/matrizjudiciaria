# Financeiro híbrido por processo

## Objetivo

Evoluir o módulo atual de contas a receber para representar contratos financeiros reais por processo, com honorários fixos, percentual adicional opcional, parcelamento e comprovantes.

## Modelo de domínio

Cada processo poderá ter exatamente um **contrato financeiro**. O contrato terá:

- modalidade padrão de honorário fixo;
- flag `includes_percentage` para habilitar percentual adicional;
- valor fixo;
- percentual adicional, quando habilitado;
- base do percentual: `claim_value` (valor da causa) ou `client_received` (valor recebido pelo cliente);
- valor-base informado manualmente quando a base for valor recebido pelo cliente;
- documento do contrato anexado;
- quantidade de parcelas entre 1 e 12.

O contrato gerará de 1 a 12 **cobranças**. Cada cobrança terá número, vencimento, valor, status e exatamente um recebimento opcional.

Cada **recebimento** terá valor integral da cobrança, data e hora, tipo de pagamento (`pix`, `cash`, `credit_card` ou `debit_card`), usuário responsável e um comprovante anexado.

Não haverá pagamentos parciais, múltiplos recebimentos por parcela, descontos, estornos ou cancelamentos nesta primeira versão.

## Cálculo e parcelamento

O valor total será calculado assim:

- somente fixo: valor fixo;
- fixo + percentual sobre valor da causa: valor fixo + (valor da causa × percentual);
- fixo + percentual sobre valor recebido: valor fixo + (valor recebido pelo cliente × percentual).

Quando a base `client_received` for escolhida, o administrador informará manualmente o valor recebido no Show do processo. O cálculo poderá ser concluído ou recalculado a partir desse valor.

As parcelas serão inicialmente distribuídas igualmente. A última parcela absorverá diferenças de centavos. O usuário poderá ajustar manualmente valores e vencimentos antes de salvar, desde que a soma corresponda ao total do contrato.

## Experiência no Show

O Show do processo terá um painel financeiro com:

1. Configuração do contrato financeiro;
2. Upload e visualização do contrato;
3. Ação para informar o valor recebido pelo cliente quando essa base for usada;
4. Lista de 1 a 12 parcelas, com vencimento, valor e situação;
5. Ação **Registrar recebimento** apenas para parcelas pendentes;
6. Upload e visualização do comprovante da parcela quitada.

Todos os perfis poderão editar o contrato e anexar documentos inicialmente.

## Regras de segurança e consistência

- O contrato pertence ao mesmo escritório e processo do usuário atual.
- Cada processo possui no máximo um contrato financeiro.
- Cada cobrança possui no máximo um recebimento.
- O valor recebido deve ser exatamente o valor da cobrança.
- O comprovante pertence ao recebimento correspondente.
- Alterações financeiras e anexos devem preservar usuário e timestamp de criação/atualização.

## Fora de escopo

- múltiplos contratos por processo;
- pagamentos parciais;
- descontos, estornos e cancelamentos;
- integração bancária;
- cálculo automático do valor recebido pelo cliente;
- histórico de versões do contrato.
