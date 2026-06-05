# FLORESTi — Custo Real

Calculadora de custo real da fábrica MLC Eucalipto. O deploy principal roda em Cloudflare Worker, com API para salvar/carregar os dados no Supabase.

## Como usar

1. Abra `https://floresti-custo-real.modesti.workers.dev/`
2. Aguarde o status **Dados carregados do banco**
3. Use as abas **Painel**, **Compras**, **Pedidos**, **Estoque**, **Margens** e **Balanço**
4. As alterações são salvas automaticamente no banco

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

O sistema salva localmente no navegador e sincroniza automaticamente no banco remoto via Worker API.

- **Exportar**: botão no canto superior direito → salva um arquivo `.json`
- **Importar**: mesmo botão → restaura os dados do `.json` salvo
- **Banco remoto**: o app chama `/api/state`, servido pelo mesmo Cloudflare Worker.
  - execute `database/supabase.sql` no Supabase
  - configure os secrets `SUPABASE_URL`, `SUPABASE_ANON` e `SUPABASE_TOKEN` no Worker
  - o usuário final não precisa preencher token ou configuração
- **GitHub**: usado para versionar o código e manter o espelho GitHub Pages. A gravação de dados do usuário final passa pelo banco remoto/API.

## Deploy

O deploy público principal é o Cloudflare Worker `floresti-custo-real`, que serve os arquivos estáticos e a API segura.
O GitHub Pages permanece como espelho estático via GitHub Actions (`.github/workflows/pages.yml`).

Cloudflare Worker:

https://floresti-custo-real.modesti.workers.dev/

GitHub Pages:

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
