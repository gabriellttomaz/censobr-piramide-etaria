# Guia de estudo — dominando o {censobr}

> Tudo aqui foi conferido na **versão 1.0.0** do pacote (CRAN, 21/09/2026),
> lendo a documentação oficial **e o código-fonte** instalado.
> Antes da apresentação, rode `packageVersion("censobr")` e confirme que é 1.0.0.

---

## 1. Ficha técnica (decorar)

| Item | Resposta |
|---|---|
| O que é | Pacote R para baixar **microdados, agregados por setor censitário e documentação** dos Censos Demográficos brasileiros |
| Quem fez | **Rafael H. M. Pereira** (autor e mantenedor) e **Rogério J. Barbosa** (autor) |
| Contribuidores | Pedro Herculano Souza, Diego Rabatone Oliveira, Neal Richardson, Haydee Svab |
| Instituição | **Ipea** (Instituto de Pesquisa Econômica Aplicada) — detentor do copyright e financiador |
| Versão atual | **1.0.0** (21/09/2026). Anteriores: 0.5.0 (07/2025), 0.4.1 (02/2025), 0.4.0 (09/2024) |
| Site | https://ipea.github.io/censobr/ |
| Código | https://github.com/ipea/censobr |
| Onde ficam os dados | *Releases* do repositório GitHub `ipea/censobr_prep_data` (ex.: tag `v1.0.0`) |
| Formato dos dados | **Parquet** (colunar, comprimido com **zstd** desde a 0.5.0) |
| Dependências (Imports) | arrow (≥ 15.0.1), checkmate, cli, dplyr, **duckdb**, fs, glue, httr2, rlang, tools |
| "Família" | Mesmo autor do **{geobr}** (malhas geográficas). O censobr cria colunas geográficas com os **mesmos nomes do geobr** (`code_muni`, `code_state`, `abbrev_state`, `code_region`, `code_weighting`) para facilitar o `left_join()` com mapas |

**Frase-resumo para abrir:** *"O censobr transforma um processo que levava horas —
baixar arquivos de largura fixa do IBGE, ler com scripts de SAS/SPSS, empilhar 27 UFs —
em uma linha de código, entregando os dados em Parquet e permitindo analisar bases
maiores que a memória RAM."*

---

## 2. As 13 funções exportadas (saber TODAS)

### Microdados (amostra — questionário longo)

| Função | Anos disponíveis | Argumentos extras |
|---|---|---|
| `read_population()` | 1960, 1970, 1980, 1991, 2000, 2010, 2022 | `merge_households` |
| `read_households()` | 1960, 1970, 1980, 1991, 2000, 2010, 2022 | — |
| `read_families()` | 2000, 2022 | — |
| `read_mortality()` | 2010, 2022 | `merge_households` |
| `read_emigration()` | 2010 | `merge_households` |

Assinatura comum:

```r
read_population(
  year,                    # OBRIGATÓRIO desde a 0.5.0/1.0.0 (não tem mais padrão 2010)
  columns = NULL,          # vetor de NOMES (texto). Índices numéricos não são mais aceitos (1.0.0)
  add_labels = NULL,       # "pt" troca códigos por rótulos em português
  as_data_frame = FALSE,   # FALSE = Arrow Dataset (padrão); TRUE = data.frame na memória
  showProgress = TRUE,     # barra de progresso do download
  cache = TRUE,            # reaproveita arquivo já baixado
  verbose = TRUE,          # mensagens informativas (novo na 0.5.0)
  merge_households = FALSE # traz variáveis do domicílio (exige `columns`)
)
```

### Agregados por setor censitário (universo)

| Função | Anos | `dataset` (obrigatório) |
|---|---|---|
| `read_tracts()` | 2000 | Basico, Domicilio, Responsavel, Pessoa, Instrucao, Morador |
| | 2010 | Basico, Domicilio, DomicilioRenda, Responsavel, ResponsavelRenda, Pessoa, PessoaRenda, Entorno |
| | 2022 | Basico, Domicilio, ResponsavelRenda, Pessoas, Indigenas, Quilombolas, Entorno, Obitos, Preliminares |

`read_tracts()` **não tem** `columns` nem `add_labels`.

