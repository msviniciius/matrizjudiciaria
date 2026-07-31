# Listagem de Clientes Aurora — Design

## Objetivo

Aplicar à listagem `/clients` o mesmo padrão visual e interativo já usado em `/legal_cases`, mantendo as ações e o escopo de clientes existentes.

## Arquitetura

`ClientsController#index` continuará sendo a entrada Rails e fornecerá um snapshot JSON com filtros, metadados, clientes e ações autorizadas. Um entrypoint React específico será montado em `clients#index`; a interface buscará o snapshot sem recarregar a página e preservará o fallback HTML existente.

## Interface

O cabeçalho terá o nome Clientes, unidade/escritório, contador e alternância persistida entre Cartões e Tabela. A barra de filtros terá busca por nome, CPF/CNPJ, telefone ou e-mail, além de status do cadastro e cidade. Os cards e a tabela exibirão nome, status, contatos e quantidade de processos, com links para visualizar/editar e ações de exclusão preservadas.

## Estados e limites

Filtros, busca, retry, loading skeleton, estado vazio e atualização assíncrona seguirão o comportamento de `LegalCasesApp`. A URL será atualizada com os filtros ativos. Não haverá polling, edição inline, alteração das regras de escopo, nem remoção das ações de cliente/processos.

## Acessibilidade e testes

Botões de visualização usam `aria-pressed`, filtros têm labels, estados de carregamento usam `role=status`, erros usam `role=alert`, e foco visível/reduced motion seguem o padrão existente. Testes React cobrirão cartões, tabela, busca/filtros, loading, erro/retry e estado vazio; testes Rails cobrirão snapshot JSON e isolamento por unidade.

