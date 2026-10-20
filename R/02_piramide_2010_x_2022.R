# ==============================================================================
# Envelhecimento: pirâmide etária 2010 x 2022 com o {censobr}
# ==============================================================================
# 2010 (microdados abertos):
#   V0010 = peso | V0601 = sexo (1 masc., 2 fem.) | V6036 = idade em anos
# 2022 (versão PÚBLICA dos microdados — o pacote avisa que é a versão reduzida):
#   P0110 = peso | P0150 = sexo (1 masc., 2 fem., 9 ignorado)
#   P0180 = grupo de idade (1 = 0 a 4 anos, ..., 17 = 80 anos ou mais, 99 = ignorado)
# Como 2022 público só tem a idade em grupos, usamos os mesmos grupos (80+) em 2010.
# ==============================================================================

library(censobr)
library(arrow)
library(dplyr)
library(ggplot2)

dir.create("output", showWarnings = FALSE)

faixas <- c(paste0(seq(0, 75, 5), "-", seq(4, 79, 5)), "80+")


# 2010 --------------------------------------------------------------------------
pir_2010 <- read_population(
  year = 2010,
  columns = c("V0010", "V0601", "V6036"),
  showProgress = TRUE
) |>
  mutate(
    grupo = if_else(V6036 >= 80, 17, floor(V6036 / 5) + 1),
    sexo  = if_else(V0601 == 1, "Homens", "Mulheres")
  ) |>
  group_by(sexo, grupo) |>
  summarise(pop = sum(V0010), .groups = "drop") |>
  collect()


# 2022 --------------------------------------------------------------------------
# read_population(year = 2022) emite um aviso: sem o zip controlado do IBGE
# (import_microdata22()), ele usa a versão pública. É esperado.
pir_2022 <- read_population(
  year = 2022,
  columns = c("P0110", "P0150", "P0180"),
  showProgress = TRUE
) |>
  filter(P0150 != 9, P0180 != 99) |>                 # remove sexo/idade ignorados
  mutate(sexo = if_else(P0150 == 1, "Homens", "Mulheres")) |>
  group_by(sexo, grupo = P0180) |>
  summarise(pop = sum(P0110), .groups = "drop") |>
  collect()


# Junta e calcula proporções ------------------------------------------------------
piramides <- bind_rows(
  mutate(pir_2010, ano = "2010"),
  mutate(pir_2022, ano = "2022")
) |>
  group_by(ano) |>
  mutate(prop = pop / sum(pop)) |>
  ungroup() |>
  mutate(faixa = factor(faixas[grupo], levels = faixas))

# População total em cada ano (sanidade: 190,8 mi em 2010; 203,0 mi em 2022,
# um pouco abaixo dos 203,1 mi oficiais porque tiramos sexo/idade ignorados)
piramides |> group_by(ano) |> summarise(pop = sum(pop))


# Gráfico: 2022 em barras, 2010 em contorno ---------------------------------------
g <- ggplot(mapping = aes(x = if_else(sexo == "Homens", -prop, prop), y = faixa)) +
  geom_col(
    data = filter(piramides, ano == "2022"),
    aes(fill = sexo), width = 0.9, alpha = 0.85
  ) +
  geom_col(
    data = filter(piramides, ano == "2010"),
    aes(linetype = "2010"),
    fill = NA, colour = "black", width = 0.9, linewidth = 0.6
  ) +
  geom_vline(xintercept = 0, colour = "white") +
  scale_x_continuous(labels = function(x) scales::percent(abs(x), accuracy = 0.1)) +
  scale_fill_manual(values = c(Homens = "#2b6a99", Mulheres = "#c9563c"), name = "2022") +
  scale_linetype_manual(values = c("2010" = "solid"), name = NULL) +
  labs(
    title    = "O Brasil envelheceu: pirâmide etária 2022 x 2010",
    subtitle = "Barras coloridas: 2022  |  Contorno preto: 2010  —  proporção da população por sexo e idade",
    x = NULL, y = "Idade",
    caption  = "Fonte: IBGE, Censos Demográficos 2010 e 2022 (versão pública) — microdados via {censobr}"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top", panel.grid.major.y = element_blank())

g
ggsave("output/piramide_2010_x_2022.png", g, width = 9, height = 7, dpi = 300, bg = "white")


# Indicadores para comentar na apresentação ---------------------------------------
piramides |>
  mutate(grande_grupo = case_when(
    grupo <= 3  ~ "0-14",
    grupo <= 13 ~ "15-64",
    TRUE        ~ "65+"
  )) |>
  group_by(ano, grande_grupo) |>
  summarise(prop = sum(prop), .groups = "drop") |>
  tidyr::pivot_wider(names_from = grande_grupo, values_from = prop) |>
  mutate(indice_envelhecimento = 100 * `65+` / `0-14`)   # idosos por 100 jovens
