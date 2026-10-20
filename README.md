# Pirâmide etária com o {censobr}

Trabalho de apresentação de pacote R: **{censobr}** — dados dos Censos Demográficos
brasileiros (1960–2022), desenvolvido por Rafael H. M. Pereira e Rogério J. Barbosa (Ipea).

![Pirâmide etária do Brasil, 2010](output/piramide_brasil_2010.png)

## Estrutura

```
censobr-piramide-etaria/
├── R/
│   ├── 00_conhecendo_o_censobr.R   # tour pelas funções do pacote
│   ├── 01_piramide_2010.R          # pirâmide etária (Brasil e UFs) — script principal
│   └── 02_piramide_2010_x_2022.R   # comparação 2010 x 2022 (envelhecimento)
├── output/                         # gráficos gerados
└── apresentacao/
    ├── roteiro.md                  # quem fala o quê, slide a slide, com tempos
    ├── guia_de_estudo.md           # tudo sobre o pacote + perguntas prováveis
    └── slides.qmd                  # slides em Quarto (revealjs)
```

## Como rodar

```r
install.packages(c("censobr", "arrow", "dplyr", "ggplot2", "scales", "tidyr", "duckdb", "DBI"))
```

Abra o projeto no RStudio/Positron com a pasta do repositório como diretório de trabalho e rode
`R/01_piramide_2010.R`. Na primeira execução o pacote baixa os microdados de pessoas de 2010
(**~822 MB**, uma única vez — depois fica em cache).

> **Dica para o dia da apresentação:** rode todos os scripts em casa antes, para que os
> arquivos já estejam no cache e nada dependa da internet da sala.

## Versões testadas

- R 4.6.1
- censobr 1.0.0 (CRAN, 21/09/2026)
