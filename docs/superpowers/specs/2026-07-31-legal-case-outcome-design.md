# Desfecho do processo na tela Show

## Objetivo

Tornar explícito o momento em que um administrador registra o resultado jurídico de um processo, sem misturar esse evento com o cadastro ou a edição operacional do processo.

## Experiência

A tela Show exibirá um botão destacado **Registrar desfecho** na área de ações do processo. O botão abrirá um modal contextual com:

- resultado: sem definição, ganho, perdido, acordo ou parcialmente ganho;
- data do desfecho;
- observação opcional.

O campo de resultado será removido do formulário geral de edição. Após a confirmação, o Show exibirá o resultado, a data e o usuário responsável pela confirmação. O botão continuará disponível para correção por administradores, apresentando o estado atual no modal.

## Regras

- Somente administradores podem registrar ou alterar o desfecho.
- A confirmação deve usar o escritório atual e o usuário autenticado.
- Resultado **ganho** ativa contas a receber vinculadas ao processo com gatilho `case_won` que estejam aguardando o evento.
- A ativação torna a cobrança pendente; nunca registra pagamento automaticamente.
- Falhas na ativação devem impedir a confirmação do desfecho, mantendo a transação consistente.

## Implementação prevista

- Remover o campo `outcome` do partial do formulário de processo.
- Adicionar botão, modal e estado visual no componente/partial da tela Show.
- Reutilizar a autorização administrativa existente no controller.
- Expor endpoint de atualização do desfecho com parâmetros de resultado, data e observação.
- Preservar a confirmação mais recente (`outcome_confirmed_by` e `outcome_confirmed_at`) e adicionar a observação no modelo se necessário.
- Cobrir autorização, confirmação de ganho, ativação de cobrança e atualização visual.

## Fora de escopo

- Histórico completo de múltiplos desfechos;
- alteração automática de status processual;
- cálculo financeiro automático a partir do valor da causa.
