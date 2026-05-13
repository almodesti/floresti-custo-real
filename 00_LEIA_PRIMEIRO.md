# Pacote Custo Real — FLORESTi

**O que é este pacote:** handoff do projeto Custo Real para Eduardo assumir como dono e construtor. André (CEO) vira patrocinador.

**Contexto:** o projeto original (`ESCOPO_ORIGINAL.md` — você já tem) definia 4 fases. Este pacote entrega o design completo da **Fase 1 — MVP com Eucalipto, madeira bruta e adesivo TLP 40**. A implementação fica com você e seu time de tech.

---

## Como ler este pacote (na ordem)

1. **`HANDOFF_EDUARDO.md`** — começa por aqui. Contexto, as 4 decisões-chave do modelo, o que ainda precisa ser levantado, expectativas de prazo, meu compromisso daqui pra frente.

2. **`DIAGRAMA_v3.html`** — duplo clique pra abrir no navegador. Visão do modelo em uma página. Olha antes de entrar na spec.

3. **`SPEC_TECNICA.md`** — para seu dev. Entidades, regras de cálculo, casos de teste, stack-agnóstica. É o documento que ele vai usar pra implementar.

4. **`SEED_PEDIDO_GIANCARLOS.json`** — pedido real extraído da planilha de orçamento 1863. Use como caso de teste do importador.

5. **`NF_71_ADESIVO_TLP40_BIRKA.pdf`** — nota fiscal de referência do adesivo. Exemplo de o que o sistema precisa capturar do lado do adesivo. (Houve mais compras de adesivo entre out/25 e abr/26 — levante as NFs.)

---

## Ordem sugerida de implementação

Se fosse eu começando do zero:

1. **Semana 1:** modelagem das entidades (compra_madeira, compra_adesivo, pedido, item_pedido, leitura_tambor, apontamento_estoque_mensal) e CRUD básico.

2. **Semana 2:** lógica de preço médio móvel (madeira e adesivo). Fácil de testar isoladamente.

3. **Semana 3:** lógica de fator_mes com serragem residual. Roda os casos de teste da seção 3 da spec.

4. **Semana 4:** lógica de taxa kg/m³ do adesivo. Integração com custo total do pedido.

5. **Semana 5:** telas de visualização (margem por pedido, balanço da fábrica, reconciliação). Aqui entra a pegada visual — se quiser manter a identidade FLORESTi, o `DIAGRAMA_v3.html` tem a paleta e tipografia aplicadas.

6. **Semana 6:** importação retroativa dos pedidos de jan-abr/26 + primeiros apontamentos reais.

Total realista: **6-8 semanas** com um dev full-time, ou **10-12 semanas** com ele dividindo com outras coisas. Isso é além do prazo original de 19/06 — discuta com André antes de comprometer.

---

## Perguntas que você precisa responder antes de começar

Do `HANDOFF_EDUARDO.md`, seção "O que precisa ser levantado":

- [ ] Pedidos de MLC Eucalipto entregues entre jan/26 e hoje (cliente, data, valor)
- [ ] Estoque físico hoje (2ª linha, refilo, bruto remanescente)
- [ ] Nível atual do tambor TLP 40
- [ ] NFs de compra de Eucalipto bruto em 2026
- [ ] NFs de compra de adesivo além da NF 71

Do `SPEC_TECNICA.md`, seção 4:

- [ ] Estoque inicial em 01/01/2026 (zero ou estimativa?)
- [ ] Tabela de custos detalhada da planilha é real ou teórica?
- [ ] Subproduto do refilo — modelar agora ou depois?
- [ ] Outras espécies — política quando começar a incluir
- [ ] Múltiplas entregas no mesmo dia — como tratar leitura do tambor

---

## Com quem falar pra cada coisa

- **Decisões de negócio, prazo, orçamento:** André (patrocinador)
- **Dados operacionais, lógica de fábrica:** Eduardo (dono do projeto)
- **Dados financeiros históricos:** você define — o Navis foi tirado da Fase 1, mas pode precisar pra reconciliação de caixa na Fase 2
- **Dados de faturamento:** Lygia (tirada da Fase 1, mas continua sendo fonte)

---

## Como começaram os arquivos deste pacote

Este pacote resulta de uma conversa de design entre André e Claude (sessão de abril/2026). Três iterações do modelo antes da versão final:

- **v1:** apontamento por pedido de "m³ bruto consumido" — descartado porque fisicamente impossível
- **v2:** pool único com 4 destinos + serragem residual — base do modelo final
- **v3:** v2 + fluxo paralelo de adesivo TLP 40 — **modelo final deste pacote**

Se você quiser ver a conversa completa com o raciocínio atrás de cada decisão, peça o link do chat para o André.

---

*FLORESTi Soluções Construtivas · Pacote de handoff · Custo Real v3 · Abril 2026*
