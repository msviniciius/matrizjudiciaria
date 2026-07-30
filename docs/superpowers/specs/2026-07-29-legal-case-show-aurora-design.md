# Detalhe de Processo Aurora — Design

## Objetivo

Transformar `/legal_cases/:id` em uma central de comando React para acompanhamento e decisão, sem permitir edição inline nem alterar os fluxos Rails existentes.

## Arquitetura

`LegalCasesController#show` continua sendo a entrada HTML e também fornece um snapshot JSON protegido pelo mesmo escopo de escritório e unidade usado no carregamento do processo. Um entrypoint React específico é carregado somente em `legal_cases#show`; ele busca o snapshot na abertura e renderiza estados explícitos de carregamento, vazio e falha.

O snapshot contém os dados de leitura já presentes na tela: identificação, estado operacional, alertas, próxima ação, dados essenciais, timeline, prazos, tarefas, perícias e caminhos Rails para cada ação. Não expõe rotas de atualização em linha; o servidor continua sendo a fonte de verdade para permissões e navegação.

## Interface Central de comando

O cabeçalho Aurora mostra cliente, identificadores interno e CNJ, fase, status, saúde e alertas. A próxima ação é o principal bloco de decisão, em modo somente leitura, com atalhos para editar o processo e criar um novo andamento.

A timeline ocupa a coluna principal. Os eventos recentes ficam visíveis de imediato e os anteriores são carregados progressivamente na própria interface. Um painel lateral contextual reúne responsável, próximo prazo, saúde e dados essenciais, além dos atalhos Rails existentes para PDF, calendário, edição e sincronização.

Prazos, tarefas e perícias ficam em acordeões. Cada seção abre automaticamente quando tiver alerta operacional — prazo vencido/próximo, tarefa pendente ou perícia próxima — e permanece acessível por botão em qualquer estado.

## Comportamento e limites

A tela atualiza o snapshot apenas na abertura ou por ação explícita de atualizar; não há polling. Todos os botões levam às telas ou formulários Rails existentes. Sincronização, criação e edição continuam nesses fluxos, sem mutação assíncrona local.

Ficam fora do escopo edição inline, criação dentro da central, sincronização assíncrona local, alterações nas regras de negócio e mudanças nas telas de formulário.

## Acessibilidade e testes

Componentes interativos usam botões com estado ARIA, foco visível e suporte a teclado. A interface respeita `prefers-reduced-motion`. Testes Rails cobrem snapshot e isolamento por unidade; testes React cobrem renderização da central, alertas, acordeões, timeline progressiva e estados vazio/erro.
