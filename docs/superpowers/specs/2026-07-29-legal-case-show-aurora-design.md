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

A tela atualiza o snapshot na abertura e após a sincronização explícita de andamentos; não há polling. A sincronização usa `POST` assíncrono com CSRF, exibe um overlay central de glassmorphism enquanto bloqueia interações, informa “Buscando andamentos…” com spinner Aurora, exibe a mensagem retornada pelo servidor e recarrega somente o snapshot do processo. O overlay desaparece em êxito ou falha e respeita `prefers-reduced-motion`. Os demais botões levam às telas ou formulários Rails existentes.

Ficam fora do escopo edição inline, criação dentro da central, polling, alterações nas regras de negócio e mudanças nas telas de formulário.

## Acessibilidade e testes

Componentes interativos usam botões com estado ARIA, foco visível e suporte a teclado. A interface respeita `prefers-reduced-motion`. O overlay de sincronização tem status anunciado, não expõe o spinner como conteúdo redundante e impede ações de fundo enquanto visível. Testes Rails cobrem snapshot e isolamento por unidade; testes React cobrem renderização da central, alertas, acordeões, timeline progressiva, estados vazio/erro e o overlay de sincronização.
