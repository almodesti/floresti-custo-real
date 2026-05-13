# Especificação técnica — Projeto Custo Real

**Público:** desenvolvedor implementando a solução
**Versão do modelo:** v3 (final do design)
**Stack:** agnóstica — decisões de tecnologia ficam com o dev

---

## 1. Entidades e seus campos

Campos marcados com `*` são obrigatórios.

### 1.1 Compra de madeira

```
compra_madeira {
  id*                  identificador único
  data_recebimento*    data ISO (YYYY-MM-DD)
  fornecedor*          string
  nf                   string (número da nota)
  volume_m3*           decimal, m³ brutos recebidos
  larguras_mm          string livre (ex: "160, 180, 200")
  valor_total*         decimal, R$ (soma de todas as parcelas da NF)
  r_m3_calculado       derivado: valor_total / volume_m3
  parcelas_pagamento[] array de { data_vencimento, valor, data_pagamento_efetivo }
}
```

### 1.2 Compra de adesivo

```
compra_adesivo {
  id*
  data_recebimento*
  fornecedor*          ex: "Birka / Martin Oliver Kemmsies"
  nf                   string
  produto*             enum: "TLP_40" | "TLP_10" (MVP usa só TLP_40)
  kg*                  decimal
  valor_total*         decimal, R$
  r_kg_calculado       derivado: valor_total / kg
  parcelas_pagamento[] mesmo formato acima
}
```

### 1.3 Pedido

```
pedido {
  id*
  orcamento*           string (ex: "1863")
  cliente*
  local_obra
  especie*             enum: "Eucalipto" (outras espécies ficam fora do MVP)
  data_entrega         data ISO
  valor_venda*         decimal, R$ (valor da NF total)
  data_sinal_recebido  data ISO
  data_final_recebido  data ISO
  observacoes          texto livre
  itens[]*             ver 1.4
  m3_aplainado         derivado: soma dos itens
}
```

### 1.4 Item de pedido

```
item_pedido {
  descricao*           ex: "Viga MLC 0 a 9m"
  qtd*                 integer
  base_mm*             integer (dimensão da seção)
  altura_mm*           integer (dimensão da seção)
  comprimento_mm*      integer
  m3_item              derivado: qtd × base × altura × comprimento / 1e9
}
```

### 1.5 Leitura de tambor

```
leitura_tambor {
  id*
  data_hora*           timestamp ISO
  produto*             enum: "TLP_40" | "TLP_10"
  kg_remanescente*     decimal
  evento*              enum: "entrega_pedido" | "conferencia_semanal" | "inicial"
  pedido_vinculado     FK para pedido (quando evento = entrega_pedido)
  observacoes
}
```

**Regra:** cada entrega de pedido dispara uma leitura. A leitura semanal é opcional e **não é usada** no cálculo — serve só pra auditoria visual.

### 1.6 Apontamento mensal de estoque

```
apontamento_estoque_mensal {
  id*
  mes_referencia*      "YYYY-MM" (sempre o último dia do mês)
  m3_2a_linha*         decimal
  m3_refilo*           decimal
  m3_bruto_remanescente* decimal
  responsavel*         quem apontou
  data_apontamento*    timestamp
}
```

**Regra:** um apontamento por mês, sempre no último dia. Substituições de apontamento do mesmo mês ficam em histórico (versionado).

### 1.7 Estoque inicial (01/01/2026)

Um registro único, usado como estado inicial do sistema. Pode ser zero ou estimado.

```
estoque_inicial {
  data_referencia      "2026-01-01"
  m3_bruto_pool
  m3_2a_linha
  m3_refilo
  kg_tambor_tlp40
  r_m3_bruto           valor atribuído ao bruto inicial (se houver)
  r_kg_adesivo         valor atribuído ao adesivo inicial (se houver)
}
```

---

## 2. Regras de cálculo

### 2.1 Preço médio móvel do pool de madeira (por data)

```
Para data D:
  compras_ate_D = todas compras_madeira com data_recebimento <= D
  soma_m3 = Σ volume_m3 de compras_ate_D + estoque_inicial.m3_bruto_pool
  soma_rs = Σ valor_total de compras_ate_D + (estoque_inicial.r_m3_bruto × estoque_inicial.m3_bruto_pool)
  preco_m3_pool(D) = soma_rs / soma_m3
```

