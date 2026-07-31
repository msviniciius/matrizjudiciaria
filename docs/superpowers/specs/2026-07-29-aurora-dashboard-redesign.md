# Aurora operacional — redesign do Painel

## Objetivo

Evoluir o Painel React para uma central de comando jurídica mais visual, colorida e interativa, sem comprometer legibilidade, acessibilidade ou prioridade operacional.

## Direção visual

- Tema Aurora operacional: superfícies azul-marinho profundas, gradientes azul/violeta e cartões com mais profundidade visual.
- Cores semânticas: vermelho para risco, amarelo para atenção, verde para itens regularizados e azul para ações/informações.
- A cor nunca será o único sinal: cada estado preserva texto, contagem e rótulo.
- Cabeçalho com saudação, contexto de unidade e cartão de próxima ação.
- KPIs maiores, coloridos e com microanimações sutis de entrada e atualização.

## Interação

- Donut de status, barras de fase e tendência de prazos serão gráficos SVG acessíveis, sem dependência externa.
- Segmentos e KPIs clicáveis abrem um painel lateral contextual, mantendo o Painel visível ao fundo.
- O painel lateral mostra a lista filtrada, a contagem, links para processos e ações rápidas já autorizadas pelo Rails.
- Tooltips exibem rótulo e valor de cada ponto de dados.
- Skeletons e números atualizados usam transições discretas; `prefers-reduced-motion` desativa movimento não essencial.

## Arquitetura

O Rails continua entregando o snapshot JSON e as regras de filtro. O React deriva somente a apresentação do painel lateral a partir de filtros declarados no snapshot, evitando duplicar critérios de risco no navegador. Os gráficos são módulos React focados, que recebem série de rótulos/valores e notificam o contêiner pelo identificador do filtro selecionado.

## Critérios de aceite

- O Painel apresenta a identidade Aurora operacional com contraste adequado.
- KPIs e gráficos têm animações sutis e respeitam redução de movimento.
- Clicar em um KPI ou elemento de gráfico abre e fecha um painel lateral sem navegação integral.
- O painel lateral é navegável por teclado, possui rótulo acessível e mantém foco de forma previsível.
- Nenhuma regra de autorização, escopo de unidade ou cálculo de risco migra para o React.
