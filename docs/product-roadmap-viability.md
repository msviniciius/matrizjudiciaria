# Roadmap de Produto e Viabilidade

Data: 2026-08-03

Este documento organiza os principais pontos que faltam para o sistema evoluir de uma gestão operacional jurídica para uma plataforma mais competitiva de controladoria, automação e inteligência jurídica.

## Critérios de Avaliação

- Valor para o usuário: impacto direto na rotina do escritório.
- Diferencial de mercado: capacidade de vender melhor ou competir com legaltechs atuais.
- Esforço técnico: complexidade de implementação e manutenção.
- Dependências externas: APIs, dados oficiais, serviços pagos ou infraestrutura.
- Risco: chance de inconsistência jurídica, custo operacional ou fragilidade técnica.

## 1. Monitoramento Oficial por OAB e Processo

Descrição:
Consolidar busca automática de publicações e andamentos em fontes oficiais, começando por DJEN/CNJ, DataJud e tribunais prioritários.

Valor:
Muito alto. Reduz risco operacional e substitui conferência manual diária.

Diferencial:
Alto. Monitoramento confiável é uma das dores centrais de escritórios.

Estado atual:
- DataJud/CNJ já possui job de sincronização de andamentos.
- Publicações já possuem modelo, listagem e notificações.
- Coletor DJMA atual é MVP e depende de página pública.
- Variáveis `DJEN_API_BASE_URL` e `DJMA_PUBLICATIONS_URL` já existem.

Viabilidade:
Alta para DJEN/CNJ, porque há API pública com filtros por OAB, UF, processo e data.
Média para fontes específicas de tribunais, pois cada tribunal pode ter formato próprio.

Riscos:
- Mudança de layout ou indisponibilidade de páginas públicas.
- Duplicidade entre DJEN, DJMA e Escavador.
- Interpretação incorreta de publicações sem processo vinculado.

Próximos passos:
1. Criar cliente DJEN oficial.
2. Buscar por `numeroOab`, `ufOab`, `siglaTribunal`, período e `meio`.
3. Normalizar resposta para `LegalPublication`.
4. Deduplicar por fonte, ID oficial, processo e conteúdo.
5. Registrar link oficial e texto completo.

Prioridade recomendada:
P0.

## 2. Motor de Prazos Inteligente

Descrição:
Ao receber andamento ou publicação, sugerir prazo, data inicial, vencimento, responsável e tarefa vinculada.

Valor:
Muito alto. Prazos são um dos maiores riscos jurídicos e operacionais.

Diferencial:
Muito alto. Um sistema que sugere prazo a partir da publicação tem valor percebido forte.

Estado atual:
- O sistema já possui prazos, tarefas, configurações de prazo e notificações.
- Alguns andamentos já criam tarefas/prazos por automação interna.
- Ainda não há interpretação jurídica robusta de publicações.

Viabilidade:
Média-alta para regras determinísticas simples.
Média para interpretação automática com IA, pois exige validação humana.

Riscos:
- Erro na contagem de prazo.
- Feriados locais/nacionais.
- Regras processuais variam por área, tribunal e tipo de ato.
- Responsabilidade jurídica se o sistema afirmar prazo como certeza.

Próximos passos:
1. Começar com sugestões, não criação automática definitiva.
2. Criar status: `sugerido`, `confirmado`, `descartado`.
3. Adicionar calendário de feriados.
4. Mapear tipos comuns: intimação, sentença, despacho, audiência, perícia.
5. Exigir confirmação humana antes de ativar prazo crítico.

Prioridade recomendada:
P0, logo após DJEN.

## 3. Central de Inteligência do Processo

Descrição:
Gerar visão executiva do processo com resumo, últimos eventos, riscos, pendências e próxima providência sugerida.

Valor:
Alto. Reduz tempo de leitura e ajuda o advogado a agir mais rápido.

Diferencial:
Alto. O mercado está vendendo cada vez mais IA jurídica aplicada à rotina prática.

Estado atual:
- O detalhe do processo já tem timeline, dados financeiros, andamentos e ações.
- Falta uma camada de síntese.

Viabilidade:
Alta para resumo determinístico baseado em dados internos.
Média para IA generativa, pois depende de custo, privacidade e qualidade dos dados.

Riscos:
- Alucinação se usar IA sem fontes claras.
- Dados sensíveis.
- Custo por uso.
- Necessidade de auditoria da resposta.

Próximos passos:
1. Criar painel "Resumo executivo" no detalhe do processo.
2. Primeiro gerar resumo sem IA, usando dados estruturados.
3. Depois adicionar IA com resposta citando eventos/fontes usados.
4. Salvar histórico do resumo gerado e data.

Prioridade recomendada:
P1.

## 4. WhatsApp Operacional

Descrição:
Enviar alertas por WhatsApp para administradores e, depois, responsáveis por processo, quando houver novo processo, publicação, andamento, pagamento ou prazo crítico.

Valor:
Alto. O canal tem alta taxa de leitura e reduz dependência de o usuário entrar no sistema.

