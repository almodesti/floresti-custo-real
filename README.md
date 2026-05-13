# FLORESTi — Custo Real

Calculadora de custo real da fábrica MLC Eucalipto. Sistema single-file HTML — abre direto no browser, sem instalação.

## Como usar

1. Baixe `calc_custo_real.html`
2. Abra no browser (Chrome ou Safari)
3. Aba **Dados** → **Carregar dados 2026**
4. Vá para **Painel** e selecione o período

## O que o sistema calcula

| # | KPI |
|---|-----|
| 01 | Volume de madeira bruta entrado na fábrica |
| 02 | Volume de MLC produzido e faturado |
| 03 | Refilo gerado e estocado |
| 04 | 2ª linha estocada |
| 05 | Serragem e tocos (perda) |
| 06 | Adesivo TLP 40 consumido |
| 07 | Tempo disponível de produção |
| 08 | Rendimento bruto → MLC acabado |
| 09 | Custo real R$/m³ de MLC |

## Como salvar os dados

O sistema não usa banco de dados — ao fechar o browser os dados somem. Para salvar:

- **Exportar**: botão no canto superior direito → salva um arquivo `.json`
- **Importar**: mesmo botão → restaura os dados do `.json` salvo

## Stack

HTML + CSS + JavaScript puro. Sem servidor, sem dependências, sem instalação.
Fontes: Google Fonts (Poppins, Outfit, JetBrains Mono). SheetJS para importar xlsx.

## Pendências conhecidas

- Datas reais de entrega dos 4 pedidos (hoje todos em 21/04 como placeholder)
- Estoque inicial 31/12/2025 (hoje 9,5 m³ estimativa)
- Leituras reais de tambor de adesivo

---
*FLORESTi · Custo Real MVP · mai/2026*
