# Módulo financeiro — contas a receber

## Objetivo

Adicionar ao sistema uma visão financeira administrativa para controlar valores a receber do escritório, inicialmente com contas únicas e suporte a pagamentos parciais. O módulo deverá funcionar por escritório/matriz, com filtro opcional por unidade.

## Acesso e isolamento

- Apenas usuários administradores poderão acessar o módulo.
- Toda conta pertence a um escritório (`office_id`).
- A conta pode ter uma unidade (`unit_id`) e deve herdar a unidade do processo quando estiver vinculada a um processo.
- A visão padrão é geral, consolidando matriz e unidades.
- O administrador poderá filtrar por uma unidade específica.

## Painel financeiro

O painel será o ponto de entrada do módulo e usará os últimos 30 dias como período padrão. Deverá oferecer filtros por período, visão geral/unidade, cliente, processo e status.

Indicadores:

- Total previsto.
- Total recebido.
- Saldo em aberto.
- Total vencido.
- Total parcialmente recebido.
- Próximos vencimentos.

Além dos indicadores, haverá gráfico de recebimentos no período e lista de contas recentes/próximas do vencimento.

## Conta a receber

Na primeira versão, cada lançamento representa uma obrigação financeira única:

- `office_id` obrigatório.
- `unit_id` opcional.
- `client_id` opcional.
- `legal_case_id` opcional, recomendado quando a cobrança estiver relacionada a processo.
- Descrição obrigatória.
- Valor total obrigatório.
- Valor recebido, inicialmente zero.
- Data de vencimento opcional.
- Data de recebimento integral opcional.
- Forma de pagamento opcional.
- Observações opcionais.
- Gatilho de cobrança: manual, processo iniciado ou processo ganho.
- Data de ativação do gatilho opcional.
- Status: pendente, parcial, recebido, vencido ou cancelado.

O saldo será calculado como valor total menos valor recebido. O status recebido só poderá ser atribuído quando o valor recebido alcançar o valor total; processo ganho apenas torna a cobrança exigível e nunca registra pagamento automaticamente.

## Resultado jurídico do processo

O resultado será separado do status operacional do processo:

- Sem definição.
- Ganho.
- Perdido.
- Acordo.
- Parcialmente ganho.

O resultado será confirmado manualmente por um administrador, registrando usuário e data da confirmação. A integração TJMA poderá sugerir eventos relacionados, mas não classificará automaticamente o resultado nem ativará pagamento sem confirmação.

## Fluxos principais

### Criar conta

O administrador acessa o financeiro, escolhe o processo ou cliente, informa descrição, valor, vencimento e gatilho. Se um processo for escolhido, cliente e unidade são preenchidos automaticamente e permanecem consistentes com o processo.

### Registrar recebimento

O administrador informa valor, data e forma de pagamento. O sistema atualiza o valor recebido e recalcula saldo/status. Pagamentos parciais permanecem na mesma conta nesta primeira versão.

### Processo ganho

Ao confirmar o resultado `ganho`, contas do processo com gatilho `processo ganho` passam de aguardando gatilho para pendente, com ativação registrada. Nenhuma conta é marcada como recebida automaticamente.

## Evolução planejada

O modelo deve permitir posterior criação de parcelas e histórico de recebimentos sem alterar o vínculo principal da conta. Também poderá receber recibos, relatórios, exportações e integrações bancárias em etapas futuras.

## Verificação e segurança

- Controllers e telas financeiras exigirão `require_admin!`.
- Consultas sempre serão limitadas ao `current_office`.
- Filtros por unidade não poderão atravessar escritórios.
- Valores monetários usarão tipo decimal com precisão e escala definidas na migration.
- Alterações de status e registros de recebimento deverão ser auditáveis.