Mesma lógica para adesivo, com kg no lugar de m³.

### 2.2 Fator de apropriação mês de madeira

Para cada mês M:

```
m3_aplainado_entregue_M = Σ m3_aplainado de pedidos com data_entrega no mês M

apontamento_M = apontamento_estoque_mensal do mês M
apontamento_M_anterior = apontamento_estoque_mensal do mês M-1 (ou estoque_inicial se M = jan/26)

entradas_M = Σ volume_m3 de compras_madeira com data_recebimento no mês M

# Variação de cada destino estocável no mês
var_2a_linha_M = apontamento_M.m3_2a_linha − apontamento_M_anterior.m3_2a_linha
var_refilo_M = apontamento_M.m3_refilo − apontamento_M_anterior.m3_refilo
var_bruto_rem_M = apontamento_M.m3_bruto_remanescente − apontamento_M_anterior.m3_bruto_remanescente

# Consumo físico total
consumo_fisico_M = entradas_M − var_bruto_rem_M

# Serragem = consumo físico − o que virou produto rastreável
serragem_M = consumo_fisico_M − m3_aplainado_entregue_M − var_2a_linha_M − var_refilo_M

# Fator = razão bruto realmente gasto em pedidos / m³ aplainado produzido
# Note: exclui serragem e destinos estocáveis porque não são atribuíveis ao pedido
bruto_atribuido_a_pedidos_M = m3_aplainado_entregue_M + (serragem_M × m3_aplainado_entregue_M / m3_aplainado_entregue_M)
# Na prática simplifica para:
bruto_atribuido_a_pedidos_M = m3_aplainado_entregue_M + serragem_M

fator_mes_M = bruto_atribuido_a_pedidos_M / m3_aplainado_entregue_M
```

**Interpretação do fator:** se 10 m³ entraram pra produzir 6 m³ aplainados em pedidos entregues no mês, e 2 m³ foram pra 2ª linha/refilo (estocáveis, voltam depois como produto) e 2 m³ viraram serragem, o fator do mês é **(6+2)/6 = 1,33**. Só serragem é "atribuída" como perda no custo do pedido, porque 2ª linha e refilo têm valor recuperável.

**Se não houver pedido entregue no mês**, fator_mes_M = null. Pedidos entregues em meses sem fator definido herdam o fator do mês anterior mais próximo.

### 2.3 Taxa kg/m³ de adesivo por período

Período de adesivo = intervalo entre duas leituras de tambor consecutivas com `evento = entrega_pedido`.

```
Para período P (entre leitura L_anterior e leitura L_atual):
  m3_aplainado_periodo_P = Σ m3_aplainado de pedidos entregues entre L_anterior e L_atual
  compras_adesivo_periodo_P = Σ kg de compras_adesivo com data_recebimento no período
  kg_consumidos_P = L_anterior.kg_remanescente + compras_adesivo_periodo_P - L_atual.kg_remanescente
  taxa_kg_por_m3_P = kg_consumidos_P / m3_aplainado_periodo_P
```

### 2.4 Custo de um pedido

```
Para pedido P com data_entrega = D:
  M = mês de D
  periodo_adesivo = período de adesivo que contém D
  
  custo_madeira = preco_m3_pool(D) × pedido.m3_aplainado × fator_mes_M
  custo_adesivo = preco_kg_pool(D) × pedido.m3_aplainado × taxa_kg_por_m3(periodo_adesivo)
  custo_total = custo_madeira + custo_adesivo
  
  margem_rs = pedido.valor_venda − custo_total
  margem_pct = margem_rs / pedido.valor_venda × 100
```

### 2.5 Balanço da fábrica

Para cada mês M, computar e exibir:

- Entradas de madeira bruta em m³ e R$
- Saídas físicas rastreadas (pedidos, variação 2ª linha, variação refilo, variação bruto remanescente)
- Serragem em m³ e % do consumo físico
- Rendimento MLC 1ª linha = m³ aplainado / consumo físico
- Fator do mês
- R$ total travado em estoque 2ª linha + refilo (usando R$/m³ do pool no último dia do mês)
- Entradas de adesivo em kg e R$
- Consumo de adesivo do mês em kg
- Taxa média kg/m³ do mês

### 2.6 Reconciliação de caixa

Duas verificações independentes.

