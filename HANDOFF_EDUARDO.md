# HANDOFF — Projeto Custo Real

**De:** André
**Para:** Eduardo (dono do projeto a partir de agora)
**Data:** 21 de abril de 2026
**Contexto:** MVP de medição de margem real por pedido de MLC Eucalipto

---

## O que você está recebendo

Este projeto nasceu da pergunta: *"A FLORESTi ganha ou perde dinheiro em cada pedido?"* Hoje, não sabemos responder com dado — só com intuição.

O escopo original (ver `ESCOPO_ORIGINAL.md`) definia 4 fases até 19/06/26. **Este handoff cobre a Fase 1 redefinida:** MVP apenas com Eucalipto, jan–abr/26, custos materiais (madeira bruta + adesivo TLP 40).

Durante o desenho do MVP (conversas com Claude entre abril/26), o modelo passou por três versões. A **v3 é a final** — é o que você e seu time de tech vão implementar. As v1 e v2 ficam registradas apenas pra contexto histórico.

---

## Por que o modelo é assim — as 4 decisões-chave

Antes de ler o modelo de dados, entenda **por que** foi desenhado desse jeito. Sem isso, seu dev vai implementar "corretamente" algo que não resolve o problema.

### Decisão 1: Pool único de matéria-prima, sem alocação por pedido

**Tentamos** um modelo onde cada pedido tinha seu "consumo real de m³ bruto" apontado. Descartamos porque **você não consegue medir isso fisicamente** — madeira bruta entra na fábrica como pool comum e alimenta múltiplos pedidos simultâneos. Pesar quanto bruto foi pro Giancarlos é impossível na prática.

**Consequência:** o custo de madeira de um pedido é **derivado**, não medido. Calculamos por fator de apropriação do período (explicado adiante).

### Decisão 2: Quatro destinos físicos explícitos, serragem como residual

Bruto que entra vira: (a) pedidos 1ª linha, (b) palete de 2ª linha, (c) refilo reaproveitável, (d) bruto remanescente no galpão, (e) serragem — perda total.

Os 4 primeiros têm valor econômico diferente e recuperável. Só a serragem é perda real. O sistema **calcula serragem por subtração** (Σ entradas − Σ 4 destinos) — ninguém pesa serragem.

**Por quê:** você próprio disse que 2ª linha pode virar MLC de 2ª linha vendável, refilo pode virar subproduto (painel, caibro, barrote colado), e bruto remanescente volta pro pool. Agregar isso como "perda" apagaria a informação mais valiosa do sistema.

**Decisão econômica temporária:** 2ª linha e refilo são contabilizados com o **mesmo R$/m³ do bruto** no MVP. Isso é simplificação. Quando vocês decidirem preço de venda da 2ª linha e do subproduto, refinam.

### Decisão 3: Adesivo tratado como matéria-prima paralela

Adesivo TLP 40 entra no sistema com o **mesmo padrão da madeira**: pool único (tambor), preço médio móvel por kg, apropriação por período.

**Leitura do tambor acontece:**
- Obrigatoriamente: a cada entrega de pedido (evento que define a janela de cálculo)
- Opcionalmente: semanal, como conferência (não é input do cálculo, só verificação)

**TLP 10 está fora do MVP** (15% do volume da NF 71). Entra depois. Quando entrar, replica o mesmo padrão com um segundo tambor.

### Decisão 4: Preço médio móvel, não FIFO

**Tentamos** FIFO por lote. Descartamos porque adiciona complexidade de rastreamento sem trazer precisão suficiente pro MVP. Com <15 pedidos e preço relativamente estável no período jan-abr/26, a diferença entre FIFO e preço médio móvel é marginal.

**Se no futuro o preço do Eucalipto oscilar muito entre lotes, reconsiderar.**

---

## O modelo em palavras (sem código)

### Entradas que o sistema captura

**Compras de Eucalipto bruto** — cada nota fiscal ou entrada de serraria: data, fornecedor, m³ bruto, R$ total, larguras dos pacotes, data de pagamento.

**Compras de adesivo TLP 40** — cada nota fiscal de Birka (Elastan): data, kg, R$ total, data de pagamento.

**Pedidos de clientes** — orçamento, cliente, data de entrega, valor de venda da NF, itens (descrição, qtd, base×altura×comprimento em mm → m³ aplainado calculado), data de recebimento do sinal, data de recebimento final.

**Leituras de tambor TLP 40** — cada leitura registra data + kg remanescente. Obrigatório a cada entrega de pedido.

**Apontamentos mensais de estoque físico** — no fim de cada mês, Eduardo estima:
- m³ acumulado em palete de 2ª linha
- m³ acumulado em refilo reaproveitável
- m³ de bruto remanescente no galpão

### Como o sistema calcula

**Preço médio móvel do pool de madeira:**
A cada compra, recalcula: `(Σ R$ pagos até hoje) / (Σ m³ comprados até hoje)`. Esse é o R$/m³ vigente.

**Preço médio móvel do tambor de adesivo:**
Mesma lógica, com kg no lugar de m³.

**Fator de apropriação mês de madeira:**
No fim do mês: `(m³ bruto consumido no mês) / (m³ aplainado entregue no mês)`.
Onde: `bruto consumido = estoque inicial + compras − 2ª linha acumulada − refilo acumulado − bruto remanescente final − serragem`.
Serragem sai automaticamente como residual.

**Taxa kg/m³ de adesivo no período:**
Entre duas leituras de tambor: `(leitura_anterior + compras − leitura_atual) / (m³ aplainado entregue no período)`.

