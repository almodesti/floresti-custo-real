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

O sistema salva localmente no navegador e também pode sincronizar um JSON no GitHub.

- **Exportar**: botão no canto superior direito → salva um arquivo `.json`
- **Importar**: mesmo botão → restaura os dados do `.json` salvo
- **Banco remoto**: aba **Dados** → **Banco de dados remoto**
  - recomendado para usar em vários computadores/celulares
  - execute `database/supabase.sql` no Supabase
  - preencha Supabase URL, anon key e token compartilhado
  - marque **salvar automático** para gravar cada alteração no banco
- **GitHub**: aba **Dados** → **Salvar dados no GitHub**
  - arquivo padrão: `data/custo-real.json`
  - requer um token do GitHub com permissão `Contents: Read and write`

## Deploy

O deploy é feito por GitHub Pages via GitHub Actions (`.github/workflows/pages.yml`).
Após o push na branch `main`, a página deve ficar disponível em:

https://almodesti.github.io/floresti-custo-real/

## Stack

HTML + CSS + JavaScript puro. Sem servidor, sem dependências, sem instalação.
Fontes: Google Fonts (Poppins, Outfit, JetBrains Mono). SheetJS para importar xlsx.

## Pendências conhecidas

- Datas reais de entrega dos 4 pedidos (hoje todos em 21/04 como placeholder)
- Estoque inicial 31/12/2025 (hoje 9,5 m³ estimativa)
- Leituras reais de tambor de adesivo

---
*FLORESTi · Custo Real MVP · mai/2026*