### Documentação

| Função | O que faz | Argumentos obrigatórios |
|---|---|---|
| `data_dictionary()` | Abre o dicionário de variáveis (Excel/HTML) | `year`, `dataset = "microdata"` ou `"tracts"` |
| `questionnaire()` | Abre o questionário | `year`, `type = "long"` (amostra) ou `"short"` (universo) |
| `interview_manual()` | Abre o Manual do Recenseador | `year` |

### Cache

| Função | O que faz |
|---|---|
| `censobr_cache()` | Lista (`list_files`, `print_tree`) ou apaga arquivos (`delete_file = "nome"`, `"all"` ou `"old"`) |
| `get_censobr_cache_dir()` | Mostra a pasta de cache em uso |
| `set_censobr_cache_dir()` | Muda a pasta de cache — **persiste entre sessões** (0.5.0). `path = NULL` volta ao padrão |

### Suporte

| Função | O que faz |
|---|---|
| `import_microdata22()` | Importa o **zip dos microdados controlados de 2022** (pedido ao IBGE) para o cache. Depois disso, `read_*(year = 2022)` passa a usar a versão completa |

---

## 3. Conceitos que o professor VAI cobrar

### 3.1 Por que Arrow / Parquet?
- **Parquet é colunar**: ler 3 colunas de um arquivo com 200 colunas lê só aquelas 3 do disco.
- `read_*()` devolve, por padrão, um **Arrow Dataset** — uma *referência* ao arquivo,
  não os dados. Os verbos do dplyr (`filter`, `select`, `mutate`, `group_by`, `summarise`)
  constroem um **plano de consulta preguiçoso (lazy)**.
- Nada é calculado até você pedir:
  - `collect()` → executa e traz o resultado para a memória como `data.frame`/tibble.
  - `compute()` → executa mas mantém como tabela Arrow (fora do R).
- Resultado: dá para agregar o Censo 2010 inteiro (**20.635.472 pessoas na amostra**)
  num notebook comum, porque só a **tabela agregada** (38 linhas na nossa pirâmide) entra na RAM.
- Classe do objeto (testado):
  - `read_households(year = 2010)` → `"FileSystemDataset"` (o arquivo inteiro, lazy)
  - `read_population(year = 2010, columns = c(...))` → `"arrow_dplyr_query"`
    (porque o pacote aplica um `select()` por dentro). Os dois funcionam igual com dplyr.
- `as_data_frame = TRUE` carrega TUDO na memória → pode travar a sessão. Só usar para bases pequenas.

### 3.2 Pegadinha do `columns` (detalhe de quem leu o código)
O arquivo Parquet é **baixado inteiro** mesmo com `columns`. O argumento só faz um
`select()` depois de abrir o dataset: economiza **memória e tempo de leitura**, não download.

Tamanhos reais no release v1.0.0: população 2010 = **822 MB**; população 2022 (pública) = 642 MB;
população 1991 = 727 MB; domicílios 2010 = 148 MB; mortalidade 2010 = 2 MB;
setores 2010 "Basico" = 16 MB.

### 3.3 Amostra × universo — **o ponto mais importante**
- Os microdados (`read_population` etc.) vêm do **questionário da amostra** (longo),
  respondido por uma fração dos domicílios.
- Portanto **cada linha não é uma pessoa da população**: é preciso usar o **peso amostral**.
  - 2010: `V0010`. 2022 (versão pública): `P0110`. Cada ano tem o seu — ver `data_dictionary()`.
- Contar linhas (`n()`) dá o tamanho da *amostra*, não da população. Na nossa pirâmide,
  somamos o peso: `sum(V0010)`.
- Os dados de setor (`read_tracts`) são do **universo** (questionário básico, todos os domicílios):
  já são totais, sem peso.

### 3.4 Erros-padrão e desenho amostral
O censobr **não** calcula variância. Para intervalos de confiança corretos use
{survey}/{srvyr}, usando a **área de ponderação** (`code_weighting`) como estrato/conglomerado
conforme a documentação do IBGE. Para 1960, os autores construíram variáveis que aproximam o desenho.

