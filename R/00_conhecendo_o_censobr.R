# ==============================================================================
# Conhecendo o {censobr} — tour pelas principais funções
# ==============================================================================
# Rode bloco a bloco (Ctrl+Enter). Algumas funções abrem arquivos no navegador.

# install.packages("censobr")   # versão do CRAN
library(censobr)
library(arrow)
library(dplyr)

packageVersion("censobr")       # esperado: 1.0.0
citation("censobr")


# 1. Documentação do Censo -------------------------------------------------------
# Todas exigem `year`. Baixam o arquivo uma vez, guardam no cache e abrem.

data_dictionary(year = 2010, dataset = "microdata")  # dicionário dos microdados
data_dictionary(year = 2022, dataset = "tracts")     # dicionário dos setores censitários
questionnaire(year = 2010, type = "long")            # questionário da amostra
questionnaire(year = 2010, type = "short")           # questionário do universo
interview_manual(year = 2010)                        # manual do recenseador


# 2. Microdados (amostra) --------------------------------------------------------
# Família read_*(): mesma lógica e mesmos argumentos.
#   read_population()  1960, 1970, 1980, 1991, 2000, 2010, 2022
#   read_households()  1960, 1970, 1980, 1991, 2000, 2010, 2022
#   read_families()    2000, 2022
#   read_mortality()   2010, 2022
#   read_emigration()  2010

dom <- read_households(year = 2010, showProgress = FALSE)
class(dom)        # "FileSystemDataset": aponta para o Parquet, não carrega na memória
names(dom)[1:15]  # colunas geográficas padronizadas + variáveis do IBGE

# add_labels = "pt" troca códigos por rótulos
obitos <- read_mortality(year = 2010, add_labels = "pt", showProgress = FALSE)

obitos |>
  filter(abbrev_state == "RJ") |>
  count(V0704) |>     # V0704 = sexo da pessoa falecida (já rotulado)
  collect()           # atenção: count() conta linhas da AMOSTRA, sem peso


# 3. merge_households: variáveis do domicílio junto com as pessoas ---------------
# Exige `columns`. Aqui: idade da pessoa + tipo de esgotamento do domicílio (V0207).
pop_dom <- read_population(
  year = 2010,
  columns = c("code_muni", "V0010", "V6036", "V0207"),
  merge_households = TRUE,
  showProgress = FALSE
)
head(pop_dom) |> collect()
# V0207 vem NA para ~4,8% das pessoas: a pergunta não se aplica (domicílio sem
# banheiro/sanitário, improvisado ou coletivo). Não é erro do merge.


# 4. Dados agregados por setor censitário (universo) -----------------------------
# Não têm peso: já são totais. `dataset` é obrigatório.
basico <- read_tracts(year = 2010, dataset = "Basico", showProgress = FALSE)
basico |> select(code_tract, code_muni, V002) |> head() |> collect()  # V002 = moradores


# 5. Larger-than-memory: Arrow, collect() e DuckDB --------------------------------
# Os verbos do dplyr montam um plano lazy; nada roda até collect()/compute().
plano <- dom |>
  group_by(abbrev_state) |>
  summarise(domicilios = sum(V0010))
plano            # ainda é só uma consulta
collect(plano)   # agora executa

# Mesma coisa em SQL com DuckDB
con <- DBI::dbConnect(duckdb::duckdb())
duckdb::duckdb_register_arrow(con, "dom2010", dom)
DBI::dbGetQuery(con, "SELECT abbrev_state, SUM(V0010) AS domicilios
                      FROM dom2010 GROUP BY abbrev_state ORDER BY domicilios DESC")
DBI::dbDisconnect(con)


# 6. Cache ------------------------------------------------------------------------
get_censobr_cache_dir()                  # onde estão os arquivos
censobr_cache(list_files = TRUE, print_tree = TRUE)
# censobr_cache(delete_file = "2010_mortality")  # apaga um arquivo
# censobr_cache(delete_file = "all")             # apaga tudo
# set_censobr_cache_dir("D:/censo")              # muda a pasta (persiste entre sessões)


# 7. Microdados de 2022 -----------------------------------------------------------
# Sem o zip controlado do IBGE, o pacote avisa e usa a versão pública (reduzida).
# Com o zip (pedido em https://microdados.ibge.gov.br/), importa uma única vez:
# import_microdata22(zip_path = "caminho/para/o_arquivo_do_ibge.zip")