**Custo de um pedido específico:**
```
custo_madeira = R$/m³ do pool × m³ aplainado × fator_mês
custo_adesivo = R$/kg do pool × m³ aplainado × taxa_kg_por_m³
custo_total = custo_madeira + custo_adesivo
margem R$ = valor_venda − custo_total
margem % = margem R$ / valor_venda
```

### O que o sistema mostra

**Margem por pedido** — tabela pedido a pedido, ordenada por data de entrega.

**Balanço da fábrica** — por mês: m³ que entraram, m³ que saíram em cada destino, rendimento MLC 1ª, % serragem, R$ travado em 2ª linha + refilo, taxa kg/m³ de adesivo.

**Reconciliação de caixa** — Σ compras (madeira + adesivo) vs. saídas de caixa pagas. Σ vendas vs. entradas de caixa recebidas. Duas checagens independentes de sanidade contábil.

---

## Decisões de implementação que seu dev precisa tomar

Estas são as escolhas que o contexto dele define. **Não venho com resposta — venho com lista.**

1. **Stack.** Backend + banco? Google Sheets + Apps Script? Excel com macros? Supabase? Qualquer que faça sentido. O modelo acima é stack-agnóstico.

2. **Persistência e backup.** Banco gerenciado? Export diário pra Drive? Versionamento?

3. **Interface.** Web? Desktop? Só planilha com regras? Depende do seu dia a dia com ele.

4. **Multi-usuário.** Só Eduardo opera? André consulta read-only? Vocês dois editam?

5. **Integração com Conta Azul.** O projeto original (ver `ESCOPO_ORIGINAL.md`) previa integração em Momento 2. Para este MVP, decidam se fazem import manual ou API desde o início.

6. **Estoque inicial de 01/01/2026.** Dezembro/25 teve o primeiro pedido de Eucalipto da empresa. Pode ter sobrado palete/refilo/bruto que não está registrado. O modelo assume zero como simplificação — se você tiver estimativa melhor, usa.

---

## O que precisa ser levantado antes de implementar

Dados históricos que André **não tem** e só você sabe (ou alguém da fábrica):

1. **Todos os pedidos de MLC Eucalipto entregues entre jan/26 e hoje.** Número, cliente, data de entrega, valor da NF. O pedido do Giancarlos (orçamento 1863, R$ 154.647,84, entrega 21/04/26) já está no seed como exemplo.

2. **Estoque físico hoje** de 2ª linha Eucalipto, refilo Eucalipto, e bruto Eucalipto remanescente.

3. **Nível atual do tambor TLP 40 em kg.**

4. **Todas as NFs de compra de madeira bruta de Eucalipto em 2026** — tenho a nota do Giancarlos só como pedido, não tenho notas de compra.

5. **Todas as NFs de compra de adesivo em 2026.** Só tenho a NF 71 (Birka, outubro/25) como referência.

---

## O que a planilha de orçamento (exemplo Giancarlos) ensina

O arquivo `SEED_PEDIDO_GIANCARLOS.json` tem o pedido real extraído. Usa como caso de teste: se sua implementação ler esse JSON e produzir valor de venda R$ 154.647,84 e m³ aplainado ~17,11 m³, o importador básico está funcionando.

Alguns dados úteis que estão na planilha original e podem virar constantes do sistema:
- **Tabela de preço de venda por tipo de peça + volume + espécie** — já existe, útil pra validar vendas
- **Tabela de consumo de adesivo por m³ colado** (~0,25 kg/m³ para lamela de 30mm) — pode servir como baseline teórico pra comparar com a taxa real medida
- **Tabela de custos internos** (madeira + tratamento + secagem + ... + prensa = R$ 8.665/m³ aplainado) — **precisa validar se são valores reais medidos ou estimativas teóricas.** Na última reunião com Claude, ficou pendente descobrir isso com você.

---

## Histórico de decisões descartadas

Registrado pra você não reabrir discussões que já aconteceram:

| Idea | Descartada porque |
|---|---|
| Apontamento "m³ bruto por pedido" | Impossível fisicamente — pool comum |
| FIFO por lote | Complexidade > precisão ganha |
| "Entrada = Saída" em R$ como equação única | Mistura reconciliação de caixa com cálculo de margem |
| Fórmula teórica de serragem da plaina como fonte da verdade | Funciona como baseline, não como medição |
| Sistema só analítico sem cadastro | Não tinha de onde puxar os dados |
| localStorage como persistência principal | Não confiável em `file://` no Safari — exporte/importe JSON é mais seguro |
| Incluir mão de obra, energia, frete no MVP | Escopo cresce, 19/06 escorrega |

---

## Expectativa de prazo

O projeto original apontava 19/06/26 como marco de MVP rodando. **Realisticamente, esse prazo precisa ser renegociado** porque:
- Dev terceiro começando do zero
- Você entrando de licença paternidade
- Modelo final mais complexo que o escopo inicial

Minha sugestão: combine com André uma **nova data** antes de começar implementação. Melhor entregar em setembro algo robusto do que em junho algo quebrado.

---

## Meu compromisso daqui pra frente

A partir deste handoff, sou patrocinador — não executor. Isso significa:

- Removo bloqueios que dependam de mim (acesso a dados, autorização financeira pro dev, decisões que só CEO decide)
- Valido entregas em marcos combinados
- **Não opino** em escolhas de stack, schema, interface, que são decisões suas
- **Não reviso** planilhas semanalmente — confio no seu processo

Se eu começar a virar gargalo (você sinaliza), me puxa de volta pro meu papel.

---

*FLORESTi Soluções Construtivas — Projeto Custo Real — Handoff v1 — Abril 2026*