### 3.5 Harmonização
O pacote harmoniza **apenas a geografia** (nomes de colunas iguais aos do geobr).
**As variáveis não são harmonizadas entre anos**: em 2010 a idade é `V6036` (anos completos) e
o sexo é `V0601`; em 2022 (público) o sexo é `P0150` e a idade só existe em grupos, `P0180`.
Sempre conferir no `data_dictionary(year, "microdata")`.

### 3.6 Microdados de 2022 (novidade da 1.0.0)
- O IBGE liberou a amostra de 2022 como **"dados controlados"** — o censobr **não pode redistribuir**.
- Sem importar, `read_population(year = 2022)` emite um **aviso** e usa uma **versão pública reduzida**
  (menos variáveis; idade vem em faixas).
- Para a versão completa: pedir em https://microdados.ibge.gov.br/ (formato .csv), baixar o zip
  e rodar **uma única vez** `import_microdata22(zip_path = "...")`. Os Parquet são gravados no cache
  e **nunca são apagados automaticamente** (o pacote não teria como baixá-los de novo).

### 3.7 Cache versionado
- Pasta padrão: `tools::R_user_dir("censobr", "cache")` →
  no Windows algo como `C:/Users/<você>/AppData/Local/R/cache/R/censobr`.
- Dentro dela: `data_release_v1.0.0/`. Quando sai um novo *data release*, os arquivos antigos
  são apagados no primeiro download da sessão (desligável com `options(censobr.keep_old_cache = TRUE)`).

### 3.8 `merge_households`
- Junta variáveis do domicílio às pessoas (ou óbitos/emigrantes) usando **DuckDB** por baixo.
- **Exige `columns`** (sem isso, dá erro): juntar tudo geraria ~300 colunas e >20 GB de RAM.
- Em 1980 e 1991 não faz nada (os microdados de pessoas já trazem as variáveis do domicílio).

### 3.9 Breaking changes da 1.0.0 (mostra que estudamos a versão nova)
1. `year` virou obrigatório em todas as funções (`questionnaire()` não assume mais 2010).
2. `type` em `questionnaire()`, `dataset` em `read_tracts()` e `data_dictionary()` viraram obrigatórios.
3. `data_dictionary()` só aceita `"microdata"` ou `"tracts"` (saíram `"population"`/`"households"`).
4. `columns` só aceita nomes (não índices).
5. **Códigos categóricos agora são inteiros**: `filter(V0601 == "1")` virou `filter(V0601 == 1)`;
   valores `"."` viraram `NA`.

### 3.10 Censo de 1960
Combinação da amostra de 25% (só 16 UFs digitalizadas) com a subamostra de 1,27% de 1965
(todas as UFs). Os autores reprocessaram, criaram pesos e variáveis de desenho amostral.
`read_population(year = 1960)` emite um aviso sobre isso.

---

## 4. Perguntas prováveis e respostas

**"Por que usar o censobr em vez de baixar direto do IBGE?"**
O IBGE distribui arquivos de largura fixa por UF, com dicionário em Excel e scripts de leitura.
O censobr já entrega tudo empilhado, em Parquet, com colunas geográficas padronizadas,
cache local e leitura *larger-than-memory*. Reprodutibilidade: qualquer pessoa roda o mesmo script.

**"O que acontece se eu rodar `read_population(2010)` duas vezes?"**
Na segunda vez lê do cache local (`cache = TRUE`). Com `cache = FALSE` baixa de novo e sobrescreve.

**"O que é retornado?"** — Um objeto Arrow, não um data.frame: `"FileSystemDataset"` sem
`columns`, `"arrow_dplyr_query"` com `columns`. Com `as_data_frame = TRUE` vira tibble.

**"Por que a idade máxima em 2010 é 139?"** (testamos: `max(V6036)` = 139)
É o dado bruto do IBGE (valores extremos/erros de declaração). Por isso agrupamos em "90+":
o grupo aberto absorve esses casos sem distorcer a pirâmide.

**"Por que tiraram os ignorados de 2022?"**
Na versão pública, 19.216 registros têm sexo = 9 e idade = 99 (ignorados). Removemos; por isso a
soma dá 202.966.521 e não os 203.080.756 oficiais (diferença de 0,06%).

