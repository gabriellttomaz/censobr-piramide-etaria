# Roteiro da apresentação — {censobr}

**Duração-alvo:** 18–20 min + perguntas · **Formato:** slides (`slides.qmd`) + R aberto para demo
**Divisão sugerida:** 4 pessoas (A, B, C, D). Com 3, junte C e D.

> Princípio: o professor conhece o autor e o pacote. Ele não quer ver que sabemos *usar* —
> quer ver que entendemos **por que o pacote é desenhado assim** (Parquet, Arrow, cache,
> padrão geobr) e **o que o dado significa** (amostra, peso, universo). Cada bloco abaixo
> tem uma "frase-chave": é a ideia que precisa ficar na cabeça dele.

---

## Bloco 1 — Abertura e problema (A · 2 min) · slides 1–3

- Título, nomes do grupo.
- **O problema:** o Censo é a base mais importante do país, mas usar os microdados do IBGE é
  difícil: arquivos de largura fixa, um por UF, dicionário em Excel, scripts de SAS/SPSS,
  arquivo de pessoas de 2010 com 20,6 milhões de linhas.
- **Pergunta que guia o trabalho:** *como a estrutura etária do Brasil mudou entre 2010 e 2022?*
- Frase-chave: **"O censobr reduz horas de preparação a uma linha de código."**

## Bloco 2 — O pacote (A · 3 min) · slides 4–6

- Autores: **Rafael H. M. Pereira** (mantenedor) e **Rogério J. Barbosa**, Ipea. Versão **1.0.0**
  (21/09/2026). Mesmo autor do {geobr}.
- Cobertura: censos de **1960 a 2022** — microdados, setores censitários e documentação.
- Arquitetura (desenhar o fluxo no slide):
  `IBGE (bruto)` → processamento pelos autores → **Parquet** no GitHub Releases
  (`ipea/censobr_prep_data`) → `read_*()` baixa uma vez → **cache local** → **Arrow** → dplyr.
- Frase-chave: **"Os dados chegam prontos, colunares e com a geografia no padrão do geobr."**

## Bloco 3 — As funções (B · 4 min) · slides 7–9

- Tabela das 5 funções de microdados com os anos (decorar: famílias 2000/2022,
  mortalidade 2010/2022, emigração só 2010).
- `read_tracts()` — universo, por setor, 2000/2010/2022, `dataset` obrigatório.
- Documentação: `data_dictionary()`, `questionnaire()`, `interview_manual()`.
- Cache: `censobr_cache()`, `get_/set_censobr_cache_dir()`. Suporte: `import_microdata22()`.
- Mostrar os argumentos comuns: `year`, `columns`, `add_labels = "pt"`, `as_data_frame`,
  `merge_households`, `cache`.
- Frase-chave: **"Todas as `read_*` têm a mesma interface — aprendeu uma, aprendeu todas."**

## Bloco 4 — Dois conceitos que fazem tudo funcionar (B ou C · 3 min) · slides 10–11

1. **Larger-than-memory.** `read_population()` não carrega nada: devolve um objeto Arrow.
   O dplyr monta um plano *lazy*; só o `collect()` executa e traz o resultado (38 linhas).
   Detalhe de quem leu o código: `columns` não reduz o download (o Parquet vem inteiro, 822 MB),
   reduz a leitura e a memória.
2. **Amostra e peso.** Os microdados são do questionário da amostra. Cada linha representa
   `V0010` pessoas. `n()` = 20,6 mi (amostra); `sum(V0010)` = **190.755.799** (população).
- Frase-chave: **"Sem o peso, a pirâmide estaria errada."**

## Bloco 5 — O código da pirâmide (C · 5 min) · slides 12–14 + DEMO

- Mostrar `R/01_piramide_2010.R` em três partes:
  1. Leitura com `columns` (4 variáveis).
  2. `calcular_piramide()`: grupos de 5 anos com `floor(V6036 / 5) * 5`, 90+, soma dos pesos,
     `collect()`, proporções.
  3. `plotar_piramide()`: o truque do valor negativo para os homens.
- **Demo ao vivo (opcional, ~1 min):** rodar `calcular_piramide(pop, uf = "AM")` —
  em segundos agrega milhões de linhas. Só faça se os dados já estiverem no cache.
  **Plano B:** os PNGs estão em `output/`.
- Frase-chave: **"Toda a agregação roda fora do R; só a tabela final entra na memória."**

## Bloco 6 — Resultados (D · 3 min) · slides 15–17

- Pirâmide 2010: base já se estreitando (0–4 menor que 10–14) → queda da fecundidade.
- AM × RS: duas fases da transição demográfica no mesmo país.
- 2010 × 2022: base encolhe, topo alarga.
  65+ foi de **7,4% para 11,0%**; índice de envelhecimento de **30,7 para 55,5** idosos por 100 jovens.
- Frase-chave: **"Em 12 anos o Brasil quase dobrou o número de idosos por jovem."**

## Bloco 7 — Limitações, 2022 e fechamento (D · 2 min) · slides 18–20

- 2022: microdados completos são **controlados** pelo IBGE; o pacote avisa e usa a versão
  pública (idade em grupos). Com o zip do IBGE: `import_microdata22()`.
- Variáveis **não** são harmonizadas entre anos (só a geografia).
- O pacote não calcula erros-padrão → usar {survey}/{srvyr}.
- Breaking changes da 1.0.0 (`year` obrigatório, códigos como inteiros) — mostrar que
  estudamos a versão nova.
- Agradecimento aos autores e citação: `citation("censobr")`.

---

## Perguntas: como responder
- Quem responde é **quem apresentou o bloco**. Os outros só complementam.
- Resposta em 3 tempos: **resposta direta → como sabemos (testamos / documentação) → exemplo**.
- Não sabe? *"Não testamos isso. Pela documentação, seria ___; podemos verificar depois."*
- Respostas prontas: ver `guia_de_estudo.md`, seção 4.

## Checklist da véspera
- [ ] Todos com censobr **1.0.0** (`packageVersion("censobr")`).
- [ ] Scripts `00`, `01` e `02` rodados no computador da apresentação (cache cheio).
- [ ] `slides.html` aberto e testado no projetor; PNGs em `output/` como plano B.
- [ ] Cada membro consegue explicar, sem ler: peso amostral, lazy/`collect()`, `columns`,
      amostra × universo, o que muda em 2022.
- [ ] Ensaio cronometrado (2×). Corte a demo se passar de 20 min.
- [ ] Cada membro responde em voz alta 5 perguntas do guia sorteadas pelos outros.