**Compras vs. saídas:**
```
Σ valor_total de todas compras_madeira + compras_adesivo com parcelas_pagamento pagas no período
deveria bater com
Σ saídas de caixa classificadas como "Compra madeira" ou "Compra adesivo" no mesmo período
```

**Vendas vs. entradas:**
```
Σ valores recebidos de pedidos (date_sinal_recebido + data_final_recebido) no período
deveria bater com
Σ entradas de caixa classificadas como "Venda pedido" no mesmo período
```

Diferenças são flagadas para conferência manual. O sistema não tenta reconciliar automaticamente — só aponta divergências.

---

## 3. Casos de teste

### Teste 1: Cálculo de m³ aplainado do pedido Giancarlos

Importar `SEED_PEDIDO_GIANCARLOS.json`. O sistema deve produzir:

- `m3_aplainado = 17,110 m³` (tolerância ±0,01)
- `valor_venda = R$ 154.647,84`
- 14 itens no array de itens

### Teste 2: Consumo de adesivo

Dado:
- Leitura L1: data 2026-04-01, kg_remanescente = 800
- Compra em 2026-04-10: 500 kg
- Leitura L2: data 2026-04-15 (vinculada a pedido X), kg_remanescente = 1.100
- Pedido X entregue em 2026-04-15, m³ aplainado = 5

Esperado:
- `kg_consumidos = 800 + 500 − 1100 = 200 kg`
- `taxa_kg_por_m3 = 200 / 5 = 40 kg/m³`

(Nota: 40 kg/m³ seria absurdo na realidade — a tabela FLORESTi indica ~0,25 kg/m³ para lamela de 30mm. Mas pra teste, verificar se a aritmética fecha.)

### Teste 3: Fator do mês com serragem

Dado para o mês de março/26:
- Estoque inicial (final de fev): 3 m³ bruto, 0 m³ 2ª linha, 0 m³ refilo
- Compras de março: 20 m³
- Apontamento fim de março: 1 m³ bruto remanescente, 2 m³ 2ª linha, 1 m³ refilo
- Pedido P1 entregue em 15/03 com m³ aplainado = 10

Esperado:
- `entradas_mes = 20`
- `var_bruto_rem = 1 − 3 = −2`
- `consumo_fisico = 20 − (−2) = 22`
- `var_2a_linha = 2`
- `var_refilo = 1`
- `serragem = 22 − 10 − 2 − 1 = 9`
- `bruto_atribuido_pedidos = 10 + 9 = 19`
- `fator_mes = 19 / 10 = 1,9`

---

## 4. Decisões que precisam do Eduardo antes de implementar

Estas estão abertas e devem ser resolvidas na primeira reunião Eduardo + dev:

1. **Estoque inicial de 01/01/2026.** Zero ou estimativa? Afeta todos os cálculos retroativos.

2. **Tabela de custos detalhada** da planilha de orçamento (madeira + tratamento + secagem + ... + prensa = R$ 8.665/m³ aplainado). Esses valores são reais medidos, teóricos, ou estimados há muito tempo? Se forem teóricos, **não devem ser usados no sistema** — a fonte de verdade é o preço real pago por m³ no pool.

3. **Subproduto do refilo.** O refilo pode virar painel, caibro, barrote colado. Essas conversões devem ser modeladas agora ou entram numa fase futura?

4. **Tratamento de outras espécies.** MVP só tem Eucalipto. Pinus (reto ou autoclavado) e Pinus 12m+ aparecem na tabela de preços. Como tratar quando começar a incluir?

5. **Política de leitura do tambor quando há múltiplas entregas no mesmo dia.** Uma leitura só ao fim do dia, ou uma por entrega?

---

## 5. O que NÃO precisa ser implementado no MVP

Explicitamente fora de escopo, registrado pra o dev não "adivinhar":

- Cálculo de mão de obra direta (fase 2)
- Rateio de energia elétrica (fase 2)
- Custo de embalagem, frete, impostos (fase 2)
- Depreciação de equipamento (fase 4)
- Custo financeiro do capital de giro (fase 4)
- Previsão de preço de venda / precificação otimizada
- Dashboard BI com drill-down
- Relatórios em PDF
- Integração com Conta Azul (fase 2 — apenas pós-aprovação de pedido)
- Controle de estoque com SKU individualizado por peça

---

*FLORESTi Soluções Construtivas — Spec técnica do Custo Real — v3 final*
