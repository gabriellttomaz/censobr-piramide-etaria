# ==============================================================================
# Pirâmide etária do Brasil — Censo 2010, com o pacote {censobr}
# ==============================================================================
# Variáveis usadas (confira com data_dictionary(year = 2010, dataset = "microdata")):
#   V0010 -> peso amostral (quantas pessoas da população cada linha representa)
#   V0601 -> sexo (1 = masculino, 2 = feminino)
#   V6036 -> idade em anos completos
#   abbrev_state -> sigla da UF (coluna criada pelo censobr, padrão geobr)
# ==============================================================================

library(censobr)
library(arrow)
library(dplyr)
library(ggplot2)

dir.create("output", showWarnings = FALSE)

# 1. Leitura --------------------------------------------------------------------
# Não carrega nada na memória: devolve um Arrow Dataset apontando para o
# arquivo Parquet no cache. Na primeira vez, baixa o arquivo.
pop <- read_population(
  year = 2010,
  columns = c("abbrev_state", "V0010", "V0601", "V6036"),
  showProgress = TRUE
)

class(pop)          # "arrow_dplyr_query" — uma consulta Arrow, não um data.frame
                    # (sem `columns` seria um "FileSystemDataset")
glimpse(pop)        # inspeciona sem carregar tudo


# 2. Função que agrega a pirâmide -----------------------------------------------
# Toda a agregação roda no Arrow (lazy). Só a tabela final, com ~38 linhas,
# entra na memória no collect().
calcular_piramide <- function(dados, uf = NULL) {

  if (!is.null(uf)) {
    dados <- filter(dados, abbrev_state == uf)
  }

  dados |>
    mutate(
      faixa = if_else(V6036 >= 90, 90, floor(V6036 / 5) * 5),  # grupos de 5 anos, 90+
      sexo  = if_else(V0601 == 1, "Homens", "Mulheres")
    ) |>
    group_by(sexo, faixa) |>
    summarise(pop = sum(V0010), .groups = "drop") |>          # soma dos PESOS, não n()
    collect() |>
    mutate(
      prop  = pop / sum(pop),
      faixa = factor(
        if_else(faixa == 90, "90+", paste0(faixa, "-", faixa + 4)),
        levels = c(paste0(seq(0, 85, 5), "-", seq(4, 89, 5)), "90+")
      )
    ) |>
    arrange(sexo, faixa)
}


# 3. Função que desenha ---------------------------------------------------------
# Truque da pirâmide: os homens recebem valor negativo para ficarem à esquerda;
# os rótulos do eixo mostram o valor absoluto.
plotar_piramide <- function(tab, titulo) {

  ggplot(tab, aes(x = if_else(sexo == "Homens", -prop, prop), y = faixa, fill = sexo)) +
    geom_col(width = 0.9) +
    geom_vline(xintercept = 0, colour = "white", linewidth = 0.5) +
    scale_x_continuous(
      labels = function(x) scales::percent(abs(x), accuracy = 0.1),
      limits = c(-1, 1) * max(tab$prop) * 1.05
    ) +
    scale_fill_manual(values = c(Homens = "#2b6a99", Mulheres = "#c9563c")) +
    labs(
      title    = titulo,
      subtitle = "Proporção da população por sexo e grupo de idade (pesos amostrais)",
      x = NULL, y = "Idade", fill = NULL,
      caption  = "Fonte: IBGE, Censo Demográfico 2010 — microdados via {censobr}"
    ) +
    theme_minimal(base_size = 13) +
    theme(legend.position = "top", panel.grid.major.y = element_blank())
}


# 4. Brasil ---------------------------------------------------------------------
piramide_br <- calcular_piramide(pop)
print(piramide_br, n = Inf)

# Checagem de sanidade: a soma dos pesos deve dar a população do Brasil em 2010
sum(piramide_br$pop)

g_br <- plotar_piramide(piramide_br, "Pirâmide etária — Brasil, 2010")
g_br
ggsave("output/piramide_brasil_2010.png", g_br, width = 8, height = 7, dpi = 300, bg = "white")


# 5. Comparando duas UFs --------------------------------------------------------
# Mesmo código, só muda o filtro. Ex.: UF jovem (AM) x UF envelhecida (RS).
piramide_am <- calcular_piramide(pop, uf = "AM")
piramide_rs <- calcular_piramide(pop, uf = "RS")

g_uf <- bind_rows(
  mutate(piramide_am, uf = "Amazonas"),
  mutate(piramide_rs, uf = "Rio Grande do Sul")
) |>
  plotar_piramide("Pirâmide etária — Amazonas x Rio Grande do Sul, 2010") +
  facet_wrap(~uf) +
  theme(panel.spacing = unit(2, "lines"))

g_uf
ggsave("output/piramide_am_rs_2010.png", g_uf, width = 12, height = 7, dpi = 300, bg = "white")