**"O merge com domicílios gerou NA?"**
`V0207` (esgotamento) fica NA para 4,8% das pessoas — pergunta que não se aplica (domicílio sem
banheiro, improvisado ou coletivo). Testamos que o merge não perde ninguém: a variável de espécie do
domicílio (`V4001`) tem 0% de NA após a junção.

**"Por que vocês usaram `sum(V0010)` e não `n()`?"**
Porque é amostra; `V0010` é o peso que expande para a população. `n()` daria ~20,6 milhões
(pessoas na amostra de 2010) e não ~190,8 milhões (população).

**"Dá para fazer a pirâmide de 2022?"**
Sim, de dois jeitos: (a) microdados públicos de 2022 (idade em faixas, `read_population(2022)`,
emite aviso); (b) agregados do universo por setor, `read_tracts(2022, "Pessoas")`.
Com o zip controlado + `import_microdata22()` teria a idade simples.

**"Como juntar com um mapa?"**
`geobr::read_municipality(year = 2010)` + `left_join(..., by = "code_muni")` + `geom_sf()`.
Funciona porque os nomes das colunas geográficas são os mesmos.

**"E se eu quiser SQL?"**
`arrow::to_duckdb()` e usar dbplyr, ou registrar o dataset numa conexão DuckDB com
`duckdb::duckdb_register_arrow()` e usar `DBI::dbGetQuery()`.

**"Qual a diferença entre `compute()` e `collect()`?"**
Ambos executam o plano. `collect()` traz para o R (memória); `compute()` materializa como tabela Arrow.

**"Como descobrir o nome da variável de idade?"**
`data_dictionary(year = 2010, dataset = "microdata")` e, para confirmar o significado,
`questionnaire(year = 2010, type = "long")`.

**"Como limpar o cache?"**
`censobr_cache(delete_file = "2010_population")` ou `censobr_cache(delete_file = "all")`.

**"O que é `code_weighting`?"**
Código da **área de ponderação** — menor unidade geográfica para a qual os microdados da amostra
são representativos (subdivisão de municípios grandes). Também tem malha no geobr
(`read_weighting_area()`).

**"Onde está hospedado?"**
Em *GitHub Releases* do repositório `ipea/censobr_prep_data`; a URL é montada com a tag do release
(`v1.0.0`). O processamento dos dados brutos fica nesse repositório separado.

---

## 5. Números que nós mesmos calculamos (saber de cor)

| Indicador | 2010 | 2022 |
|---|---|---|
| Linhas na amostra | 20.635.472 | 21.538.508 |
| População (soma dos pesos) | 190.755.799 | 203.080.756 (202.966.521 sem ignorados) |
| 0–14 anos | 24,1% | 19,8% |
| 15–64 anos | 68,5% | 69,3% |
| 65+ anos | 7,4% | 11,0% |
| Índice de envelhecimento (65+ por 100 de 0–14) | 30,7 | 55,5 |

Leitura: em 12 anos a base da pirâmide encolheu e o topo alargou — o Brasil quase dobrou o número
de idosos por jovem. As maiores barras de 2022 estão em 35–44 anos (a "geração grande" de 2010,
que tinha 10–29 anos e foi subindo).

Comparação regional (2010): **Amazonas** tem pirâmide de base larga (população jovem, fecundidade
mais alta); **Rio Grande do Sul** já tinha base estreita e meio largo (envelhecimento avançado).

Citação oficial (`citation("censobr")`):
Pereira RHM, Barbosa RJ (2023). *censobr: Download Data from Brazil's Population Census*.
doi:10.32614/CRAN.package.censobr

---

## 6. Regras de ouro no dia
1. **Baixar os dados ANTES** (cache). Wi-Fi da faculdade não é confiável — 2010 tem centenas de MB.
2. Ter o gráfico salvo em `output/` como plano B se algo falhar ao vivo.
3. Nunca dizer "o pacote faz X" sem ter testado. Se não souber: *"Não testamos isso; pela
   documentação seria assim..."* — honestidade pega melhor que chute com professor metódico.
4. Citar o pacote: `citation("censobr")`.
