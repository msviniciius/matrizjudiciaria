# Integração de prazos jurídicos por expediente

## Objetivo

Evoluir o módulo de prazos existente para que prazos judiciais sejam originados por um expediente e pela ciência do advogado, preservando os fluxos atuais de prazos internos, tarefas, perícias, calendário e integrações PJe/DJMA.

O primeiro resultado verificável será: cadastrar um expediente, dar ciência, calcular automaticamente o prazo em dias úteis e visualizar o resultado no painel atual.

## Decisão arquitetural

Não serão criadas entidades paralelas para `Processo` e `Prazo`. O mapeamento será:

- `LegalCase`: processo já existente;
- `Deadline`: prazo já existente;
- `Expediente`: nova origem jurídica do prazo;
- `Ciencia`: novo registro de ciência expressa ou tácita;
- `Feriado`: calendário de feriados;
- `Suspensao`: períodos de suspensão, como recesso forense.

Prazos manuais continuarão existindo para itens internos. Prazos judiciais vinculados a expediente terão o vencimento calculado pelo sistema e não deverão aceitar edição manual da data final.

## Modelo de dados

### Expediente

Novo modelo vinculado a `LegalCase`, com:

- tipo: intimação, citação, despacho ou sentença;
- descrição;
- data de disponibilização;
- quantidade de dias;
- forma de contagem: úteis ou corridos;
- indicador de prazo em dobro;
- origem da informação, inicialmente manual e futuramente DJMA/PJe;
- referências opcionais ao evento ou publicação de origem.

Um expediente terá no máximo uma ciência e um deadline jurídico.

### Ciencia

Novo modelo vinculado a `Expediente`, com:

- tipo: expressa ou tácita;
- data da ciência;
- usuário responsável, usando `User` quando possível;
- timestamps para auditoria.

### Deadline

Adicionar vínculo opcional com `Expediente` e metadados de cálculo. O registro existente continuará suportando deadlines sem expediente.

O deadline jurídico usará `due_date` como data calculada e manterá compatibilidade com os status atuais. A camada de domínio deverá mapear os estados jurídicos para os estados existentes sem quebrar filtros, prorrogação e conclusão atuais.

### Feriado e Suspensao

Serão entidades próprias para permitir edição futura. O escopo deverá considerar o modelo multi-escritório e, quando necessário, tribunal/comarca. O recesso forense será representado por suspensão, não por lógica fixa no serviço.

## Serviços

### BusinessDaysCalculator

Serviço responsável por:

- verificar se uma data é útil;
- pular fins de semana, feriados e suspensões;
- encontrar o próximo dia útil;
- somar dias úteis;
- calcular dias úteis restantes.

Feriados e suspensões devem ser carregados de forma agrupada por cálculo, sem consultas repetidas para cada data.

### DeadlineCalculator

Recebe um `Deadline` jurídico e recalcula início, vencimento e estado.

Regras:

- sem ciência: permanece aguardando ciência e sem datas calculadas;
- a contagem começa no primeiro dia útil após a ciência;
- dias úteis usam o calendário de feriados e suspensões;
- dias corridos ajustam o vencimento para o próximo dia útil quando necessário;
- prazo em dobro multiplica a quantidade original antes da contagem;
- o cálculo atualiza o `next_deadline_on` do processo.

### Atualização de estado

O estado será recalculado pelo serviço e pelo job diário. A conclusão manual continuará usando o fluxo atual de `quick_update`, evoluindo posteriormente para uma ação específica de cumprimento com protocolo.

O limite de alerta deverá usar a configuração do escritório quando disponível, com fallback de três dias úteis.

## Fluxo de criação

1. Usuário cria um expediente vinculado ao `LegalCase`.
2. O sistema cria ou associa um `Deadline` aguardando ciência.
3. Usuário registra ciência expressa.
4. `DeadlineCalculator` calcula início e vencimento.
5. O prazo aparece na caixa correspondente do painel, no calendário e nos indicadores existentes.
6. O job diário cria ciência tácita após o prazo configurado de leitura, caso não exista ciência expressa.

Em uma etapa posterior, publicações do DJMA e eventos do PJe poderão criar expedientes automaticamente, evitando duplicidade por meio de uma referência externa única.

## Interface e integrações existentes

- O painel atual de deadlines será adaptado para agrupar prazos jurídicos por estado.
- O calendário interno continuará usando `due_date` do `Deadline`.
- O dashboard deverá consultar os estados e datas calculados, sem criar uma segunda fonte de verdade.
- `TaskDeadlineCreator` continuará criando prazos internos e deverá ser ajustado para distinguir deadlines manuais de deadlines originados por expediente.
- A criação automática a partir de movimentos processuais será preservada até que a origem seja convertida para expediente.
- A integração com DJMA/PJe será feita depois do fluxo manual estar validado.

## Job e agendamento

Será criado um job diário no Solid Queue existente para:

- criar ciências tácitas vencidas;
- recalcular deadlines jurídicos em aberto;
- atualizar estados e `next_deadline_on`;
- evitar processamento fora do escopo do escritório.

O job será adicionado ao `config/recurring.yml` respeitando os ambientes atuais.

## Timezone e calendário

O aplicativo deverá definir explicitamente o timezone de negócio antes dos cálculos dependentes de data. Feriados e suspensões serão tratados como datas locais, usando `Date.current` sob o timezone configurado.

O seed inicial deverá incluir feriados nacionais, estaduais do Maranhão, feriados forenses e o recesso de 20/12 a 20/01, com criação idempotente.

## Compatibilidade e segurança

- Não migrar deadlines existentes automaticamente para expedientes sem dados confiáveis.
- Deadlines atuais sem expediente permanecem válidos.
- As consultas devem continuar filtrando por escritório e unidade.
- Criação e ciência devem validar que o processo pertence ao escritório atual.
- Não permitir que um usuário conclua ou altere prazo de outro escritório.

## Testes

O framework atual é Minitest. Devem ser adicionados testes para:

- cálculo atravessando fins de semana, feriados e recesso;
- ciência expressa e tácita;
- dias úteis, corridos e prazo em dobro;
- transições de estado;
- criação de deadline a partir de expediente;
- isolamento por escritório/unidade;
- preservação do comportamento de deadlines manuais existentes.

## Fora desta etapa

- cadastro completo de partes e documentos;
- geração automática de peças;
- agenda completa de audiências;
- módulo financeiro;
- criação automática de expediente a partir de todas as fontes externas;
- envio de e-mails de alerta, caso a rotina ainda não exista.