Diferencial:
Médio-alto. Muitos sistemas notificam por e-mail; WhatsApp bem integrado é mais acionável.

Estado atual:
- Campo de WhatsApp foi planejado/adicionado para usuários.
- Integração Twilio foi discutida.
- A estratégia inicial aprovada foi notificar admins primeiro.

Viabilidade:
Alta tecnicamente.
Média operacionalmente, por depender de templates, custo e política do WhatsApp/Twilio.

Riscos:
- Custo por mensagem.
- Templates precisam ser aprovados.
- Dados sensíveis em mensagem.
- Consentimento do usuário.

Próximos passos:
1. Persistir histórico de notificações enviadas.
2. Criar serviço único `WhatsAppNotifier`.
3. Usar templates por evento.
4. Enviar apenas resumo e link para o sistema.
5. Configurar opt-in por usuário.

Prioridade recomendada:
P1.

## 5. Portal do Cliente

Descrição:
Permitir que clientes acompanhem processos, documentos, pagamentos e mensagens em uma área própria.

Valor:
Alto para percepção comercial e redução de atendimento manual.

Diferencial:
Alto para escritórios que atendem muitos clientes pessoa física.

Estado atual:
- Clientes e processos já existem.
- Não há autenticação/área externa de cliente.

Viabilidade:
Média. Exige autenticação separada, permissões, UX própria e controle de dados.

Riscos:
- Exposição indevida de dados.
- Cliente visualizar informação interna/estratégica.
- Suporte e gestão de acesso.

Próximos passos:
1. Definir o que o cliente pode ver.
2. Criar autenticação separada ou token mágico.
3. Mostrar apenas movimentações públicas/selecionadas.
4. Permitir envio de documentos.
5. Notificar cliente por WhatsApp/e-mail quando houver atualização liberada.

Prioridade recomendada:
P2.

## 6. Documentos, OCR e IA Jurídica

Descrição:
Adicionar gestão documental por processo, com OCR, classificação, busca e geração de minutas/resumos.

Valor:
Alto em escritórios com volume documental.

Diferencial:
Muito alto se combinado com IA e resumo processual.

Estado atual:
- Active Storage existe no projeto.
- Ainda não há módulo documental robusto por processo.

Viabilidade:
Média.

Riscos:
- Custo de OCR e IA.
- Armazenamento.
- LGPD e segurança de documentos.
- Qualidade baixa de PDFs digitalizados.

Próximos passos:
1. Criar aba de documentos no processo.
2. Classificar documentos manualmente no início.
3. Adicionar OCR assíncrono.
4. Criar busca textual.
5. Depois avaliar busca semântica e IA.

Prioridade recomendada:
P2.

## 7. Indicadores de Gestão e Controladoria

Descrição:
Evoluir o painel para indicadores de produtividade, gargalos, risco, financeiro e desempenho por responsável/unidade.

Valor:
Alto para administradores e escritórios em crescimento.

Diferencial:
Médio-alto. Ajuda a vender o sistema como ferramenta de gestão, não só cadastro.

Estado atual:
- Dashboard já existe com KPIs e listas operacionais.
- Financeiro e unidades já existem.

Viabilidade:
Alta.

Riscos:
- Métricas ruins levam a decisões ruins.
- Precisa padronizar uso do sistema para dados fazerem sentido.

Próximos passos:
1. Definir KPIs principais.
2. Criar visão por período, unidade e responsável.
3. Medir prazos vencidos, tempo em fase, processos sem responsável, processos sem próxima ação.
4. Adicionar financeiro: previsto, recebido, atrasado.

Prioridade recomendada:
P1.

## Ordem Recomendada de Execução

1. P0 - DJEN/CNJ oficial por OAB e processo.
2. P0 - Motor de prazos sugeridos a partir de publicações/andamentos.
3. P1 - Notificações operacionais por WhatsApp.
4. P1 - Resumo executivo do processo.
5. P1 - Indicadores de controladoria.
6. P2 - Portal do cliente.
7. P2 - Documentos, OCR e IA jurídica.

## Estratégia de Produto

Posicionamento atual:
ERP jurídico operacional para escritórios.

Posicionamento desejado:
Assistente de controladoria jurídica com monitoramento oficial, prazos inteligentes, notificações automáticas e visão executiva do processo.

Mensagem comercial possível:
"O sistema monitora processos e publicações, sugere providências, alerta responsáveis e organiza a rotina jurídica em um painel de controladoria."

## Decisão Recomendada

Começar pela frente de maior valor e menor dependência comercial: DJEN/CNJ oficial.

Motivo:
- Resolve dor diária.
- Usa fonte oficial.
- Alimenta notificações.
- Alimenta motor de prazos.
- Alimenta resumo executivo.
- Reduz dependência de serviços pagos como Escavador.

Primeiro épico sugerido:
`feature/djen-publications`

Objetivo:
Importar publicações oficiais do DJEN por OAB/UF e período, salvar em `LegalPublication`, vincular ao processo quando possível e mostrar no sino de notificações.
