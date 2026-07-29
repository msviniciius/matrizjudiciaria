# Listagem de Processos Aurora — Design

## Objetivo

Transformar `/legal_cases` em uma experiência React operacional, com cartões como visão padrão, tabela alternável e busca/filtros assíncronos, sem alterar as regras de negócio existentes.

## Arquitetura

`LegalCasesController#index` continua sendo a entrada HTML e entrega o ponto de montagem React. A mesma ação responde a `GET /legal_cases.json`, usando `LegalCaseQuery` e o escopo da unidade atual para retornar uma representação serializada dos processos, dos filtros aplicados e dos caminhos necessários pela interface.

O novo entrypoint React busca o snapshot JSON ao carregar e sempre que os filtros mudarem. Os parâmetros ativos são escritos em `history.replaceState`, preservando URLs compartilháveis e o comportamento do botão Voltar. A preferência entre cartões e tabela fica em `sessionStorage`; não altera a URL nem o servidor.

## Interface Aurora operacional

O cabeçalho da lista apresenta o total exibido, um campo de busca, o acionador dos filtros avançados e as ações existentes de fechamento diário e novo processo. Os filtros são texto, fase, status, prioridade, responsável e situação do prazo, mantendo exatamente as opções e semântica atuais.

Cartões são a visualização padrão. Cada cartão contém número interno, cliente, área, status, prazo, responsável e último andamento, além de um marcador para eventos CNJ novos. O cartão inteiro aponta para o processo. A cor de destaque prioriza prazo vencido, prazo de hoje/próximos dias e prioridade, sem transformar a cor em única fonte de informação.

O controle segmentado “Cartões / Tabela” troca apenas a apresentação dos mesmos resultados carregados. A tabela mostra as mesmas colunas da implementação atual, para leitura densa e familiar. Nenhuma visualização introduz edição em massa ou altera dados.

## Atualização assíncrona e estados

Alterar um filtro ou enviar a busca dispara uma única requisição JSON com os parâmetros atuais. Enquanto ela está pendente, a lista anterior continua visível com indicador de atualização; respostas antigas são ignoradas para não sobrescrever um filtro mais recente. Limpar filtros carrega a URL-base sem recarga.

No carregamento inicial há um estado de carregamento. Uma resposta vazia usa mensagem orientativa; falhas de rede ou servidor mostram erro recuperável com botão para tentar novamente, preservando os últimos resultados válidos.

## Acessibilidade

Os filtros usam rótulos associados. A alternância de visualização é formada por botões com `aria-pressed`; o total e o estado de atualização usam regiões de status. Cartões são links, portanto podem ser percorridos e acionados por teclado. Contraste, foco visível e redução de movimento seguem o sistema Aurora já aplicado ao painel.

## Testes e limites

Testes Rails verificam que o snapshot JSON respeita a unidade e os filtros. Testes React verificam carregamento, filtro assíncrono, alternância, resultados vazios e recuperação de erro.

Ficam fora deste escopo paginação, ordenação configurável, edição em massa, alteração das regras de consulta e mudanças na página de detalhes do processo.
